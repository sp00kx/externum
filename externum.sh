#!/usr/bin/bash

#Externum DEV v0.4

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
    mkdir enum/nikto
    mkdir enum/directories
echo

# creates a targets file
read -r -p "A targets file will now be created. Press enter to add IP's to scope " null
nano targets.txt

# find hostnames associated to IP's
echo
echo "Finding hostnames associated to IP's"
echo
echo "Hostnames Discovered:"
    
for ip in $(cat targets.txt) ; do
    ip_info=$(curl -s $ipinfo/"$ip"/hostname)
        echo "$ip_info" | cut -d "." -f 2-4 | sort -u >> enum/dns/resolved_tlds.txt;
done
cat enum/dns/resolved_tlds.txt

#stop check to access if hostnames look correct - left out in Dev v0.3 as not sure its needed
#echo
#while true; do
#    read -r -p "Do the hostnames look correct (Y/N): " yn
#    case $yn in
#        [Yy]* ) break;;
#        [Nn]* ) nano enum/dns/resolved_tlds.txt;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done

# go out and enumerate subdomains to associated IP and then compare against inscope IP's
echo
echo "Looking for all associated subdomains to target, please be patient this may take a little while"
for line in $(cat enum/dns/resolved_tlds.txt);
    do  amass enum -ipv4 -silent -o enum/dns/enumerated_subdomains.txt -d "$line";
done


# Add in a wc result for how many subdomains enumerated
echo
echo "Number of subdomains found:"; wc -l < enum/dns/enumerated_subdomains.txt


# looking for quick win webservers
echo
echo "Looking for open services, please be patient"
sudo naabu -p - -iL targets.txt -silent -o potentialwebservers.txt > /dev/null 2>&1
echo
echo "Number of open services found:"; wc -l < potentialwebservers.txt
echo
echo "Probing services for active webservers"
cat potentialwebservers.txt | httprobe >> webservers.txt





# run nmap against hosts
#echo
#echo "All OSINT is complete, now starting NMAP TCP/UDP against target IP's"
#echo
#cd nmap/
#echo "--Scanning TCP in parallel, please be patient--"
#sudo rush "nmap -Pn -sSVC --top-ports 10000 {} -oN {}" -i ../targets.txt -j 5 > /dev/null 2>&1


#echo "--Scanning UDP 200 top ports, please be patiet--"
#sudo rush "nmap -Pn -sUV --top-ports 200 {} -oN {}" -i ../targets.txt -j 3
