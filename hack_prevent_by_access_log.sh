#!/bin/bash
# this script will grep the last (XXX) entries in access_log and checks 
# wether one ip is hammering on our website.
#
#
# the script works like this:
#  ~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  get the last XXX (1000) entries in access_ssl_log. each line contains
#  a request.
#  so php|html  files and images, css and so on are in the output
#  - we grep within this string all requests for php|html files (so
#    amazon and other picture grabbers are left out)
#  - we only take the entries of the current and last minute (max 2min)
#    to narrow the attack time
#  - we exclude all requests from admin|export folder to let our own
#    scripts do what they have to do
# 
#  If one IP has XXX (100) requests (see def. below) request for a php|html
#  file within the access log after the filters we BAN it!
# 
#  Why is this correct? If a website is loaded at least 10-20-30 files
#  will be requested. Ok, we try to cache by header very hard and this
#  might have the effect that all subsidary content is loaded from the
#  cache of the browser.
#  But XXX (50) requests from one IP within the last XXX (max 2min) seems to
#  be pretty much a bombing and not a regular user. 
#
# Don't forgett to check your robots.txt some commercial crawler can be
# banned easily
#
# to manually unban:
# ~~~~~~~~~~~~~~~~~~
# fail2ban-client set plesk-apache-badbot unbanip [YOURIPADDRESS]
#
# Sun Dec 11 00:05:10 CET 2022 all rights reserved, Mathias E. Koch  <mk@adoptimize.de>
#
###############################################################################################################

_fail2banJail="plesk-apache-badbot"
_weblog="[YOUR_PTH]/logs/hack_prevent_by_access_log.sh.banned_ips.log"
_logfile="/tmp/hack_prevent_by_access_log.sh.log"
_accesslog="[YOUR_PTH]/logs/access_ssl_log"
let _tailLength=1000
let _banLimit=70

# define a time range within the log current Minute and current Minute - 1
let _minute=$(date '+%M');
let _start=$((_minute - 1));
_grepdate=$(date '+%d\/%b\/%Y:%H:')
_grepdate="${_grepdate}\(${_start}\|${_minute}\)"

# get the latest entries from log
_last100=$(tail -${_tailLength} ${_accesslog})

# write the 100 entries into a logfile
echo "${_last100}" > ${_logfile}

# grep for ip-addresses and a php|hmtl-files in log (css, images are left out)
_firstFilter=$(grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}.*${_grepdate}.*GET.*\(php\|html\).*HTTP" ${_logfile})
echo "${_firstFilter}" > ${_logfile};

# exclude admin requests 
_secondFilter=$(grep -v '\/admin\/' ${_logfile})
echo "${_secondFilter}" > ${_logfile};

# exclude scripts in export folder 
_thirdFilter=$(grep -v '/export/' ${_logfile})
echo "${_thirdFilter}" > ${_logfile};

# count the occurence of the IP in the new written logfile
_counter=$(cat ${_logfile} | awk '{print $1}' | sort -n | uniq -c | sort -nr | head -100)

# how often a ip was matched. at the beginning 0
let _amount=0;

for _count in ${_counter}; 
do
    _ip='';

    if [[ ${_count} =~ \. ]]; 
    then
        _ip=${_count};
    else
        let _amount=${_count}
    fi

    # lets ban ips having more than 30 php files  opened within the last 100 entries
    if (( ${_amount} >  ${_banLimit} )) && [[ ${_ip} =~ \. ]]; 
    then
        # catch importand bots not been banned. 
        _canBeBanned=$(host ${_ip} | awk -F " " '{print $NF}' | grep -v 'google.*\.\|msn\.com\.\|apple.com\.\|ahrefs\.com\.|yandex\.com\.')

        if [ ! -z "${_canBeBanned}" ]; 
        then
          _jailed=$(fail2ban-client -vvv set plesk-apache-badbot banip ${_ip})
          echo ${_jailed}
          _msg="${_ip} had been banned because having ${_amount} requests within the last ${_tailLength} lines in access log. $(date '+%D %H:%M:%S')"
          echo ${_msg} >> ${_weblog};
        fi
# for debbuging.
    else

        if (( ${_amount} <= ${_banLimit} )) && [[ ${_ip} =~ \. ]]; 
        then
            _canBeBanned=$(host ${_ip} | awk -F " " '{print $NF}' | grep -v 'google.*\.\|msn\.com\.\|apple.com\.\|ahrefs\.com\.|yandex\.com\.')

            if [ -z "${_canBeBanned}" ]; 
            then
                _msg=" ${_ip} has not been banned because having ${_amount} requests within the last ${_tailLength} lines in access log. $(date '+%D %H:%M:%S')"
			    echo ${_msg}
            fi
        fi
    fi
done;

exit 0;

