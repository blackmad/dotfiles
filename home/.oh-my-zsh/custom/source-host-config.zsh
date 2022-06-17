# source un-checked-in config
FILENAME=~/.`hostname`.zsh

if test -f "$FILENAME"; then
    source $FILENAME
fi