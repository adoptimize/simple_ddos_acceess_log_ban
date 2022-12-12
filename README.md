

Abstract:
 this script will grep the last (XXX) entries in access_log and checks
 wether one ip is hammering on our website.

Dependency:
 To use this script you will need a working fail2ban installation on
 your server



 the script works like this:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~
 get the last XXX (1000) entries in access_ssl_log. each line contains
 a request.
 so php|html  files and images, css and so on are in the output
 - we grep within this string all requests for php|html files (so
   amazon and other picture grabbers are left out)
 - we only take the entries of the current and last minute (max 2min)
   to narrow the attack time
 - we exclude all requests from admin|export folder to let our own
   scripts do what they have to do

 If one IP has XXX (100) requests (see def. below) request for a php|html
 file within the access log after the filters we BAN it!

 Why is this correct? If a website is loaded at least 10-20-30 files
 will be requested. Ok, we try to cache by header very hard and this
 might have the effect that all subsidary content is loaded from the
 cache of the browser.
 But XXX (50) requests from one IP within the last XXX (max 2min) seems to
 be pretty much a bombing and not a regular user. 

 Be carful with the limits. Google and other wanted crawlers can have 
 multiple requests in a very short time. The Browser information in the
 log is like any other text string and can not be trusted. The config
 of the script is pretty well working for a online-shop with about 30k
 products in three different languages. The more content, the more
 crawls you can have. Testing is your friend. Of course you can 
 whitelist google bots, bing and others, but this is just 

 to manually unban:
 fail2ban-client set plesk-apache-badbot unbanip [YOURIPADDRESS]


