##############
### git
###############

function gc {
 git checkout "$(git branch | fzf| tr -d '[:space:]')"
}

function git-branch-delete {
 git branch -D "$(git branch | fzf| tr -d '[:space:]')"
}

alias gcm="git checkout master"
alias gp="git pull && git-delete-squashed"


alias ls=exa
alias chrome='open -a Google\ Chrome'

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

alias local-ip="ipconfig getifaddr en1"

# print everything in $PATH, one per line
alias path='printf "%b\n" "${PATH//:/\\n}"'

alias serve='python -m SimpleHTTPServer'
alias server='serve'
alias castle='cd /Users/blackmad/.homesick/repos/dotfiles/home/'
