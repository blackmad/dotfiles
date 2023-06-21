defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool FALSE

mkdir ~/.tools
cd ~/.tools
git clone https://github.com/MartinRamm/fzf-docker

mv ~/.oh-my-zsh/custom /tmp
rm -rf ~/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mv /tmp/custom/* ~/.oh-my-zsh/

brew bundle --file=~/.Brewfile 

ansible-playbook ~/.first_time/ansible/sudo-touchid.yml
