# EXTERNUM

A framework written in Bash that is designed to help automate and increase efficiency when conducting external penetration tests.


# Screenshots:
--------------
![Screenshot_2021-06-01_13-42-12](https://user-images.githubusercontent.com/75701798/120325647-c5fb2c00-c2df-11eb-9cae-cd5b02b4f57c.png)

# Information:
-------------
This is my first venture into creating a framework to try and increase efficiency by automating some of the more laborious recon and enumeration tasks of an external penetration test. I realise that there are many programs out there that will do significantly more than this this program, but this is in line with my personal methodology.

To coin a phrase from the film Full Metal Jacket: "This is my program. There are many like it, but this one is mine"

It is not perfect, and I will be making many improvements and additions to it over the coming months/years, but I hope that it helps someone, somewhere.

### Requirements:
-----------------
Externum requires a few packages to be installed on your system in order to work. I am not going to give instructions on how to install each one as there are very comprehensive instructions on each makers github wiki page.

**Each of the following programs needs to be installed and accessible from your path:**

| Program   | Link to resource |
|:----------|:-----------------|
| Amass     | (https://github.com/OWASP/Amass) |
| Naabu     | (https://github.com/projectdiscovery/naabu) |
| Httprobe  | (https://github.com/tomnomnom/httprobe) |
| Fuff      | (https://github.com/ffuf/ffuf) |
| GoWitness | (https://github.com/sensepost/gowitness) |
| Nikto     | sudo apt-get install nikto (From Debian based system)
| Nmap      | sudo apt-get install nmap (From Debian based system)

NOTE: I would just like to give thanks to the makers of the above applications that have made my life easier over the years. Without people like them contributing to our community our jobs would be a lot harder. 

### Usage:
---------

**Externum has three positional arguments as follows:**

| Argument | Status    | Description |
|:---------|:----------|:------------|
|   -o     | OPTIONAL  | Enables the OSINT recon section of the framework. All IP's will be checked against the ipinfo.io api returning associated hostnames. These hostnames will then be sent to amass where all subdomains will be enumerated. |
|   -t     | REQUIRED  | Path to your target file that contains a list of IP's (One per line) |
|   -w     | REQUIRED  | Path to your chosen wordlist | 

NOTE: The nmap scans will require root privileges so it's best to run Externum elevated from the start, although you will be prompted if you forget.

Example:
```bash
sudo ./externum.sh -o -t <PATH TO TARGET FILE> -w <PATH TO WORDLIST>
```

I hope you enjoy it and happy hunting.
  