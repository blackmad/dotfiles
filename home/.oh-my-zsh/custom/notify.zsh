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
