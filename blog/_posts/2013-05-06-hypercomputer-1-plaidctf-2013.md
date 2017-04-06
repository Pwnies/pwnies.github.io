---
title: hypercomputer-1 - PlaidCTF 2013
author: IdolfHatler
layout: post
published: true
date: 2013-05-06 23:02:05
---

Challenge description:

> <pre>For those who didn't play plaidCTF 2012: "supercomputer" was a
> reversing challenge that computed flags using really silly math (like adding
> in a loop instead of mulitplication). hypercomputer is easier... if you do it right :P
> ssh to 54.224.174.166</pre>

```python
from pwn import *
context('amd64', 'linux')

bin = read('hypercomputer')

def replace(pat, rep):
    global bin
    pat = unhex(pat)
    rep = asm(rep).ljust(len(pat), '\x90')
    bin = bin.replace(pat, rep)

# usleep
replace('FF255A682000', 'ret')

# dec eax to 0
replace('4883E80175FA', 'xor eax, eax')

# dec eax to 0
replace('4883E8010F1F0075F7', 'xor eax, eax')

# inc rax to rdx
replace('4883C0014839D075F7', 'mov rax, rdx')

write('hypercomputer-patched', bin)
```

Key: Y0uKn0wH0wT0Sup3rButCanY0uHyp3r
