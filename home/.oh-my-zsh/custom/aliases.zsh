###############################################################
# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
###############################################################
alias map="xargs -n1"

###############################################################
# print everything in $PATH, one per line
###############################################################
alias path='printf "%b\n" "${PATH//:/\\n}"'

###############################################################
# simple local http server
###############################################################
alias serve='python3 -m http.server 8000'
alias server='serve'

###############################################################
# aliases for shell customization
###############################################################
alias castle='cd /Users/blackmad/.homesick/repos/dotfiles/home/'
alias ec="code $HOME/.zshrc"
alias reload="source $HOME/.zshrc"

export CODE_EDITOR="code"
# edit my main list of aliases
alias edit-aliases="$CODE_EDITOR ~/.oh-my-zsh/custom/aliases.zsh"
alias edit-zsh="$CODE_EDITOR ~/.oh-my-zsh/custom/"
alias edit-karabiner="$CODE_EDITOR ~/.config/karabiner/karabiner.json"
alias zshconfig="$CODE_EDITOR  ~/.zshrc"
alias ohmyzsh="$CODE_EDITOR  ~/.oh-my-zsh"
alias karabiner-edit=edit-karabiner

alias millis='function _millis(){ date -r $(( $1/1000 )) "+%c"; };_millis'

function jq-key {
  jq -r '..|.'$1'?| select( . != null )'
}

function homesick_commit {
  cd /Users/blackmad/.homesick/repos/dotfiles/home/

  MESSAGE="$@"
  if [ -z $MESSAGE ]; then
    git commit -a && git push

  else
    git commit -a -m $MESSAGE && git push
  fi
}

###############################################################
# find file in current dir
###############################################################
alias spot="mdfind -onlyin $(pwd)"

###############################################################
# command aliases
###############################################################
alias ls=eza
alias local-ip="ipconfig getifaddr en1"
alias chrome='open -a Google\ Chrome'
alias download="curl -O"
alias grep='grep --color=auto'

###############################################################
# DOCKER
###############################################################
# https://www.calazan.com/docker-cleanup-commands/

# Kill all running containers.
alias docker-killall='docker kill $(docker ps -q)'

# Delete all stopped containers.
alias docker-cleanc='printf "\n>>> Deleting stopped containers\n\n" && docker rm $(docker ps -a -q)'

# Delete all untagged images.
alias docker-cleani='printf "\n>>> Deleting untagged images\n\n" && docker rmi $(docker images -q -f dangling=true)'

# Delete all stopped containers and untagged images.
alias docker-clean='docker-cleanc || true && docker-cleani'

alias docker-nuke='docker system prune -f --all --volumes'

# download youtube video as mp3
alias youtube-mp3="yt-dlp -x --audio-format mp3"

# convert all HEIC in current dir to jpg
alias heic2jpg="magick mogrify -monitor -format jpg *heic *HEIC"
# convert all arguments to jpg
alias tojpg=magick mogrify -monitor -format jpg

alias googlebot='\curl --user-agent "Googlebot/2.1 (+http://www.google.com/bot.html)" -v'
alias twitterbot='\curl -A Twitterbot'
#alias curl="figlet are you sure you don\'t want to use http\? && curl"

# some good ideas here: https://github.com/stevenqzhang/dotfiles/blob/master/.bashrc
# ditoo https://github.com/isao/dotfiles/blob/master/zsh.d/fzf.zsh

alias brew-dump="brew bundle dump  --global -f"

alias ios-simulator="open -a Simulator"

alias python="python3"
alias pip="pip3"

alias via="open ~/Code/breasts/training/via.html"

alias find-empty-directories="find . -type d -empty"

alias mdfind-cwd="mdfind -onlyin ."

alias xargs-map="xargs -t -n1"
alias xargs-newline="tr '\n' '\0' | xargs -n1 -t -0"ech
