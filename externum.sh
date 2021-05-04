#!/usr/bin/bash

#externum v0.1

# create and name a master folder
clear
read -p "Enter the name of the job folder (e.g. client_ext_data) : " mainfolder

if [ ! -d "$makefolder" ]' then'
    mkdir ~/$mainfolder
fi

cd $mainfolder
if [ ! -d "nmap" ] then
    mkdir nmap
fi

if [ ! -d "enum" ] then
    mkdir enum
fi

if [ ! -d "enum/dns" ] then
    mkdir enum/dns
fi

if [ ! -d "enum/screenshots" ] then
    mkdir enum/screenshots
fi

if [ ! -d "nikto" ] then
    mkdir nikto
fi

if [ ! -d "enum/directories" ] then
    mkdir enum/directories
fi

if [ ! -d "automated" ] then
    mkdir automated
fi
echo "all job folders created"

# creates a targets file
cd ~/$mainfolder
read -p "A targets file will now be created, please paste the in-scope IP's" null
nano targets.txt

# find hostnames associated to IP's
cd nmap
echo "Finding hostnames associated to IP's"
for line in $(cat ../targets.txt); do echo $line" - "$(dig -x $line +short) >> ips_resolved.txt; done

# run nmap against hosts (need to multi-thread this)
echo "---Starting NMAP TCP/UDP against targets - Assuming all hosts up---"

echo "--TCP--"
for i in $(cat ../targets.txt)
do
    nmap -Pn -sSVC $i --top-ports 10000 -oN "$i"_tcp
done

echo "--UDP--"
for i in $(cat ../targets.txt)
do
    nmap -Pn -sSUV $i --tops-ports 200 -oN "$i"_udp 
done


#5 - httpprobe services for potential webservers - output webservers.txt
#6 - eyewitness against namp output and save to folder
#7 - directory brute all webservers
#8 - nikto all webservers
#9 - run nuclei against webservers for vulns - need to look into this one.




