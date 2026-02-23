FUNCTIONS_TO_LOAD=(aws-use batdiff batman extract ssh-get-hash ssh-forward-key)

for func in "${FUNCTIONS_TO_LOAD[@]}"; do
  if [[ -f "${HOME}/.bash_functions.d/${func}.sh" ]]; then
    source "${HOME}/.bash_functions.d/${func}.sh"
  fi
done
