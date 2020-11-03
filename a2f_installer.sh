#!/bin/bash

function addA2FToServicePam
{
    # Add the line: auth required pam_oath.so usersfile=/etc/users.oath window=10 digits=6     at the end of the file /etc/pam.d/$service_name 
    line=$(sudo awk '/auth/ && /required/ && /pam_oath\.so/ && /usersfile=\/etc\/users\.oath/ && /window=10/ && /digits=6/' /etc/pam.d/$service)
    if [ -z "$line" ]; then
        echo "Add following lines to /etc/pam.d/$service :"
        pamA2F="\n# A2F\nauth required pam_oath.so usersfile=/etc/users.oath window=10 digits=6"
        echo -e $pamA2F | sudo tee -a /etc/pam.d/$service
    fi

    case $service in
        "sshd")
            echo ""
            echo "Check in /etc/ssh/sshd_config if the parameters ChallengeResponseAuthentication is set to 'yes'"
            echo ""
            echo "Check in /etc/ssh/sshd_config if the parameters PasswordAuthentication is set to 'no'"
            echo ""
            echo "Execute the command: systemctl restart sshd.service"
            echo ""
            ;;
        "sudo")
            echo ""
            echo "Reboot the the system to apply A2F to sudo.service"
            echo ""
            ;;
        *)
            echo ""
            echo "Restart the $service service"
            echo ""
            ;;
    esac
}

function addUserToUsersOathFile
{
    # Generate an A2F seed and add it with username  at the end of the file /etc/users.oath
    if [ ! -e ~/gen-oath-safe/gen-oath-safe ]; then
        git clone https://github.com/mcepl/gen-oath-safe.git ~/gen-oath-safe
    fi

    echo "Scan the QR below or copy and paste the b32 key into a keepass that manages OTP :"
    ~/gen-oath-safe/gen-oath-safe $username totp | tee /tmp/output.txt

    secret=$(tail -n 1 /tmp/output.txt)
    echo "Add the following line to /etc/users.oath :"
    echo $secret | sudo tee -a /etc/users.oath

    rm /tmp/output.txt
}

##function installCentosPackages
##{
##    # Install packages depending on whether they are already installed or not
##    for package in ${packages[*]}; do
##        sudo yum list --installed | grep $package || sudo yum install $package
##    done
##}

function installDebianPackages
{
    # Install packages depending on whether they are already installed or not
    for package in ${packages[*]}; do
        sudo dpkg -l | grep -qw $package || sudo apt-get install $package
    done
}

#################### Tool Initialisation ####################

# Get distribution and version ID
id=$(sudo cat /etc/os-release | grep -E "^ID=(.)*")
id=${id:3} 

# Install packages
case $id in
    "ubuntu" | "debian")
        packages=('libpam-oath' 'oathtool' 'caca-utils' 'qrencode')
        installDebianPackages
    ;;
    ##"\"centos\"")
    ##    packages=('pam_oath' 'oathtool' 'caca-utils' 'qrencode')
    ##    installCentosPackages
    #"";;
    *)
        echo "No packages available for $id."
    ;;
esac

# Create the file /etc/users.oath that contains each username and their A2F secret (seed)
if [ ! -e /etc/users.oath ]; then
    sudo touch /etc/users.oath
    sudo chmod go-rw /etc/users.oath
fi

############################################################

if [ -z "$1" ] || [[ "$1" =~ (-h|--help)  ]]; then
        echo "usage: bash $0 [-s service_name|-u username]"
        echo ""
        echo "service_name: service that requires authentication"
        echo "              Ex: sshd, sudo, ..."
        echo ""
        echo "username: [issuer:]username[@[domain]]"
        echo "          using @ without domain uses"
        echo "          host's FQDN as domain"
    exit 1
fi

if [ ! -z "$1" ]; then
    case $1 in
        "-s")
            if [ ! -z "$2" ]; then
                service="$2"
                addA2FToServicePam
            fi
            ;;
        "-u")
            if [ ! -z "$2" ]; then
                username="$2"
                addUserToUsersOathFile
            fi
            ;;
        *)
            echo "unknow command: bash $0 $*"
            exit 1
            ;;
    esac
fi