#####################
### git
#####################

function gc {
  git checkout "`git branch | cut -c 3- | fzf --preview="git log {} --"`"
}

function git-branch-delete {
  git branch |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --multi --preview="git log {} --" |
    xargs --no-run-if-empty git branch --delete --force
}

function git-add {
  git add $(git ls-files --modified --others --exclude-standard | fzf -m)
}

function git-checkout-upsert {
	git checkout $1 2>/dev/null || git checkout -b $1;
}

alias gcm="git checkout master"
alias gd="git-branch-delete "
alias gp="git pull && git-delete-squashed"
alias gpp="git push"
alias gfp="git push --force"
alias ga="git-add"
alias gf="git ls-files | grep"
alias gcu="git-checkout-upsert"
alias gs="git status"

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
alias serve='python -m SimpleHTTPServer'
alias server='serve'

###############################################################
# aliases for shell customization
###############################################################
alias castle='cd /Users/blackmad/.homesick/repos/dotfiles/home/'
alias ec="code $HOME/.zshrc"
alias reload="source $HOME/.zshrc"
# edit my main list of aliases
alias edit_aliases=code ~/.oh-my-zsh/custom/aliases.zsh

function homesick_commit {
  cd /Users/blackmad/.homesick/repos/dotfiles/home/
  git commit -a -m stuff && git push
}

###############################################################
# find file in current dir
###############################################################
alias spot="mdfind -onlyin `pwd`"

###############################################################
# command aliases
###############################################################
alias ls=exa
alias local-ip="ipconfig getifaddr en1"
alias chrome='open -a Google\ Chrome'
alias download="curl -O"
alias grep='grep --color=auto'

alias docker-nuke='docker system prune -f --all --volumes'

# download youtube video as mp3
alias youtube-mp3=youtube-dl -x --audio-format mp3 

# convert all HEIC in current dir to jpg
alias heic2jpg="magick mogrify -monitor -format jpg *heic *HEIC"
# convert all arguments to jpg
alias tojpg=magick mogrify -monitor -format jpg



# some good ideas here: https://github.com/stevenqzhang/dotfiles/blob/master/.bashrc
# ditoo https://github.com/isao/dotfiles/blob/master/zsh.d/fzf.zsh