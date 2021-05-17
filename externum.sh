#!/bin/bash

#Externum DEV v0.5

#Defined Variables
ipinfo="https://ipinfo.io"

#Colours
blue="\e[34m"
green="\e[32;5;48m"
colouroff="\e[0m"

#functions
banner () {
    clear
    echo -e "$green"   
    echo -e             "░█▀▀▀ ▀▄░▄▀ ▀▀█▀▀ ░█▀▀▀ ░█▀▀█ ░█▄─░█ ░█─░█ ░█▀▄▀█"
    echo -e             "░█▀▀▀ ─░█── ─░█── ░█▀▀▀ ░█▄▄▀ ░█░█░█ ░█─░█ ░█░█░█"
    echo -e             "░█▄▄▄ ▄▀░▀▄ ─░█── ░█▄▄▄ ░█─░█ ░█──▀█ ─▀▄▄▀ ░█──░█ by sp00kx"
    echo -e "$colouroff"
}

usage () {
    echo
    echo -e "${blue}Description:${colouroff}"
    echo "This tool is designed to assit a penetration tester with an external test"
    echo "by automating some of the more labourious tasks of intial informaiton"
    echo "gathering and enumeration."
    echo
    echo "The tool will initially discover hostnames associated to the target IP's"
    echo "then perform some subdomain enumeration before morning on to trying to"
    echo "identify some quick wins."
    echo
    echo "Once this is compelte it should give you enough informaiton to get on with"
    echo "some manual testing. Whilst this is happening Externum will be carrying out"
    echo "a full scann of the target IP's to find all open/closed ports and services"
    echo
    echo -e "${blue}Usage:${colouroff}"
    echo "Due to cetain commands Externum is designed to be run as root"
    echo
    echo " -t   Path to targets file (Required)"
    echo " -w   Path to wordslist for directory enumeration (Required)"
    echo " -o   Enables OSINT (Looks for hostnames / enumerates subdomains)"
    echo " -h   Show this usage message"
    echo
    echo "example: sudo ./externum.sh -o -t <target.txt> -w <wordlist.txt>"
    echo
    exit
}

banner

# positonal error capture
if [ $# -eq 0 ]; then
    banner
    usage
fi

while getopts "t:w:h" selection; do
	case "${selection}" in
		    t) target_file=${OPTARG};;
            w) wordlist=${OPTARG};;
            o) osint=${OPTARG};;
	    	h) banner; usage; exit;;
	    	*) banner; usage; exit;;
 	esac
done



# Create master folder and subfolders
echo
read -r -p 'Enter the name of the job folder (e.g. client_ext_data) : ' mainfolder

if [ ! -d ./$mainfolder ]; then
    mkdir $mainfolder
    mkdir $mainfolder/nmap
    mkdir $mainfolder/enum
    mkdir $mainfolder/enum/dns
    mkdir $mainfolder/enum/screenshots
    mkdir $mainfolder/enum/nikto
    mkdir $mainfolder/enum/directories
fi

# Copy users target file to main job folders
usr_file_path=$( realpath "$target_file" )
cp "$usr_file_path" "$mainfolder"/



# OSINT FUNCTION HERE


# find hostnames associated to IP's
echo 
echo -e "${blue}Hostnames associated to IP's:${colouroff}"

for ip in $target_file ; do
    ip_info=$(curl -s $ipinfo/"$ip"/hostname)
        echo "$ip_info" | cut -d "." -f 2-4 | sort -u >> enum/dns/resolved_tlds.txt;
done
cat enum/dns/resolved_tlds.txt

# Enumerate subdomains to associated IPs and store for manual analysis
echo
echo -e "${blue}Looking for all associated subdomains to target, please be patient this may take a little while${colouroff}"

for line in $(cat enum/dns/resolved_tlds.txt);
    do  amass enum -ipv4 -silent -o enum/dns/enumerated_subdomains.txt -d "$line";
done

# Add in a wc result for how many subdomains enumerated
echo
echo -e "$blue"Number of subdomains found:"$colouroff"; wc -l < enum/dns/enumerated_subdomains.txt

#END OF OSINT FUNCTION HERE



# looking for quick win webservers
echo
echo -e "${blue}Looking for open services, please be patient${colouroff}"
sudo naabu -p - -iL targets.txt -silent -o potentialwebservers.txt > /dev/null 2>&1
echo
echo -e "${blue} Number of open services found:${colouroff}"; wc -l < potentialwebservers.txt
echo
echo -e "${blue}Probing services for active webservers${colouroff}"
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
