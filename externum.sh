#!/bin/bash

#Global defined variables
ipinfo="https://ipinfo.io"

# Colours
red="\e[31m"
blue="\e[34m"
green="\e[32;48m"
colouroff="\e[0m"

# Opening functions
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
    echo "by automating some of the more laborious tasks of initial information"
    echo "gathering and enumeration."
    echo
    echo "The tool will initially discover hostnames associated to the target IP's"
    echo "then perform some subdomain enumeration before moving on to trying to"
    echo "identify some quick wins."
    echo
    echo "Once this is complete it should give you enough information to get on with"
    echo "some manual testing. Whilst this is happening Externum will be carrying out"
    echo "a full scan of the target IP's to find all open/closed ports and services"
    echo
    echo -e "${blue}Usage:${colouroff}"
    echo "Due to certain commands Externum is designed to be run as root"
    echo
    echo " -t   Path to targets file (Required)"
    echo " -w   Path to wordlist for directory enumeration (Required)"
    echo " -o   Enables OSINT plugin that looks for hostnames & enumerates subdomains (Optional)"
    echo " -h   Show this usage message"
    echo
    echo "example: sudo ./externum.sh -o -t <target.txt> -w <wordlist.txt>"
    echo
    exit
}

spinner () {
    pid=$! # Process Id of the previous running command

    spin='-\|/'

    i=0
    while kill -0 $pid 2>/dev/null
    do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1} - Working"
    sleep .1
    done
    echo -e "\nDone!"
}

banner

# positonal error capture
if [ $# -eq 0 ]; then
    banner
    usage
fi

while getopts "h:t:w:o" selection; do
	case "${selection}" in
		    o) osint=true;;
            t) target_file=${OPTARG};;
            w) wordlist=${OPTARG};;
            h) banner; usage; exit;;
            *) banner; usage; exit;;
 	esac
done


# Create master folder and subfolders
echo "Creating job folders"
if [ ! -d "./externum-results" ]; then
    mkdir externum-results
    mkdir externum-results/enum
    mkdir externum-results/enum/nmap
    mkdir externum-results/enum/nmap/tcp
    mkdir externum-results/enum/nmap/udp
    mkdir externum-results/enum/dns
    mkdir externum-results/enum/screenshots
    mkdir externum-results/enum/screenshots/captures
    mkdir externum-results/enum/nikto
    mkdir externum-results/enum/directories
    touch externum-results/logfile.txt
fi
usr_file_path=$( realpath "$target_file" )
cp "$usr_file_path" ./externum-results/targets.txt
sleep 1

osint_enum() {
    # find hostnames associated to IP's
    echo "Time: $(date -Iseconds). osint started." >> externum-results/logfile.txt
    echo 
    echo -e "${blue}Hostnames associated to IP's:${colouroff}"
    for ip in $(cat ./externum-results/targets.txt) ; do
        ip_info=$(curl -s $ipinfo/"$ip"/hostname)
            echo "$ip_info" | cut -d "." -f 2-4 | sort -u >> ./externum-results/enum/dns/resolved_tlds.txt;
    done
    cat ./externum-results/enum/dns/resolved_tlds.txt

    # Enumerate subdomains to associated IPs and store for manual analysis
    echo
    echo -e "${blue}Looking for all associated subdomains to targets, please be patient this may take a little while${colouroff}"
    
    # check is amass is installed
    if ! command -v amass &>/dev/null; then
        banner
        echo -e ${red}"Badtimes! You need Amass installed for Externum to work"${colouroff}
        exit
    else
        for line in $(cat ./externum-results/enum/dns/resolved_tlds.txt);
            do  amass enum -ipv4 -silent -o ./externum-results/enum/dns/enumerated_subdomains.txt -d "$line" &
            spinner
        done
    fi
    # Add in a wc result for how many subdomains enumerated
    echo
    echo -e "$blue"Number of subdomains found:"$colouroff"; wc -l < ./externum-results/enum/dns/enumerated_subdomains.txt
    echo "Time: $(date -Iseconds). osint completed." >> ./externum-results/logfile.txt
}



quickenum() {
    # looking for quick win webservers
    echo
    echo "Time: $(date -Iseconds). common port enum started." >> ./externum-results/logfile.txt
    echo -e "${blue}Looking for common open services, please be patient${colouroff}"
    # check if Naabu is installed
    if ! command -v naabu &>/dev/null; then
        banner
        echo -e ${red}"Badtimes! You need Naabo installed for Externum to work"${colouroff}
        exit
    else
        naabu -p 80,443,8080,8443,8005,8009,8181,4848,9000,8008,9990,7001,9043,9060,9080,9443,1527,7777,4443 -iL ./externum-results/targets.txt -silent -o ./externum-results/enum/potentialwebservers.txt > /dev/null 2>&1 &
        spinner
    fi
    echo "Time: $(date -Iseconds). common port enum completed." >> ./externum-results/logfile.txt
   
    #httprobe
    echo
    echo "Time: $(date -Iseconds). probing for active webservers." >> ./externum-results/logfile.txt
    echo -e "${blue}Probing discovered services for active webservers${colouroff}"
    cat ./externum-results/enum/potentialwebservers.txt | httprobe >> ./externum-results/enum/webservers.txt
    echo
    echo -e "${blue}Number of active webservers found:${colouroff}"; wc -l < ./externum-results/enum/webservers.txt
    echo "Time: $(date -Iseconds). webserver probe complete." >> ./externum-results/logfile.txt

    #directory enum
    echo
    echo "Time: $(date -Iseconds). starting directory bruteforce." >> ./externum-results/logfile.txt
    echo -e "${blue}Busting some directories and looking for codes: ${colouroff}"
    if ! command -v ffuf &>/dev/null; then
        banner
        echo -e ${red}"Badtimes! You need ffuf installed for Externum to work"${colouroff}
        exit
    else
        if [[ "$wordlist" == "" ]]; then
            echo -e ${red}"Badtimes! You have forgotten to add the path to your wordlist"${colouroff}
            exit
        else
            for line in $(cat ./externum-results/enum/webservers.txt); do
               ffuf -u $line/FUZZ -H "User-Agent: Firefox" -w "$wordlist" -t 10 -mc 200,204,401,403,500,501,502 -recursion -recursion-depth 1 -s -of csv -o ./externum-results/enum/directories/$(echo $line | cut -d "/" -f 3).csv > /dev/null 2>&1 &
               spinner
            done
        fi   
    fi
    echo "Time: $(date -Iseconds). directory busting complete." >> ./externum-results/logfile.txt
    
    #nikto
    echo
    echo "Time: $(date -Iseconds). starting nikto." >> ./externum-results/logfile.txt
    echo -e "${blue}Scanning the webservers using Nikto: ${colouroff}"
    if ! command -v rush &>/dev/null; then
        banner
        echo -e ${red}"Badtimes! You need Rush installed for Externum to work"${colouroff}
        exit
    else
        if ! command -v nikto &>/dev/null; then
            banner
            echo -e ${red}"Badtimes! You need Nikto installed for Externum to work"${colouroff}
            exit
        else #Running nikto multi threaded using rush
            rush "nikto --ask no --maxtime 15m -host {} -Format html -o ./externum-results/enum/nikto/AllResults.html" -i ./externum-results/enum/webservers.txt -j 10 &
            spinner
        fi
        echo "Time: $(date -Iseconds). nikto complete." >> ./externum-results/logfile.txt
    fi
    

    #Screenshots GoWitness
    echo
    echo "Time: $(date -Iseconds). starting gowitness screen capture." >> ./externum-results/logfile.txt
    echo -e "${blue}Grabbing some screenprints, nearly finshed.${colouroff}"
    if ! command -v gowitness &>/dev/null; then
        banner
        echo -e ${red}"Badtimes! You need GoWitness installed for Externum to work"${colouroff}
        exit
    else
        gowitness file -f ./externum-results/enum/webservers.txt -t 10 --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0" -P ./externum-results/enum/screenshots/captures --db-path ./externum-results/enum/screenshots/captures.sqlite3 > /dev/null 2>&1 &
        spinner
    fi
    echo "Time: $(date -Iseconds). gowitness complete." >> ./externum-results/logfile.txt

}


nmap() {
    echo
    echo -e ${red}
    echo "All quick enumeration has now finshed, you should have some juicy info to go and check."
    echo
    echo "In the meantime Externum will begin the nmap TCP all port, and UDP Top 200 scan which"
    echo "may take sometime, we will not be running scripts but are multi threading the scans"
    echo "so will be as quick as possible."
    echo
    echo "Why dont you go grab a coffee"
    echo -e ${colouroff}


    # run nmap against hosts
    echo
    echo -e ${blue}
    echo "Dont forget you will need to be root for this section, you will be prompted for the password next"
    echo
    echo "Time: $(date -Iseconds). starting nmap TCP all ports." >> ./externum-results/logfile.txt
    echo "Starting NMAP TCP/UDP against target IP's"
    echo -e ${colouroff}

    sudo rush "nmap -Pn -sSV -T4 --top-ports 1000 {} -oN ./externum-results/enum/nmap/tcp/{}" -i ./externum-results/targets.txt -j 5 > /dev/null 2>&1 &
    spinner
    
    echo "Time: $(date -Iseconds). completed nmap TCP all ports." >> ./externum-results/logfile.txt

    echo "Time: $(date -Iseconds). starting nmap UDP top 200 ports." >> ./externum-results/logfile.txt
    echo -e ${blue}"Starting NMAP UDP against target IP's${colouroff}"
    
    sudo rush "nmap -Pn -sUV --top-ports 200 {} -oN ./externum-results/enum/nmap/udp/{}" -i ./externum-results/targets.txt -j 5 > /dev/null 2>&1 &
    spinner
    
    echo "Time: $(date -Iseconds). completed nmap UDP top 200 ports." >> ./externum-results/logfile.txt

}

# Main Menu
if [ "$osint" == true ]; then
    osint_enum
    quickenum
    nmap
else
    quickenum
    nmap
fi
