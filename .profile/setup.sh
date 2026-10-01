#!/usr/bin/bash

echo RUNNING SETUP SCRIPT FOR /workspaces/$RepositoryName/

# add setup here!
python -m pip install -r /workspaces/$RepositoryName/.profile/requirements.txt
mv ~/.bashrc ~/.bashrc.backup ;  
ln -s /workspaces/$RepositoryName/.profile/bashrc ~/.bashrc ; 
touch /workspaces/$RepositoryName/.profile/bash_history; 
ln -s /workspaces/$RepositoryName/.profile/bash_history ~/.bash_history ; 
echo setup bash_history; 

mkdir -p ~/.local/bin
ln -s /workspaces/$RepositoryName/.profile/git_helper.sh ~/.local/bin/git_helper 
chmod u+x /workspaces/$RepositoryName/.profile/git_helper.sh

echo ENDED SETUP SCRIPT

