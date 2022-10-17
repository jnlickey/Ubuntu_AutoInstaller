#!/bin/bash
##############################################################################
#
# This script is for generating the seed.iso file for Ubuntu AutoInstaller.
#
# Created by: J.Lickey
# 07/13/2021
# Modified: 10/17/2022
#
# Default credentials: Ansible / ChangeMe
##############################################################################

# Validate password
function PASSWORD () {
	printf "${YEL}Enter password for default username:${NC} "; read -s PASS;
	printf "\n${YEL}Confirm password:${NC} ";read -s PASS2;
	if [[ $(echo ${PASS}) = $(echo ${PASS2}) ]];then
		PASS=$(echo "${PASS}");
	else
		printf "\n${RED}Passwords do not match!${NC}\n";
		PASSWORD;
	fi
}

# Setup Network Configuration
function NETWORK () {
    if [[ ${OS_version} -le 20 ]];then
        # Create Network template file, always needed
        if [[ ! -f ${HOME_DIR}/01-config.yaml-template ]];then
            # Create template for network configuation
            touch ${HOME_DIR}/01-config.yaml-template
            echo "network:" >> ${HOME_DIR}/01-config.yaml-template
            echo "  version: 2" >> ${HOME_DIR}/01-config.yaml-template
            echo "  ethernets:" >> ${HOME_DIR}/01-config.yaml-template
            echo "    INTERFACE:" >> ${HOME_DIR}/01-config.yaml-template
            echo "      addresses: [IP/24]" >> ${HOME_DIR}/01-config.yaml-template
            echo "      gateway4: GATEWAY" >> ${HOME_DIR}/01-config.yaml-template
            echo "      nameservers:" >> ${HOME_DIR}/01-config.yaml-template
            echo "        search: [${DOMAIN}]" >> ${HOME_DIR}/01-config.yaml-template
            echo "        addresses: [${DNSservers}]" >> ${HOME_DIR}/01-config.yaml-template
        fi
    else
        # Create Network template file, always needed
        if [[ ! -f ${HOME_DIR}/01-config.yaml-template ]];then
            # Create template for network configuation
            touch ${HOME_DIR}/01-config.yaml-template
            echo "network:" >> ${HOME_DIR}/01-config.yaml-template
            echo "  version: 2" >> ${HOME_DIR}/01-config.yaml-template
            echo "  ethernets:" >> ${HOME_DIR}/01-config.yaml-template
            echo "    INTERFACE:" >> ${HOME_DIR}/01-config.yaml-template
            echo "      dhcp4: false" >> ${HOME_DIR}/01-config.yaml-template
            echo "      dhcp6: false" >> ${HOME_DIR}/01-config.yaml-template
            echo "      addresses: [IP/24]" >> ${HOME_DIR}/01-config.yaml-template
            echo "      routes:" >> ${HOME_DIR}/01-config.yaml-template
            echo "          - to: default" >> ${HOME_DIR}/01-config.yaml-template
            echo "            via: GATEWAY" >> ${HOME_DIR}/01-config.yaml-template
            echo "      nameservers:" >> ${HOME_DIR}/01-config.yaml-template
            echo "        search: [${DOMAIN}]" >> ${HOME_DIR}/01-config.yaml-template
            echo "        addresses: [${DNSservers}]" >> ${HOME_DIR}/01-config.yaml-template
        fi
    fi
	
	NEW_SERVER_NAME="${1}"
	VLOCATION="${2}"

	printf "${YEL}Enter IP address for${NC} ${NEW_SERVER_NAME}${YEL}:${NC} "; read IP_ans
	if [[ ${IP_ans} =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ ]];then
		IP="${IP_ans}"
		GATEWAY="$(echo ${IP} | cut -d. -f1-3).254"
		if [[ ${VLOCATION} =~ VM|vm ]];then
			INTERFACE="ens160"
		else
			INTERFACE="enp0s17"
		fi
		cp ${HOME_DIR}/01-config.yaml-template ${HOME_DIR}/01-config.yaml
		sed -i "s/INTERFACE/${INTERFACE}/g" ${HOME_DIR}/01-config.yaml
		sed -i "s/GATEWAY/${GATEWAY}/g" ${HOME_DIR}/01-config.yaml
		sed -i "s/IP/${IP}/g" ${HOME_DIR}/01-config.yaml
	else
		printf "${RED}Not a VALID IP address!{NC}"
	fi

    # Network check script for Ubuntu MOTD
    DNS1=$(echo ${DNSservers} | cut -d, -f1)
    DNS2=$(echo ${DNSservers} | cut -d, -f2)
    echo "#!/bin/bash" > ${HOME_DIR}/99-custom-network-test
    echo "result1=\$(ping -c1 $DNS1 | grep received | awk '{print \$4}')" >> ${HOME_DIR}/99-custom-network-test
    echo "result2=\$(ping -c1 $DNS2 | grep received | awk '{print \$4}')" >> ${HOME_DIR}/99-custom-network-test
    echo "if [[ ! \${result1} = \"1\" ]] || [[ ! \${result2} = \"1\" ]];then" >> ${HOME_DIR}/99-custom-network-test
	echo "    echo \"     *** NETWORK CONNECTION DOWN ***     \"" >> ${HOME_DIR}/99-custom-network-test
    echo "fi" >> ${HOME_DIR}/99-custom-network-test
    chmod 775 ${HOME_DIR}/99-custom-network-test
}

# Set's up Docker Installation script
function DOCKERINSTALL () {
    DOCKERAPP=${1}
    result=$(ping -c1 $(echo ${DNSservers}| cut -d"," -f1) | grep received | awk '{print $4}')
    if [[ ${result} = "1" ]];then
        # Builds DockerInstall.sh script
        if [[ ! -f ${HOME_DIR}/DockerInstall.sh ]];then
            touch ${HOME_DIR}/DockerInstall.sh
            chmod 750 ${HOME_DIR}/DockerInstall.sh
            echo -ne "#!/bin/bash\n\n" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "#\n# Install packages for Docker\n#\n" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo apt install apt-transport-https ca-certificates gnupg lsb-release -y" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "\n#\n# Install Docker\n#\n" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" >> ${HOME_DIR}/DockerInstall.sh
            echo 'sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null' >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo apt update" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo apt install docker-ce docker-ce-cli containerd.io -y" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "\n#\n# Install Docker Compose (From Binary)\n#\n" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose" >> ${HOME_DIR}/DockerInstall.sh
            #echo "sudo curl -L \"https://github.com/docker/compose/releases/download/2.11.2/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo chmod +x /usr/local/bin/docker-compose" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "\n#\n# Once you have docker and docker-compose installed, you can make a directory\n#\n" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo mkdir /docker-services && sudo chmod 777 /docker-services" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "\n#\n# After that you can make a directory in there named the same\n# as the appliation that will be running:\n#\n" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo mkdir -p /docker-services/${DOCKERAPP}" >> ${HOME_DIR}/DockerInstall.sh
            echo "sudo touch /docker-services/${DOCKERAPP}/docker-compose.yml" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "\n" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "sudo cp /DockerInstall/daemon.json /etc/docker/daemon.json\n" >> ${HOME_DIR}/DockerInstall.sh
            echo -ne "sudo rm -rf /etc/cron.d/docker-install\n" >> ${HOME_DIR}/DockerInstall.sh
            echo "reboot" >> ${HOME_DIR}/DockerInstall.sh
            echo "exit 0" >> ${HOME_DIR}/DockerInstall.sh
        fi
        
        # Builds daemon.json file
        if [[ ! -f ${HOME_DIR}/daemon.json ]];then
            touch ${HOME_DIR}/daemon.json
            echo '{' >> ${HOME_DIR}/daemon.json
            echo '  "default-address-pools": [' >> ${HOME_DIR}/daemon.json 
            echo '      {"base": "10.241.0.0/16", "size":24}' >> ${HOME_DIR}/daemon.json
            echo '  ],' >> ${HOME_DIR}/daemon.json
            echo '  "log-driver": "json-file",' >> ${HOME_DIR}/daemon.json
            echo '  "log-opts": {' >> ${HOME_DIR}/daemon.json
            echo '    "max-size": "300m",' >> ${HOME_DIR}/daemon.json
            echo '    "max-file": "3",' >> ${HOME_DIR}/daemon.json
            echo '    "labels": "production_status",' >> ${HOME_DIR}/daemon.json
            echo '    "env": "os"' >> ${HOME_DIR}/daemon.json
            echo '  }' >> ${HOME_DIR}/daemon.json
            echo '}' >> ${HOME_DIR}/daemon.json
        fi
    fi
}

function Build_USER-DATA(){
	# Build user-data file
	echo "#cloud-config" > ${HOME_DIR}/user-data 
	echo "# Helpful sights:" >> ${HOME_DIR}/user-data
	echo "#        https://louwrentius.com/understanding-the-ubuntu-2004-lts-server-autoinstaller.html"  >> ${HOME_DIR}/user-data
	echo "#        https://www.edwardssite.com/cloud-init" >> ${HOME_DIR}/user-data
	echo "#        https://ubuntu.com/server/docs/install/autoinstall-referencie#commandlist" >> ${HOME_DIR}/user-data
	echo "#        https://www.convertunits.com/from/bytes/to/MB" >> ${HOME_DIR}/user-data
	echo "autoinstall:" >> ${HOME_DIR}/user-data
	echo "  version: 1" >> ${HOME_DIR}/user-data
	echo "  ineractive-sections:" >> ${HOME_DIR}/user-data
	echo "  keyboard: {layout: 'us', variant: ''}" >> ${HOME_DIR}/user-data
	echo "  locale: en_US.UTF-8" >> ${HOME_DIR}/user-data
	echo -ne "\n" >> ${HOME_DIR}/user-data
	echo "  # Identification" >> ${HOME_DIR}/user-data
	echo "  identity:" >> ${HOME_DIR}/user-data
	echo "    hostname: ${NEW_SERVER_NAME}" >> ${HOME_DIR}/user-data
	echo "    username: ${USERNAME}" >> ${HOME_DIR}/user-data
	echo "    password: \"$(openssl passwd -6 ${PASS})\"" >> ${HOME_DIR}/user-data
	echo "  ssh:" >> ${HOME_DIR}/user-data
	echo "    allow-pw: true" >> ${HOME_DIR}/user-data
	echo "    install-server: true" >> ${HOME_DIR}/user-data
	echo -ne "\n"  >> ${HOME_DIR}/user-data
}

function Build_STORAGE(){
	# Storage Information for user-data
	if [[ ${DISK} =~ Y|y ]];then
		#### IF LVM BEING USED ####
		echo -ne "  # Storage Information\n" >> ${HOME_DIR}/user-data
		echo -ne "  storage:\n" >> ${HOME_DIR}/user-data
		echo -ne "    config:\n" >> ${HOME_DIR}/user-data
		#### Partition the disk ####
		echo -ne "    # Find Disk, Partition Boot/EFI, and wipe clean (268435456 = 256MB, 536870912 = 512MB)\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {grub_device: true, id: disk-sda, name: '', path: /dev/sda, preserve: false, ptable: gpt, type: disk, wipe: superblock-recursive}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: disk-sda, flag: bios_grub, grub_device: false, id: partition-0, number: 1, preserve: false, size: 1048576, type: partition}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: disk-sda, flag: '', grub_device: false, id: partition-1, number: 2, preserve: false, size: 536870912, type: partition, wipe: superblock}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-0, preserve: false, type: format, volume: partition-1}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: disk-sda, flag: '', grub_device: false, id: partition-2, number: 3, preserve: false, size: 134217728, type: partition, wipe: superblock}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-1, preserve: false, type: format, volume: partition-2}\n" >> ${HOME_DIR}/user-data
		echo -ne "\n"
		echo -ne "    # Create SWAP space and mount it (2147483648 = 2GB)\n"  >> ${HOME_DIR}/user-data
		echo -ne "    - {device: disk-sda, flag: swap, grub_device: false, id: partition-3, number: 4, preserve: false, size: 2147483648, type: partition, wipe: superblock}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: swap, id: format-2, preserve: false, type: format, volume: partition-3}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-2, id: mount-2, path: '', type: mount}" >> ${HOME_DIR}/user-data
		echo -ne "\n" >> ${HOME_DIR}/user-data   
		echo -ne "    # Create LVM Group from remaining disk space\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: disk-sda, flag: '', grub_device: false, id: partition-4, number: 5, preserve: false, size: -1, type: partition, wipe: superblock}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - devices:\n" >> ${HOME_DIR}/user-data
		echo -ne "      - partition-4\n" >> ${HOME_DIR}/user-data
		echo -ne "      id: lvm_volgroup-0\n" >> ${HOME_DIR}/user-data
		echo -ne "      name: ${VGNAME}\n" >> ${HOME_DIR}/user-data
		echo -ne "      preserve: false\n" >> ${HOME_DIR}/user-data
		echo -ne "      type: lvm_volgroup\n" >> ${HOME_DIR}/user-data
		echo -ne "\n" >> ${HOME_DIR}/user-data
		#### Create LVM Filesystems ####
		echo -ne "    # Create LVM Filesystems\n" >> ${HOME_DIR}/user-data
		echo -ne "    # /\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {id: lvm_partition-0, name: FS_root, preserve: false, size: 4290772992B, type: lvm_partition, volgroup: lvm_volgroup-0}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-5, preserve: false, type: format, volume: lvm_partition-0}\n"  >> ${HOME_DIR}/user-data  
		echo -ne "    # /home\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {id: lvm_partition-1, name: FS_home, preserve: false, size: 2147483648B, type: lvm_partition, volgroup: lvm_volgroup-0}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-6, preserve: false, type: format, volume: lvm_partition-1}\n" >> ${HOME_DIR}/user-data
		echo -ne "    # /var\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {id: lvm_partition-2, name: FS_var, preserve: false, size: 2147483648B, type: lvm_partition, volgroup: lvm_volgroup-0}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-7, preserve: false, type: format, volume: lvm_partition-2}\n" >> ${HOME_DIR}/user-data
		echo -ne "    # /opt\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {id: lvm_partition-4, name: FS_opt, preserve: false, size: 1073741824B, type: lvm_partition, volgroup: lvm_volgroup-0}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-8, preserve: false, type: format, volume: lvm_partition-4}\n" >> ${HOME_DIR}/user-data
		echo -ne "    # /tmp\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {id: lvm_partition-5, name: FS_tmp, preserve: false, size: 1073741824B, type: lvm_partition, volgroup: lvm_volgroup-0}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-9, preserve: false, type: format, volume: lvm_partition-5}\n" >> ${HOME_DIR}/user-data
		echo -ne "    # /usr\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {id: lvm_partition-6, name: FS_usr, preserve: false, size: 4442450944B, type: lvm_partition, volgroup: lvm_volgroup-0}\n"  >> ${HOME_DIR}/user-data
		echo -ne "    - {fstype: ext4, id: format-10, preserve: false, type: format, volume: lvm_partition-6}\n" >> ${HOME_DIR}/user-data
		echo -ne "    # /var/log\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {id: lvm_partition-3, name: FS_var_log, preserve: false, size: 2147483648B, type: lvm_partition, volgroup: lvm_volgroup-0}\n" >> ${HOME_DIR}/user-data 
		echo -ne "    - {fstype: ext4, id: format-11, preserve: false, type: format, volume: lvm_partition-3}\n" >> ${HOME_DIR}/user-data
		echo -ne "\n"  >> ${HOME_DIR}/user-data
			#### Mount Filesystems ####
		echo -ne "    # Mount Storage devices\n" >> ${HOME_DIR}/user-data  
		echo -ne "    - {device: format-0, id: mount-0, path: /boot, type: mount}\n"  >> ${HOME_DIR}/user-data  
		echo -ne "    - {device: format-1, id: mount-1, path: /boot/efi, type: mount}\n"  >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-5, id: mount-5, path: /, type: mount}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-6, id: mount-6, path: /home, type: mount}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-7, id: mount-7, path: /var, type: mount}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-8, id: mount-8, path: /opt, type: mount}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-9, id: mount-9, path: /tmp, type: mount}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-10, id: mount-10, path: /usr, type: mount}\n" >> ${HOME_DIR}/user-data
		echo -ne "    - {device: format-11, id: mount-11, path: /var/log, type: mount}\n" >> ${HOME_DIR}/user-data
		echo -ne "\n" >> ${HOME_DIR}/user-data
	else
		#### If ONLY one filesystem being used ####
		echo -ne "  # Storage Information\n" >> ${HOME_DIR}/user-data
		echo -ne "  storage:\n" >> ${HOME_DIR}/user-data
		echo -ne "    layout:\n" >> ${HOME_DIR}/user-data
		echo -ne "      name: lvm\n" >> ${HOME_DIR}/user-data
		echo -ne "\n" >> ${HOME_DIR}/user-data
	fi
}

function Install_PKGS(){
	local DEFAULT_PACKAGES="${1}"
	local PACKAGES="${2}"
	# Install Packages
	# If other packages need to be installed by default. They can be added to the DEFAULT_PACKAGES list
	PACK=$(echo "${DEFAULT_PACKAGES},${PACKAGES}" | tr ',' ' ')
	echo -ne "  # Post-install packages to download and include\n"  >> ${HOME_DIR}/user-data
	echo -ne "  packages:\n" >> ${HOME_DIR}/user-data
	for i in ${PACK}; do 
		echo -ne "    - ${i}\n" >> ${HOME_DIR}/user-data
	done
}

function VM_TOOLS(){
	# Install VirtualBox or open-VMware-tools
	if [[ ${LOCATION} =~ VB|vb|vB|Vb ]];then 
		VBPACKAGES=$(echo "build-essential,dkms,virtualbox-guest-additions-iso" | tr ',' ' ')
		#VBPACKAGES=$(echo "${VBSpecialPackages}" | tr ',' ' ')
		for p in ${VBPACKAGES};do
		echo -ne "    - ${p}\n" >> ${HOME_DIR}/user-data
		done
	elif [[ ${LOCATION} =~ VM|vm|Vm|vM ]];then
		echo -ne "    - open-vm-tools\n" >> ${HOME_DIR}/user-data
	elif [[ ${LOCATION} =~ N|NO|No|nO ]];then
		break;   	
	fi

	echo -ne "\n" >> ${HOME_DIR}/user-data
	echo -ne "  # Commands to complete after installation\n" >> ${HOME_DIR}/user-data
	echo -ne "  late-commands:\n" >> ${HOME_DIR}/user-data
	echo -ne "    - mkdir /tmp/mnt\n" >> ${HOME_DIR}/user-data
	echo -ne "    - mount /dev/sr1 /tmp/mnt\n" >> ${HOME_DIR}/user-data
	echo -ne "    - curtin in-target --target=/target -- touch /etc/cloud/cloud-init.disabled\n" >> ${HOME_DIR}/user-data
}

function Create_SEED() {
	# Create the seed.iso file
	# cloud-localds ${HOME_DIR}/seed.iso ${HOME_DIR}/user-data ${HOME_DIR}/meta-data
	printf "${YEL}Create seed.iso file in${NC} ${HOME_DIR} ${YEL}(Y|N):${NC} "; read ANS
        FILES2PKG="${HOME_DIR}/user-data ${HOME_DIR}/meta-data ${HOME_DIR}/DockerInstall.sh ${HOME_DIR}/daemon.json ${HOME_DIR}/01-config.yaml ${HOME_DIR}/99-custom-network-test"
	if [[ ${ANS} =~ [Y|y][E|e][S|s]|[Y|y] ]];then
		if [[ ${DOCKER} =~ Y|y ]];then
			if [[ ${LOCATION} =~ vb|VB ]];then
				mkisofs -V cidata -r -o ${HOME_DIR}/seed-${NEW_SERVER_NAME}-vb.iso ${HOME_DIR}/user-data ${HOME_DIR}/meta-data ${HOME_DIR}/DockerInstall.sh ${HOME_DIR}/daemon.json ${HOME_DIR}/01-config.yaml ${HOME_DIR}/99-custom-network-test 2>/dev/null
			else
				mkisofs -V cidata -r -o ${HOME_DIR}/seed-${NEW_SERVER_NAME}-vm.iso ${FILES2PKG} 2>/dev/null
			fi
		else
			if [[ ${LOCATION} =~ vb|VB ]];then
				mkisofs -V cidata -r -o ${HOME_DIR}/seed-${NEW_SERVER_NAME}-vb.iso ${FILES2PKG} 2>/dev/null
			else
				mkisofs -V cidata -r -o ${HOME_DIR}/seed-${NEW_SERVER_NAME}-vm.iso ${FILES2PKG} 2>/dev/null
			fi
		fi
	elif [[ ${ANS} = '' ]];then
		printf "${RED}You didn't enter yes|Y|y or no|N|n${NC}\n"
		Create_SEED
	else
		exit
	fi
}

function Create_DIR(){
	# Create location for user-data, seed.iso, and meta-data files
	if [[ ! -d ${HOME_DIR} ]];then
		mkdir ${HOME_DIR}
	fi
	if [[ ! -f ${HOME_DIR}/meta-data ]];then
		touch ${HOME_DIR}/meta-data
	fi
}

function Default_Config(){
	# Setup NETWORKING with netplan config
 	echo -ne "    - cp /tmp/mnt/01-config.yaml /target/etc/netplan/01-config.yaml\n" >> ${HOME_DIR}/user-data
    	# Check NETWORKING via MOTD
    	echo -ne "    - cp /tmp/mnt/99-custom-network-test /target/etc/update-motd.d/99-custom-network-test\n" >> ${HOME_DIR}/user-data
    	# Adding default DNS entries
    	DNS1="$(echo ${DNSservers} | cut -d, -f1)"
    	DNS2="$(echo ${DNSservers} | cut -d, -f2)"
    	Domains="$(echo ${DOMAIN} | tr ',' ' ')"
    	printf "    - sed -i 's/^#DNS\=/DNS\=/g;s/^#Fall/Fall/g;s/^#Domains\=/Domains\=/g' /target/etc/systemd/resolved.conf\n" >> ${HOME_DIR}/user-data
    	printf "    - sed -i '/^DNS\=/ s/\$/${DNS1}/' /target/etc/systemd/resolved.conf\n" >> ${HOME_DIR}/user-data
    	printf "    - sed -i '/^Fall.*\=/ s/\$/${DNS2}/' /target/etc/systemd/resolved.conf\n" >> ${HOME_DIR}/user-data
    	printf "    - sed -i '/^Domains\=/ s/\$/${Domains}/' /target/etc/systemd/resolved.conf\n" >> ${HOME_DIR}/user-data

   	# Adding Ansible user
	# Adding Ansible user to sudo
	printf "    - echo \"ansible ALL=(ALL:ALL) NOPASSWD:ALL\" > /target/etc/sudoers.d/ansible_admin\n" >> ${HOME_DIR}/user-data
	printf "    - chmod 0440 /target/etc/sudoers.d/ansible_admin\n" >> ${HOME_DIR}/user-data
	# Pulled from .pub for the Ansible user
	if [[ ${AnsibleSSHKEY} = '' ]];then
		AnsibleSSHKEY="ssh-rsa somerandomcharacterssomerandomcharacterssomerandomcharacterssomerandomcharacters ansible@something"
	fi
	# Used read PASS;openssl passwd -6 $PASS to create hash
	if [[ ${AnsibleHASH} = '' ]];then
		AnsibleHASH="\$6\$UOrIRkykWLbC0ACt\$hilixjxWZFOJ0lLk1dbHD.kifrb42TzG8gDg47u3N4lmu/5DUE55KGtvk1giAQj3VNYNBb4f6/7HN3FXx/o1q/"
	fi
    	printf "    - curtin in-target --target=/target -- /usr/sbin/useradd -m -c \"Ansible Account\" -s /bin/bash -G sudo -p \'${AnsibleHASH}\' ansible\n" >> ${HOME_DIR}/user-data
    	printf "    - curtin in-target --target=/target -- mkdir /home/ansible/.ssh\n" >> ${HOME_DIR}/user-data
    	printf "    - curtin in-target --target=/target -- chmod 0700 /home/ansible/.ssh\n" >> ${HOME_DIR}/user-data
    	printf "    - curtin in-target --target=/target -- touch /tmp/authorized_keys\n" >> ${HOME_DIR}/user-data
	printf "    - curtin in-target --target=/target -- install -o ansible -g ansible -m 0600 /tmp/authorized_keys -t /home/ansible/.ssh\n" >> ${HOME_DIR}/user-data
	printf "    - echo \"${AnsibleSSHKEY}\" >> /target/home/ansible/.ssh/authorized_keys\n" >> ${HOME_DIR}/user-data
    	printf "    - curtin in-target --target=/target -- chown -R ansible:ansible /home/ansible/\n" >> ${HOME_DIR}/user-data

	# Adding additional user
	PASSWD=$(openssl passwd -6 ${PASS})
    	printf "    - curtin in-target --target=/target -- /usr/sbin/useradd -m -c \"${USERNAME} Account\" -s /bin/bash -p \'${PASSWD}\' ${USERNAME}\n" >> ${HOME_DIR}/user-data
    
	# Setting timezone 
	case ${timez} in
        	EST) timezone="America/New_York";;
        	CST) timezone="America/Chicago";;
        	MNT) timezone="America/Denver";;
        	HI) timezone="US/Hawaii";;
        	ALASKA|alaska|Alaska) timezone="US/Alaska";;
        	*) timezone="America/Los_Angeles";;
    	esac
    	echo -ne "    - curtin in-target --target=/target -- timedatectl set-timezone ${timezone}\n" >> ${HOME_DIR}/user-data 
	
	# Update system
	if [[ ${UPDATES} =~ y|Y ]];then
		echo -ne "    - curtin in-target --target=/target -- apt update\n" >> ${HOME_DIR}/user-data           
		echo -ne "    - curtin in-target --target=/target -- apt upgrade -y\n" >> ${HOME_DIR}/user-data
	fi

}

function Install_Docker(){
	# Install Docker and Docker Compose
	if [[ ${DOCKER} =~ Y|y ]];then
		DOCKERINSTALL ${DOCKERAPP}
		echo -ne "    - mkdir /target/DockerInstall\n" >> ${HOME_DIR}/user-data 
		echo -ne "    - cp /tmp/mnt/daemon.json /target/DockerInstall/daemon.json\n" >> ${HOME_DIR}/user-data
		echo -ne "    - cp /tmp/mnt/DockerInstall.sh /target/DockerInstall/DockerInstall.sh\n" >> ${HOME_DIR}/user-data
		echo -ne "    - chmod 777 /target/DockerInstall/DockerInstall.sh\n" >> ${HOME_DIR}/user-data
		echo -ne "    - echo '@reboot root /usr/bin/sleep 30 && /DockerInstall/DockerInstall.sh' | sudo tee /target/etc/cron.d/docker-install\n" >> ${HOME_DIR}/user-data
	fi
}

function Reboot_SRV(){
	# Add reboot server to user-data
	echo -ne "\n" >> ${HOME_DIR}/user-data
	echo -ne "  # Process to restart the server after build completes, and allow root ssh access\n" >> ${HOME_DIR}/user-data
	echo -ne "  user-data:\n" >> ${HOME_DIR}/user-data
	echo -ne "    timezone: ${timezone}\n" >> ${HOME_DIR}/user-data 
	echo -ne "    disable_root: false\n" >> ${HOME_DIR}/user-data
	echo -ne "    power_state:\n" >> ${HOME_DIR}/user-data
	echo -ne "      mode: reboot\n" >> ${HOME_DIR}/user-data
	echo -ne "      condition: true\n" >> ${HOME_DIR}/user-data
}

function PKGS_For_ISO(){
	# Check for needed packages for creation of seed.iso
	INSTALLED1=$(sudo dpkg-query -W -f='${Status}\n' openssl | cut -d" " -f3)
	INSTALLED2=$(sudo dpkg-query -W -f='${Status}\n' cloud-image-utils | cut -d" " -f3)
	if [[ ${INSTALLED1} = '' ]];then
		printf "Would you like to install openssl now? "; read ans
			if [[ ${ans} =~ Y|y ]];then
					INSTALL1="openssl"
			fi
	elif [[ ${INSTALLED2} = '' ]];then
			printf "Would you like to install cloud-image-utils now? "; read ans
			if [[ ${ans} =~ Y|y ]];then
			INSTALL2="cloud-image-utils"
		fi
	fi
    	if [[ ${INSTALL1} = "openssl" ]] && [[ ${INSTALL2} = "cloud-image-utils" ]];then
		sudo apt install openssl cloud-image-utils -y
	elif [[ ${INSTALL1} = "openssl" ]]; then
			sudo apt install openssl -y
	elif [[ ${INSTALL2} = "cloud-image-utils" ]]; then
		sudo apt install cloud-image-utils -y	
	fi
}
# ========================================= MAIN SCRIPT =========================================
# Colors
RED='\033[1;31m'
GRN='\033[1;32m'
YEL='\033[1;33m'
NC='\033[0m' # No Color

# Start New Configuration
printf "${GRN}This script generates the seed.iso file for Ubuntu AutoInstaller.${NC}\n"
printf "Would you like to continue (Y|N): ";read ANS

if [[ ${ANS} =~ [Y|y][E|e][S|s]|[Y|y] ]];then
	if [[ ! -d "/home/${USER}/www" ]];then
		mkdir /home/${USER}/www
	fi	
	if [[ -f /home/${USER}/www/user-data ]];then
		printf "Do you want to re-create ISO from info in /home/${USER}/www (Yes|Y|y), continue a new build (press ENTER), or quit (quit|Q|q): "; read recreate
		if [[ ${recreate} =~ [Y|y][E|e][S|s]|[Y|y] ]];then
			Create_SEED
			exit
		elif [[ ${recreate} =~ [Q|q][U|u][I|i][T|t]|[Q|q] ]]; then
			exit
		fi
	fi
	# Source default variables
	if [[ ! -f /home/${USER}/www/seed.env ]];then
		printf "${YEL}You can set default variables in:${NC} /home/${USER}/www/seed.env\n"
		printf "# Set hostname of server to install\n" > /home/${USER}/www/seed.env
		printf "export NEW_SERVER_NAME=\n" >> /home/${USER}/www/seed.env
		printf "# OS Version\n" >> /home/${USER}/www/seed.env
		printf "export OS=\"22.04\"\n" >> /home/${USER}/www/seed.env
		printf "# Set domain name needs to end with a period, and multiple comma seperated (ad1.example.com.,ad2.example.com.)\n" >> /home/${USER}/www/seed.env
                printf "export DOMAIN=\"ad.example.com.,example.com.\"\n" >> /home/${USER}/www/seed.env
		printf "# Set filesystems to use LVM\n" >> /home/${USER}/www/seed.env
         	printf "export DISK='y'\n" >> /home/${USER}/www/seed.env
		printf "# Set volume group name\n" >> /home/${USER}/www/seed.env
		printf "export VGNAME=vgroot\n" >> /home/${USER}/www/seed.env
		printf "# Set username\n" >> /home/${USER}/www/seed.env
		printf "export USERNAME=myuser\n" >> /home/${USER}/www/seed.env
		printf "# Install DOCKER by default\n" >> /home/${USER}/www/seed.env
		printf "export DOCKER='y'\n" >> /home/${USER}/www/seed.env
		printf "# Set Docker Compose installation directory\n" >> /home/${USER}/www/seed.env
		printf "export DOCKERAPP='DockerApp'\n" >> /home/${USER}/www/seed.env
		printf "# Set Location for VMware or VirtualBox\n" >> /home/${USER}/www/seed.env
		printf "export LOCATION='VM'\n" >> /home/${USER}/www/seed.env
		printf "# Set timezone ( EST, CST, MNT, PST, Alaska, or HI (Hawaii) )\n" >> /home/${USER}/www/seed.env
		printf "export timez='EST'\n" >> /home/${USER}/www/seed.env
		printf "# Set system updates\n" >> /home/${USER}/www/seed.env
		printf "export UPDATES='y'\n" >> /home/${USER}/www/seed.env
		printf "# Set Home directory location\n" >> /home/${USER}/www/seed.env
		printf "export HOME_DIR=\"/home/${USER}/www\"\n" >> /home/${USER}/www/seed.env
		printf "# Set default DNS servers, comma seperated\n" >> /home/${USER}/www/seed.env
		printf "export DNSservers='8.8.8.8,127.0.0.1'\n" >> /home/${USER}/www/seed.env
		printf "# REQUIRED DEFAULT Packages for VirtualBox\n" >> /home/${USER}/www/seed.env
		printf "export DEFAULT_PACKAGES_VB=\"resolvconf,vim,curl,wget,openssh-server,perl,build-essential,hwinfo,ifupdown,locate,net-tools\"\n" >> /home/${USER}/www/seed.env 
		printf "# REQUIRED DEFAULT Packages for VMware\n" >> /home/${USER}/www/seed.env
		printf "export DEFAULT_PACKAGES_VM=\"vim,curl,wget,openssh-server,perl\"\n" >> /home/${USER}/www/seed.env
		printf "# Set Other Packages to install\n" >> /home/${USER}/www/seed.env
		printf "export PACKAGES=\n" >> /home/${USER}/www/seed.env
		printf "# Set Password Hash for Ansible User: read PASS;openssl passwd -6 \$PASS\n" >> /home/${USER}/www/seed.env
		printf "export AnsibleHASH=\n" >> /home/${USER}/www/seed.env
		printf "# Set Ansible user SSH Key in /home/ansible/.ssh/authorized_keys\n" >> /home/${USER}/www/seed.env
		printf "export AnsibleSSHKEY=\n" >> /home/${USER}/www/seed.env
	else
		printf "${GRN}/home/${USER}/www/seed.env is present${NC}\n"
	fi

	source /home/${USER}/www/seed.env
    	
	# Clean-up Old Configs
	rm -f ${HOME_DIR}/01-config.yaml* ${HOME_DIR}/daemon.json ${HOME_DIR}/DockerInstall.sh ${HOME_DIR}/meta-data ${HOME_DIR}/user-data ${HOME_DIR}/*seed.iso
    
    	# Install needed Packages for Building ISO
	PKGS_For_ISO

    	# Start setup of user-data
	printf "${YEL}Enter version of OS [${OS}]:${NC} "; read OS_ans
	printf "${YEL}Enter hostname for new server:${NC} "; read NEW_SERVER_NAME
	printf "${YEL}Use multiple filesystems with LVM (Y|N) [${DISK}]:${NC} "; read DISK_ans
	if [[ ${DISK_ans} = '' ]];then
		printf "${YEL}Enter name of volume group [${VGNAME}]:${NC} "; read VGNAME_ans
        	if [[ ! ${VGNAME_ans} = '' ]];then
            		VGNAME="${VGNAME_ans}"
        	fi
    	else
        	DISK=${DISK_ans}
	fi
	printf "${YEL}Enter default username for server: [${USERNAME}]${NC}"; read USERNAME_ans
	if [[ ! ${USERNAME_ans} = '' ]];then
        	USERNAME="${USERNAME_ans}"
	fi
    
	# Call Password Function
	PASSWORD

	# Continue setup of user-data
	printf "\n${YEL}Install Docker and Docker Compose (Y|N) [${DOCKER}]:${NC} "; read DOCKER_ans
	if [[ ! ${DOCKER_ans} = '' ]];then
		DOCKER="${DOCKER_ans}"
	fi
    	if [[ ${DOCKER} =~ y|Y ]];then
        	printf "\n${YEL}Enter name of Docker application (Ex. AllOneWord) [${DOCKERAPP}]:${NC} "; read DOCKERAPP_ans
        	if [[ ! ${DOCKERAPP_ans} = '' ]];then
            		DOCKERAPP="${DOCKERAPP_ans}"
        	fi
    	fi
	printf "${YEL}Is new VM in VirtualBox or VMware (VB|VM) [${LOCATION}]:${NC} "; read LOCATION_ans
    	if [[ ! ${LOCATION_ans} = '' ]];then
        	LOCATION="${LOCATION_ans}"
	fi
	if [[ ${LOCATION} =~ [V|v][B|b] ]];then
		printf "${YEL}Default packages to be installed:${NC} ${GRN}${DEFAULT_PACKAGES_VB}${NC}\n"
		pkg="vb"
	else
		printf "${YEL}Default packages to be installed:${NC} ${GRN}${DEFAULT_PACKAGES_VM}${NC}\n"
		pkg="vm"
	fi
	printf "${YEL}Other packages to install from standard Ubuntu Repo's (pkg,pkg,pkg... or press ENTER for none):${NC} "; read PACKAGES_ans
    	if [[ ! ${PACKAGES_ans} = '' ]];then
        	PACKAGES="${PACKAGES_ans}"
    	fi

	# Call NETWORK Function
   	 if [[ ! ${OS_ans} = '' ]];then
        	OS="${OS_ans}"
    	fi
    	OS_version=$(echo ${OS} | cut -d"." -f1)
	NETWORK ${NEW_SERVER_NAME} ${LOCATION} ${OS_version}

	# Ask to run updates
	printf "${YEL}Run updates for new server (Y|N) [${UPDATES}]:${NC} "; read UPDATES_ans
	if [[ ! ${UPDATES_ans} = '' ]];then
		UPDATES="${UPDATES_ans}"
	fi

	# Ask for timezone info
	printf "${YEL}Enter timezone (EST, CST, MNT, PST, ALASKA, HI) [${timez}]: ";read timez_ans
	if [[ ! ${timez_ans} = '' ]];then
		timez=${timez_ans}
	fi
	    
	Create_DIR
	Build_USER-DATA
	Build_STORAGE
	if [[ ${pkg} = "vb" ]];then
		Install_PKGS ${DEFAULT_PACKAGES_VB} ${PACKAGES}
	else
		Install_PKGS ${DEFAULT_PACKAGES_VM} ${PACKAGES}
	fi
	VM_TOOLS
	Install_Docker
	Default_Config ${PASS} ${DNSServers}
	Reboot_SRV
	Create_SEED
else
	exit
fi

exit 0
