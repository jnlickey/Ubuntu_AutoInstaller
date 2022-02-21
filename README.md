# Ubuntu_AutoInstaller
This script was designed in order to ease the installation process of Ubuntu server. It was designed to create an answer file that can be used to setup initial users, disks using Logical Volume Manager (LVM), and patches with minimal user interaction.

## Using CreateSeedISOwDocker.sh
<ol>
  <li>Download and Run CreateSeedISOwDocker.sh</li>   
    <ul>
      <li>FIRST RUN ONLY - The script will prompt to download any missing packages that are required, if they are not already installed on your Linux system</li>
      <li>FIRST RUN ONLY - Select all of the defaults (Default settings appear inside square brackets - [  ] )</li>
      <li>FIRST RUN ONLY - When prompted to build the ISO file at the end, say "no"</li>
    </ul>
  
  <li>The script when ran will auto generate a directory named /home/&#60;user&#62;/www, and an environment variable file /home/&#60;user&#62;/www/seed.env</li>
    <ul>
      <li>/home/&#60;user&#62;/www/ - is the directory that stores the data that is used to create the seed-&#60;servername&#62;.iso file</li>
      <li>/home/&#60;user&#62;/www/seed.env - is a file that contains default variables that can be modified for future seed-&#60;servername&#62;.iso file creations, or simply re-used</li>
    </ul>  
</ol>

   ![image](https://user-images.githubusercontent.com/13524582/154775732-c0f7627c-4350-42d4-b288-e5dbc076f8fa.png)

NOTE: It is strongly recommended that you modify/change the variable `AnsibleHASH=''` from the default in /home/&#60;user&#62;/www/seed.env, by running the following command:

```
read PASS;openssl passwd -6 $PASS
```
![image](https://user-images.githubusercontent.com/13524582/154776986-c03b7bb1-5a76-4596-85c5-bd6e57ef7b82.png)
<ul>
  <li>Copy the long list of characters starting with $6$... and paste it in the variable field for `AnsibleHash='\$6\$...'` in the /home/&#60;user&#62;/seed.env file.</li>
  <li>Add forward slashes in front of any dollar signs that are in the string of characters, and surround the string with single quotes</li>
</ul>

  ![image](https://user-images.githubusercontent.com/13524582/154777566-d6b5f2c4-0e9f-4bd6-9691-5c651c440579.png)
<ul>
  <li>Adding an SSH Key for Ansible</li>
  <ul>
    <li>Generate an SSH key pair or copy the contents from /home/&#60;user&#62;/.ssh/id_rsa.pub for an existing ansible account</li>
  </ul>
</ul>

```
ssh-keygen
```
<ul>
  <ul>
  <li>Add the contents from /home/&#60;user&#62;/.ssh/id_rsa.pub to the `AnsibleSSHKEY=''` variable in the /home/&#60;user&#62;/www/seed.env file</li>
  <li>Surround the contents with single quotes</li>
  </ul>
</ul>
  
   ![image](https://user-images.githubusercontent.com/13524582/154778797-59de9a2b-8c54-4a49-b5e0-5ecca7b64a93.png)

## Default Credentials
<ul>
  <li>Username: myuser</li>
  <li>Password: Whatever you type in, when prompted</li>
  <li>Username: ansible</li>
  <li>Password: ChangeMe</li>
  <ul>
    <li>NOTE: The ansible user is the only one setup with sudo permissions, and the root password is not set.</li>
  </ul>
</ul>

## Docker Installation
<ul>
  <li>Docker and Docker Compose are installed by default, unless you choose not to install it when running CreateSeedISOwDocker.sh</li>
  <li>Docker and Docker Compose installation script/files can be found under /DockerInstall/ once installation is complete</li>
    <ul><li>NOTE: The Docker install script will reboot the system</li></ul>
  <li>Docker Compose files can be found under /docker-services/&#60;DockerApp&#62;</li>
</ul>

## Building a Virtual machine using the seed-&#60;servername&#62;.iso file
<ol>
  <li>Download latest Ubuntu Server: https://ubuntu.com/download/server</li>
  <li>Download WinSCP: https://winscp.net/download/WinSCP-5.19.5-Setup.exe</li>
    <ul>
      <li>Tool used for transferring files between linux host (where CreateSeedISOwDocker.sh script is ran) and a Windows host where the virtual environment might be located. (e.g. VirtualBox, VMware Workstation Player, VMware Workstation, or others)</li>
    </ul>
  <li>When building the virtual machine using the seed-&#60;servername&#62;.iso file it requires you to have two (2) CD/DVD drives.</li>
  <ul>
    <li>CD/DVD drive 1: UbuntuServer.iso</li>
    <li>CD/DVD drive 2: seed-&#60;servername&#62;.iso</li>
  </ul>
  <li>Boot the server</li>
  <li>At the prompt to continue using autoinstall, type 'yes' and press enter</li>
  <li>The server should then continue to be setup per the answer file, and will reboot</li>
  <li>After the reboot, it should come up and you should be able to login to it with the username that you created when running the CreateSeedISOwDocker.sh scipt or the ansible account.</li>
</ol>
    
## Troubleshooting
<ul>
  <li>If the system does not boot the first time, switch the ISO files in the CD/DVD drives</li>
  <li>If you are unable to login to the server after the reboot, you will need to enter single user mode:</li>
    <ol>
      <li>Reboot the server</li>
      <li>Press 'ESC' quickly as the server reboots (You may need to press it multiple times)</li>
      <li>At the Ubuntu GRUB menu, press 'e' to edit the GRUB Boot options</li>
      <li>Scroll through the list until you find a line starting with 'linux' and is indented</li>
      <li>Goto the end of that 'linux' line, add a space and enter 'init=/bin/bash'</li>
      <li>Press F10 to continue booting the system into single user mode</li>
      <li>At the root prompt enter the following:</li>
        <ul>
          <li>mount -o remount,rw /</li>
          <li>passwd root</li>
          <li>Input a password for the root account, and confirm it, by entering the same password again</li>
          <li>reboot -f</li>
        </ul>
      <li>Once the server comes back up, login as the root account, with the password that you just setup.</li>
      <li>You will then need to manually re-create the new user and ansible accounts that were suppose to be added via the answer file</li>
      <li>You should also manually re-run the /DockerInstall/DockerInstall.sh script to install Docker/Docker Compose. NOTE: this script WILL reboot the server</li>
    </ol>
</ul>
    
## Archive Information Below
<s>To create a new seed.iso file:
1) Create a www directory under your home:  mkdir /home/$USER/www
2) Create an empty meta-data file under www: touch /home/$USER/www/meta-data
3) Install 'cloud-image-utils': apt install cloud-image-utils -y
4) Run the following command:
rm -rf /home/$USER/www/seed.iso; cloud-localds /home/$USER/www/seed.iso /home/$USER/www/user-data /home/$USER/www/meta-data

Current user for testing is: ubuntu

Current password hash is: ubuntu</s>
