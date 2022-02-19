# Ubuntu_AutoInstaller
This script was designed in order to ease the installation process of Ubuntu server. It was designed to create an answer file that can be used to setup initial users, disks using Logical Volume Manager (LVM), and patches with minimal user interaction.

## Using CreateSeedISOwDocker.sh
<ul>
  <li>Download and Run CreateSeedISOwDocker.sh</li>   
    <ul><li>The script will prompt to download any missing packages that are required, and not already installed on your Linux system</li></ul>
  
  <li>The script when ran will auto generated a directory named /home/&#60;user&#62;/www, and an environment variable file /home/&#60;user&#62;/seed.env</li>
    <ul>
      <li>/home/&#60;user&#62;/www/ - is the directory that stores the data that is used to create the seed-&#60;servername&#62;.iso file</li>
      <li>/home/&#60;user&#62;/www/seed.env - is a file that contains default variables that can be modified for future seed-&#60;servername&#62;.iso file creations</li>
    </ul>
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
