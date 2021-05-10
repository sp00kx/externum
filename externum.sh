#!/usr/bin/bash

#Externum v0.2

#Defined Variables
ipinfo="https://ipinfo.io"

#Colours
colouron="\e[34m"
colouroff="\e[0m"

#functions
banner () {
    clear
    echo -e "$colouron"   
    echo -e             "░█▀▀▀ ▀▄░▄▀ ▀▀█▀▀ ░█▀▀▀ ░█▀▀█ ░█▄─░█ ░█─░█ ░█▀▄▀█"
    echo -e             "░█▀▀▀ ─░█── ─░█── ░█▀▀▀ ░█▄▄▀ ░█░█░█ ░█─░█ ░█░█░█"
    echo -e             "░█▄▄▄ ▄▀░▀▄ ─░█── ░█▄▄▄ ░█─░█ ░█──▀█ ─▀▄▄▀ ░█──░█ by SirJestalot"
    echo ""
    echo -e             "An automated external pentest enumeration tool"
    echo -e "$colouroff"
}

#***********************************************************************************************************

banner

# create master folder and subfolders
echo
read -r -p "Enter the name of the job folder (e.g. client_ext_data) : " mainfolder

if [ ! -d "./$mainfolder" ]; then
    mkdir "$mainfolder"
fi

cd "$mainfolder" || exit
    mkdir nmap
    mkdir enum
    mkdir enum/dns
    mkdir enum/screenshots
    mkdir nikto
    mkdir enum/directories
    mkdir automated

echo

# creates a targets file
read -p "A targets file will now be created. Press enter to add IP's to scope" null
nano targets.txt

# find hostnames associated to IP's
echo
echo "Finding hostnames associated to IP's"
echo
echo "Hostnames Discovered:"
    
for ip in $(cat targets.txt) ; do
    ip_info=$(curl -s $ipinfo/"$ip"/hostname)
        echo "$ip_info" | cut -d "." -f 2-4 >> enum/dns/resolved_tlds.txt;
done
cat enum/dns/resolved_tlds.txt

#stop check to access if hostnames look correct.
echo
while true; do
    read -p "Do the hostnames look correct (Y/N): " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# go out and enumerate subdomains to associated IP and then compare against inscope IP's
echo
echo "Looking for all associated subdomains to target, please be patient this may take a little while"
for line in $(cat enum/dns/resolved_tlds.txt);
    do  amass enum -ipv4 -silent -o enum/dns/enumerated_subdomains.txt -d "$line";
done


# Add in a wc result for how many subdomains enumerated
echo
echo "Number of subdomains found:"; wc -l < enum/dns/enumerated_subdomains.txt

# run nmap against hosts (need to multi-process this consider rush)
echo
echo "All OSINT is complete, now starting NMAP TCP/UDP against target IP's"
echo
echo "--TCP--"
for i in $(cat ../targets.txt)
do
    nmap -Pn -sSVC "$i" --top-ports 10000 -oN "$i"_tcp
done

echo "--UDP--"
for i in $(cat ../targets.txt)
do
    nmap -Pn -sSUV "$i" --top-ports 200 -oN "$i"_udp 
done
wait

# format results from nmap scans
echo "cleaning nmap results"
grep -Hari "/tcp" | cut -d "/" -f 1 >> allservices.txt
grep -Hari "/udp" | cut -d "/" -f 1 >> allservices.txt

#httpprobe services for potential webservers - output webservers.txt
