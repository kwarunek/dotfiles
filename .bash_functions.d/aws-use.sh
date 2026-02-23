#!/bin/sh

aws-use() {
    profile="$1"
    gray='\033[90m'
    reset='\033[0m'
    caller_identity=""

    if [ -z "$profile" ]; then
        echo "Usage: aws_use <profile_name>" >&2
        return 1
    fi

    if [ -n "$NO_COLOR" ] || [ ! -t 1 ]; then
        gray=''
        reset=''
    fi

    if ! which crudini >/dev/null 2>&1; then
        echo "Error: crudini not found. Please install it first." >&2
        return 1
    fi

    if caller_identity=$(aws --profile "$profile" sts get-caller-identity --output json 2>/dev/null); then
        export AWS_PROFILE="$profile"
        printf '%b\n' "${gray}${caller_identity}${reset}"
        return 0
    fi

    if crudini --get ~/.aws/credentials "$profile" >/dev/null 2>&1; then
        export AWS_PROFILE="$profile"
    else
        if crudini --get ~/.aws/config "profile $profile" >/dev/null 2>&1; then
            sso_session=""
            sso_session=$(crudini --get ~/.aws/config "profile $profile" sso_session 2>/dev/null)

            if [ -n "$sso_session" ]; then
                echo "SSO session found, logging in..." >&2
                aws sso login --sso-session "$sso_session"
            else
                echo "No SSO session, using saml2aws..." >&2
                saml2aws login -a "$profile"
            fi
            export AWS_PROFILE="$profile"
        else
            echo "Profile '$profile' not found in AWS config" >&2
            return 1
        fi
    fi

    caller_identity=$(aws --profile "$profile" sts get-caller-identity --output json)
    printf '%b\n' "${gray}${caller_identity}${reset}"
}

if [ -n "$BASH_VERSION" ]; then
    _aws-use_completion() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local profiles=""
        if [ -f "$HOME/.aws/credentials" ]; then
            profiles=$(crudini --get "$HOME/.aws/credentials")
        fi
        if [ -f "$HOME/.aws/config" ]; then
            profiles="${profiles} $(crudini --get "$HOME/.aws/config" | grep '^profile ' | awk '{print $2}')"
        fi
        profiles=$(echo "$profiles" | sort -u)
        mapfile -t COMPREPLY < <(compgen -W "$profiles" -- "$cur")
    }
    complete -F _aws-use_completion aws-use
fi
