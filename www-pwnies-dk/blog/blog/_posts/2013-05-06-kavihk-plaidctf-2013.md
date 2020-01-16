---
title: kavihk - PlaidCTF 2013
author: br0ns
layout: post
published: true
date: 2013-05-06 22:53:20
---

(We didn't solve this challenge during the CTF because too much derp)

Challenge description:
> <pre>YOU RIKE PRAY GAME?
> HINT FOR KAVIHK: There is a bruteforce of much less than a billion things.
> HINT FOR KAVIHK: You do not need to hand-optimize math, and my solution runs in under 5 min on my laptop. </pre>
>[kavihk.tgz](http://play.plaidctf.com/files/kavihk.tgz-27158df97cab0e6c316db12947c3cef8d9e8ad5f)

Apparently `Another Visit In Hell' is an ncurses based rougelike game.  We are
given a modified version as a 32bit stripped ELF.  To win the game you have to
survive 8 circles of hell.

The code is pretty daunting at first but noticing the string
  `WIN    ...but no flag for you.`
at address 0x804b730 and searching for references to it lands us in a function
(let's call it `win') at address 0x8049581.  The function is only called from
one place:

```objdump
804997b:       a1 b0 49 05 08          mov    eax,ds:0x80549b0
8049980:       83 f8 09                cmp    eax,0x9
8049983:       75 07                   jne    804998c
8049985:       e8 f7 fb ff ff          call   8049581
804998a:       eb 05                   jmp    8049991
804998c:       b8 4f b7 04 08          mov    eax,0x804b74f
```

We notice two things: 1) there's a comparison to 9 which fits well with the goal
of the original game to go through 8 circles (thus reaching the 9th), and 2) the
string at 0x804b74f is "kavihk" which the game prints (among other things) in a
status line.

So the assumption is that we have to win the game in a certain way and we'll see
the flag in the status line.  So let's have a look at the `win' function.

The function starts with a loop which is executed 30 times:

```objdump
8049589:       c7 44 24 10 08 00 00 00    mov    DWORD PTR [esp+0x10],0x8
8049591:       8d 45 f7                   lea    eax,[ebp-0x9]
8049594:       89 44 24 0c                mov    DWORD PTR [esp+0xc],eax
8049598:       c7 44 24 08 00 00 00 00    mov    DWORD PTR [esp+0x8],0x0
80495a0:       c7 44 24 04 00 00 00 00    mov    DWORD PTR [esp+0x4],0x0
80495a8:       c7 04 24 c0 49 05 08       mov    DWORD PTR [esp],0x80549c0
80495af:       e8 f1 0b 00 00             call   804a1a5
80495b4:       85 c0                      test   eax,eax
80495b6:       74 0c                      je     80495c4
80495b8:       c7 04 24 01 00 00 00       mov    DWORD PTR [esp],0x1
80495bf:       e8 48 f1 ff ff             call   804870c <exit@plt>
80495c4:       a1 14 cb 04 08             mov    eax,ds:0x804cb14
80495c9:       8b 15 14 cb 04 08          mov    edx,DWORD PTR ds:0x804cb14
80495cf:       0f b6 8a d0 ca 04 08       movzx  ecx,BYTE PTR [edx+0x804cad0]
80495d6:       0f b6 55 f7                movzx  edx,BYTE PTR [ebp-0x9]
80495da:       31 ca                      xor    edx,ecx
80495dc:       88 90 d0 ca 04 08          mov    BYTE PTR [eax+0x804cad0],dl
80495e2:       a1 14 cb 04 08             mov    eax,ds:0x804cb14
80495e7:       83 c0 01                   add    eax,0x1
80495ea:       a3 14 cb 04 08             mov    ds:0x804cb14,eax
80495ef:       a1 14 cb 04 08             mov    eax,ds:0x804cb14
80495f4:       83 f8 1d                   cmp    eax,0x1d
80495f7:       76 90                      jbe    8049589
```

First there's a call `some_func(&foo, 0, 0, &c, 8)`, then the character that we
passed the address to as the 4th argument is xor'ed into the bytes starting at
address 0x804cad0.  A team member recognized the `some_func` as the KeccaK
(SHA-3 finalist) sponge function (now the name of the challenge makes sense).

The sponge function (which is called `Duplexing') takes as arguments; an
internal KeccaK state, an input buffer, the size of the input buffer (in bits),
an output buffer, and the size of the output buffer (also in bits).  So the loop
we saw before extracts 30 bytes, one byte at a time.

After the loop, the xor'ed bytes are examined; if there are underscores in five
particular places and the last byte is zero, then a pointer to the bytes is
returned.  Else the win-but-no-flag string is returned.

Now it's clear what we must do: get the right input to the sponge function in
order to decrypt the flag.  So how is the function called?  This gdb script sets
a breakpoint on the last instruction of `Duplexing' and prints out the arguments
it was called with.  If there was input or output, that is printed (hex encoded)
as well.

```objdump
b *0x0804A3B5
commands
  silent
  set $ibuf=((char**)$sp)[2]
  set $inum=((int*)$sp)[3]
  set $obuf=((char**)$sp)[4]
  set $onum=((int*)$sp)[5]
  printf "Duplexing(&st, 0x%08x, %d, 0x%08x, %d)\n", $ibuf, $inum, $obuf, $onum
  if $ibuf != 0
    set $i=0
    printf "  Input : "
    while $i * 8 < $inum
      printf "%02x", (unsigned char)$ibuf[$i]
      set $i=$i + 1
    end
    echo \n
  end
  if $obuf != 0
    set $i=0
    printf "  Output: "
    while $i * 8 < $onum
      printf "%02x", (unsigned char)$obuf[$i]
      set $i=$i + 1
    end
    echo \n
  end
  echo \n
  c
end
```

Now we start the game with `gdbserver' attached:

    gdbserver localhost:2345 ./kavihk

and connects `gdb':

    gdb -x kavihk.gdb
      (gdb) target remote localhost:2345
      (gdb) continue

After playing around a bit we see that the function is called four times when we
go one circle down in the game:

    Duplexing(&st, 0x080549b0, 32, 0x00000000, 0)
      Input : 00000000

    Duplexing(&st, 0x0804cabc, 32, 0x00000000, 0)
      Input : 12000000

    Duplexing(&st, 0x08054aa8, 32, 0x00000000, 0)
      Input : 00000000

    Duplexing(&st, 0x00000000, 0, 0xffffd04c, 32)
      Output: 7d77ab13

The first three calls input 4 bytes of data each, and the fourth extracts four
bytes.  From looking at the game's status line We see that the first call inputs
the circle we going to (zero indexed), the second inputs our maximum health, and
the third inputs the amount of gold we have.  From playing some more we also
learn that there are two health items (we call them hearts), and two gold pieces
in each circle and that our max health and gold increases by the number of the
circle (one indexed this time) we are in per picked up item.  I.e a gold piece
on level 4 increases our gold by 4.

(We got this far during the CTF, but have later confirmed that there are in fact
 always two hearts and two gold pieces on each level, and that they are always
 worth as much as the number of the circle we are in.)

With 2 hearts and 2 gold pieces on each level there are 3^16 different ways to
complete the game.  That's 43046721 which we should be able to brute force.  A
quick Google search gives us the [KeccaK source](http://keccak.noekeon.org), and
after some number crunching we get,

```text
Level 1: 1 heart, 0 gold
Level 2: 2 heart, 1 gold
Level 3: 2 heart, 0 gold
Level 4: 2 heart, 1 gold
Level 5: 1 heart, 0 gold
Level 6: 0 heart, 0 gold
Level 7: 1 heart, 1 gold
Level 8: 1 heart, 1 gold
Key: b2ute_f0rce_1s_7he_b3st_f0rce
```

A nice challenge, too bad we derp'ed too much during the CTF.  (The mistake was
to use KeccaK in a wrong configuration.)
