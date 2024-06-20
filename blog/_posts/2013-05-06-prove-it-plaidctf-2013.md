---
title: Prove It - PlaidCTF 2013
author: anonymous
layout: post
published: true
date: 2013-05-06 22:43:12
---

Challenge description:

> <pre>We've been reading about bitcoins -- 184.73.80.194:9001
> Hint: The answer isn't brute forcing.</pre>

# Solution

After looking at the Python script for a bit, without finding any obvious
vulnerabilities, we connected to the service to get a MD5 prefix:

```console
$ nc 184.73.80.194 9001
Free Key Distribution Service
Welcome! I am more than happy to give you a key, but you must first prove you did some work!

MD5 Prefix: 66203c461b36a
Enter string:
  Wrong! :\
$
```

After connecting to the service a couple of timeis we noticed that the MD5
prefix was changing, so we developed the following Perl script to see if it was
possible to figure out what kind of strings the MD5 prefixes derived from:

```perl
#!/usr/bin/perl
#
# bruteforce.pl

use Digest::MD5 qw(md5_hex);

$filename	= "all";
$prefix		= $ARGV[0];

open(FH, "< ".$filename);
while($word = <FH>) {
  $word =~ s/[\r\n]//g;

  if($prefix eq substr(md5_hex($word),0,13)) {
    print "Prefix: ".$word."\n";

    exit;
  }
}
close(FH);

print STDERR "Error: Unknown prefix.\n";
```

With the abovementioned script and a wordlist we were able to bruteforce the
string that the MD5 prefix derived from:

```console
$ ./bruteforce.pl 66203c461b36a
Prefix: protocols
$
```

With the succesful bruteforcing attempt in mind we developed the following Perl
script:

```perl
#!/usr/bin/perl
#
# solution.pl

use IO::Socket::INET;
use IPC::Run qw(run);

$ip             = "184.73.80.194";
$port           = "9001";
$protocol       = "tcp";

for(;;) {
  if(!($socket = new IO::Socket::INET(
    "PeerAddr"	=> $ip,
    "PeerPort"	=> $port,
    "Proto"		=> $protocol,
    "Timeout"	=> 2
  ))) {
    print STDERR "Error: Unable to connect to IP \"".$ip."\" at \"".$port."/".$protocol."\"\n";

    exit;
  }

  for(;;) {
    for(;;) {
      $socket->recv($string, 65535);

      if(($flag) = $string =~ /FLAG: (.+)/) {
        print "\nFlag: ".$flag."\n";

        exit;
      }
      elsif(($prefix) = $string =~ /MD5 Prefix: ([\da-f]{13})\n/) {
        last;
      }
    }

    @cmd = (
      "./bruteforce.pl",
      $prefix
    );

    eval {
      run \@cmd,\$in,\$out,\$err
    };

    if($err eq "Error: Unknown prefix.\n") {
      print "Warning: Unable to find the word derived from MD5 prefix \"".$prefix."\".\n";

      last;
    }

    ($word) = $out =~ /^Prefix: (.+\n)$/;
    print "MD5 Prefix: ".$prefix.". Word: ".$word;

    $socket->send($word);
  }
}
```

The following is the output from running the abovementioned script:

```console
$ ./solution.pl
MD5 Prefix: d014a047716ad. Word: retoucher
MD5 Prefix: b58a2074db806. Word: crudities
MD5 Prefix: 71ca321df9efa. Word: verifiable
MD5 Prefix: 8a99ccb2fbbc6. Word: alterman
MD5 Prefix: 5e15282ba3014. Word: coverer
MD5 Prefix: 889887d4a1745. Word: eking
MD5 Prefix: ff62266ce9f97. Word: famishment
MD5 Prefix: 9928c88a12353. Word: egress
MD5 Prefix: ad8437d4bf608. Word: applied
MD5 Prefix: 5001324b60b25. Word: gestation
MD5 Prefix: 854c1c9bb71f6. Word: indiscrete
MD5 Prefix: 14c9bd26bf156. Word: tace
MD5 Prefix: dae7d4d46fc4f. Word: terrorist
MD5 Prefix: b6f697830c192. Word: stipellate
MD5 Prefix: f549fe6806d0b. Word: prednisone
MD5 Prefix: ba664e16dd3d8. Word: noons
MD5 Prefix: 05e497be99c28. Word: decibels
MD5 Prefix: 07214c6750d98. Word: entities
MD5 Prefix: 2820f157e9753. Word: paradisiacal
MD5 Prefix: 65ef4dc83456a. Word: castellated
```

    Flag: ricky_mad3_m3_chang3_th3_k3y
