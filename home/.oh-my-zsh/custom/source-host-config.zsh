HOSTNAME=`hostname`

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    HOSTNAME=`scutil --get ComputerName`
fi

# source un-checked-in config
FILENAME=~/.$HOSTNAME.zsh

if test -f "$FILENAME"; then
    source $FILENAME
fi