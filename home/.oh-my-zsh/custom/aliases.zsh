#####################
### git
#####################

function git_guess_main_branch_name {
  if git show-ref --quiet refs/heads/main; then
    echo -n main
  else
    echo -n master
  fi
}

function gc {
  if [[ $1 ]]; then
    git checkout $1
  else
    git checkout "$(git branch | cut -c 3- | fzf --preview="git log {} --")"
  fi
}

function git-branch-delete {
  git branch |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --multi --preview="git log {} --" |
    xargs git branch --delete --force
}

function git-add {
  git add $(git ls-files --modified --others --exclude-standard | fzf -m)
}

# Create a slug from a string
# https://gist.github.com/oneohthree/f528c7ae1e701ad990e6
function slugify {
  echo "$@" | iconv -t ascii//TRANSLIT | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+\|-+$//g' | tr '[:upper:]' '[:lower:]'
}

function git-checkout-upsert {
  BRANCH=$(slugify $@)
  git checkout $BRANCH 2>/dev/null || git checkout -b $BRANCH
}

function gcm {
  git checkout $(git_guess_main_branch_name)
}

function grm {
  git rebase $(git_guess_main_branch_name)
}

# git pull master + rebase onto master
function gprm {
  CURRENT_BRANCH=$(git branch --show-current)
  if [[ $(git diff --stat) != '' ]]; then
    WAS_DIRTY=0
  fi

  [ $WAS_DIRTY ] && echo was dirty, saving work in stash
  [ $WAS_DIRTY ] && git stash
  gcm
  git pull
  git checkout $CURRENT_BRANCH
  grm
  [ $WAS_DIRTY ] && git stash pop
}

function git-rebase-continue {
  git add -A
  git rebase --continue
}

function git-delete-squashed {
  TARGET_BRANCH=$(git_guess_main_branch_name)

  git checkout -q $TARGET_BRANCH && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base $TARGET_BRANCH $branch) && [[ $(git cherry $TARGET_BRANCH $(git commit-tree $(git rev-parse $branch\^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done
}

function _git-commit-and-message {
  git commit -a -m "$*"
}

alias gd="git-branch-delete"
alias gp="git pull && git-delete-squashed"
alias gpu="git push"
alias gpp="git push"
alias gfp="git push --force"
alias ga="git-add"
alias gf="git ls-files | grep"
alias gcu="git-checkout-upsert"
alias gca="git commit -a"
alias gcaa="git commit -a --amend --no-edit"
alias gs="git status"
alias gcam="git add -A && _git-commit-and-message"

alias _git-root="git rev-parse --show-toplevel"

function notify {
  EXIT_STATUS=$?

  set -x

  NOTIFICATION="${@-foo}"
  if [ -z $1 ]; then
    NOTIFICATION="Done!"
  fi

  if [[ $EXIT_STATUS == 0 ]]; then
    osascript -e "display notification \"$NOTIFICATION\" with title \"Success!\""
  else
    osascript -e "display notification \"FAIL: $NOTIFICATION\" with title \"ERROR $EXIT_STATUS!\""
  fi
}

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
alias edit_aliases="code ~/.oh-my-zsh/custom/aliases.zsh"

function homesick_commit {
  MESSAGE="$@"
  if [ -z $1 ]; then
    MESSAGE="stuff!"
  fi

  cd /Users/blackmad/.homesick/repos/dotfiles/home/
  git commit -a -m "$MESSAGE" && git push
}

###############################################################
# find file in current dir
###############################################################
alias spot="mdfind -onlyin $(pwd)"

###############################################################
# command aliases
###############################################################
alias ls=exa
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
alias youtube-mp3="youtube-dl -x --audio-format mp3"

# convert all HEIC in current dir to jpg
alias heic2jpg="magick mogrify -monitor -format jpg *heic *HEIC"
# convert all arguments to jpg
alias tojpg=magick mogrify -monitor -format jpg

alias googlebot='\curl --user-agent "Googlebot/2.1 (+http://www.google.com/bot.html)" -v'
alias twitterbot='\curl -A Twitterbot'
alias curl="figlet are you sure you don\'t want to use http\? && curl"

# some good ideas here: https://github.com/stevenqzhang/dotfiles/blob/master/.bashrc
# ditoo https://github.com/isao/dotfiles/blob/master/zsh.d/fzf.zsh

alias brew-dump="brew bundle dump  --global -f"
