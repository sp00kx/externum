#!/usr/bin/bash

#externum v0.1

# create and name a master folder
clear
read -p "Enter the name of the job folder (e.g. client_ext_data) : " mainfolder

if [ ! -d "./$mainfolder" ]; then
    mkdir $mainfolder
fi

cd $mainfolder
    mkdir nmap
    mkdir enum
    mkdir enum/dns
    mkdir enum/screenshots
    mkdir nikto
    mkdir enum/directories
    mkdir automated

echo ""

# creates a targets file
read -p "A targets file will now be created. Press enter to add IP's to scope" null
nano targets.txt

# find hostnames associated to IP's
echo ""
echo "Finding hostnames associated to IP's"
echo ""
echo "Hostnames Discovered"
    cat enum/dns/resolved_tlds.txt

for line in $(cat targets.txt); do echo $line" - "$(dig -x $line +short) | cut -d " " -f 3 | grep -Po "(\w+\.\w+\.)$" | cut -d "." -f 1,2  >> enum/dns/resolved_tlds.txt; done

# go out and enumerate subdomains to associated IP and then compare against inscope IP's
echo ""
echo "Looking for all associated subdomains to target, please be patient this may take a little while"
for line in $(cat enum/dns/resolved_tlds.txt);
    do  amass enum -ipv4 -silent -o enum/dns/enumerated_subdomains.txt -d $line;
done
wait

# Add in a wc result for how many subdomains enumerated

# run nmap against hosts (need to multi-process this consider rush)
echo ""
echo "All OSINT is complete, now starting NMAP TCP/UDP against target IP's"
echo ""
echo "--TCP--"
for i in $(cat ../targets.txt)
do
    nmap -Pn -sSVC $i --top-ports 10000 -oN "$i"_tcp
done

echo "--UDP--"
for i in $(cat ../targets.txt)
do
    nmap -Pn -sSUV $i --top-ports 200 -oN "$i"_udp 
done
wait

# format results from nmap scans
echo "cleaning nmap results"
grep -Hari "/tcp" | cut -d "/" -f 1 >> allservices.txt
grep -Hari "/udp" | cut -d "/" -f 1 >> allservices.txt

#httpprobe services for potential webservers - output webservers.txt




#6 - eyewitness against namp output and save to folder
#7 - directory brute all webservers
#8 - nikto all webservers
#9 - run nuclei against webservers for vulns - need to look into this one.
