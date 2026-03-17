ssh-get-hash() {
    case $1 in
          *.pub) ssh-keygen -lf $1 ;;
          *) for key in ~/.ssh/*.pub; do echo -n "Key: $key "; ssh-keygen -lf "$key"; echo; done ;;
    esac
}
