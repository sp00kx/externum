#!/usr/bin/bash

#externum v0.1

# create and name a master folder
clear
read -p "Enter the name of the job folder (e.g. client_ext_data) : " mainfolder
mkdir ~/$mainfolder
cd $mainfolder
mkdir nmap
mkdir enum
mkdir enum/dns
mkdir enum/screenshots
mkdir enum/nikto
mkdir enum/directories
mkdir automated
echo "all job folders created"

# creates a targets file
cd ~/$mainfolder
read -p "A targets file will now be created, please paste the in-scope IP's" null
nano targets.txt

# find hostnames associated to IP's
cd nmap
echo "Finding hostnames associated to IP's"
for line in $(cat ../targets.txt); do echo $line" - "$(dig -x $line +short) >> ips_resolved.txt; done

# run nmap against hosts
echo "---Starting NMAP TCP/UDP against targets - Assuming all hosts up---"
echo "--TCP--"
    nmap -Pn -sSVC -iL ../targets.txt -p- -oA nmap_tcp_all
echo "--UDP--"
    nmap -Pn -sSUV -iL ../targets.txt -p- -oA nmap_udp_all



#5 - httpprobe services for potential webservers - output webservers.txt
#6 - eyewitness against namp output and save to folder
#7 - directory brute all webservers
#8 - nikto all webservers
#9 - run nuclei against webservers for vulns - need to look into this one.




