# Ubuntu_AutoInstaller
To create a new seed.iso file:
1) Create a www directory under your home:  mkdir /home/$USER/www
2) Create an empty meta-data file under www: touch /home/$USER/www/meta-data
3) Install 'cloud-image-utils': apt install cloud-image-utils -y
4) Run the following command:
rm -rf /home/$USER/www/seed.iso; cloud-localds /home/$USER/www/seed.iso /home/$USER/www/user-data /home/$USER/www/meta-data

Current user for testing is: ubuntu

Current password hash is: ubuntu
