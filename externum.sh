#!/usr/bin/bash

#externum v0.1

# create and name a master folder
clear
read -p "Enter the name of the job folder (e.g. client_ext_data) : " mainfolder

if [ ! -d "./$mainfolder" ]; then
    mkdir $mainfolder
fi

cd $mainfolder
if [ ! -d "./nmap" ]; then
    mkdir nmap
fi

if [ ! -d "./enum" ]; then
    mkdir enum
fi

if [ ! -d "./enum/dns" ]; then
    mkdir enum/dns
fi

if [ ! -d "./enum/screenshots" ]; then
    mkdir enum/screenshots
fi

if [ ! -d "./nikto" ]; then
    mkdir nikto
fi

if [ ! -d "./enum/directories" ]; then
    mkdir enum/directories
fi

if [ ! -d "./automated" ]; then
    mkdir automated
fi
echo "all job folders created"

# creates a targets file
read -p "A targets file will now be created. Press enter to add IP's to scope" null
nano targets.txt

# find hostnames associated to IP's
echo "Finding hostnames associated to IP's"
for line in $(cat targets.txt);
do echo $line" - "$(dig -x $line +short) >> enum/dns/ips_resolved.txt
    $(cat enum/dns/ips_resolved.txt) | cut -d " " -f 3 | grep -Po "(\w+\.\w+\.)$" | cut -d "." -f 1,2 | tee enum/dns/tlds.txt;
done

# go out and enumerate subdomains to associated IP and then compare against inscope IP's

wait

# run nmap against hosts (need to multi-process this)
echo "---Starting NMAP TCP/UDP against targets - Assuming all hosts up---"

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




