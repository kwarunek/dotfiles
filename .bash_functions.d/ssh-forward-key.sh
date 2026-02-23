ssh-forward-key() {
    KEY=$DEFAULT_SSH_KEY_TO_FORWARD
    if [ -n "$1" ]; then
        KEY=$1
    fi
    if [ ! -f "$KEY" ]; then
        echo "Key $KEY does not exist"
        return 1
    fi
    pkill -9 -f ssh-agent
    eval $(ssh-agent -s)
    ssh-add $KEY
}
