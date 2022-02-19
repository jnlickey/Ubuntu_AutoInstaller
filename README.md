# Ubuntu_AutoInstaller
This script was designed in order to ease the installation process of Ubuntu server. It was designed to create an answer file that can be used to setup initial users, disks using Logical Volume Manager (LVM), and patches with minimal user interaction.

## Using CreateSeedISOwDocker.sh
<ol>
  <li>Download and Run CreateSeedISOwDocker.sh</li>   
    <ul>
      <li>FIRST RUN ONLY - The script will prompt to download any missing packages that are required, if they are not already installed on your Linux system</li>
      <li>FIRST RUN ONLY - Select all of the defaults</li>
      <li>FIRST RUN ONLY - When prompted to build the ISO file at the end, say "no"</li>
    </ul>
  
  <li>The script when ran will auto generated a directory named /home/&#60;user&#62;/www, and an environment variable file /home/&#60;user&#62;/seed.env</li>
    <ul>
      <li>/home/&#60;user&#62;/www/ - is the directory that stores the data that is used to create the seed-&#60;servername&#62;.iso file</li>
      <li>/home/&#60;user&#62;/www/seed.env - is a file that contains default variables that can be modified for future seed-&#60;servername&#62;.iso file creations</li>
    </ul>  
</ol>

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
  <li></li>
</ul>

  ![image](https://user-images.githubusercontent.com/13524582/154775732-c0f7627c-4350-42d4-b288-e5dbc076f8fa.png)

## Archive Information Below
<s>To create a new seed.iso file:
1) Create a www directory under your home:  mkdir /home/$USER/www
2) Create an empty meta-data file under www: touch /home/$USER/www/meta-data
3) Install 'cloud-image-utils': apt install cloud-image-utils -y
4) Run the following command:
rm -rf /home/$USER/www/seed.iso; cloud-localds /home/$USER/www/seed.iso /home/$USER/www/user-data /home/$USER/www/meta-data

Current user for testing is: ubuntu

Current password hash is: ubuntu</s>
