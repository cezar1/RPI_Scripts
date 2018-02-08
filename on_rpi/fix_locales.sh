#!/bin/bash
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
sudo dpkg-reconfigure locales
#For checking results
locale
echo 'export LANG="en_US.UTF-8"' >> ~/.bashrc
echo 'export LANGUAGE="en_US:en"' >> ~/.bashrc
echo 'export LC_ALL="en_US.UTF-8"' >> ~/.bashrc
echo 'export LC_CTYPE="en_US.UTF-8"' >> ~/.bashrc
