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

# Replaced by git-fuzzy-co.py
# function gc {
#   if [[ $1 ]]; then
#     git checkout $1
#   else
#     git checkout "$($(whence -p git) branch | cut -c 3- | fzf --preview="git log {} --")"
#   fi
# }

function git-branch-delete {
  $(whence -p git) branch |
    grep --invert-match '\*' |
    cut -c 3- |
    fzf --multi --preview="$(whence -p git) log {} --" |
    xargs $(whence -p git) branch --delete --force
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

function git-current-branch {
  git branch --show-current
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
  GIT_EDITOR=true git rebase --continue
}

function git-delete-squashed {
  TARGET_BRANCH=$(git_guess_main_branch_name)

  git checkout -q $TARGET_BRANCH && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base $TARGET_BRANCH $branch) && [[ $(git cherry $TARGET_BRANCH $(git commit-tree $(git rev-parse $branch\^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done
}

function _git-commit-and-message {
  git commit -a -m "$*"
}

alias gd="git-branch-delete"
alias gp="git pull origin --rebase && sleep 1 && git-delete-squashed"
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
alias gch="git checkout HEAD"
#alias gchm="git checkout $(git_guess_main_branch_name)"
alias gc="git-fuzzy-co.py"

alias _git-root="git rev-parse --show-toplevel"
