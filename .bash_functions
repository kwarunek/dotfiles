extract () {
  if [ -f $1 ] ; then
    case $1 in
          *.tar.bz2) tar xvjf $1 ;;
          *.tar.gz) tar xvzf $1 ;;
          *.tar.xz) tar xvJf $1 ;;
          *.bz2) bunzip2 $1 ;;
          *.xz) xz -d $1 ;;
          *.rar) rar x $1 ;;
          *.gz) gunzip $1 ;;
          *.tar) tar xvf $1 ;;
          *.tbz2) tar xvjf $1 ;;
          *.tgz) tar xvzf $1 ;;
          *.txz) tar xvJf $1 ;;
          *.zip) unzip $1 ;;
          *.Z) uncompress $1 ;;
          *.7z) 7z x $1 ;;
          *) echo "don't know how to extract '$1'..." ;;
    esac
  else
    echo "'$1' is not a valid file!"
  fi
}

parseyaml () {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

batdiff() {
    git diff --name-only --relative --diff-filter=d | xargs bat --diff
}

batman() {
    MANPAGER="sh -c 'col -bx | bat -l man -p'"  man $@
}

ssh-get-hash(){
    case $1 in
          *.pub) ssh-keygen -lf $1 ;;
          *) for key in ~/.ssh/*.pub; do echo -n "Key: $key "; ssh-keygen -lf "$key"; echo; done ;;
    esac
}

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
