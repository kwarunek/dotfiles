#!/usr/bin/env bash
#
# Git status line for tmux
# Displays current branch and dirty state

DEFAULT_BRANCH_COLOR="green"
BRANCH_COLOR="cyan"
UNSTAGED_COLOR="red"
PREFIX="git:"

__get_current_branch() {
  git rev-parse --abbrev-ref HEAD 2> /dev/null | sed 's/^\* //'
}

__get_dirty_state() {
  git status --porcelain 2> /dev/null | wc -l | tr -d ' '
}

__get_default_branch() {
  git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
}

git_mux() {
  REPO_PATH=$1
  cd "${REPO_PATH}"
  BRANCH=$(__get_current_branch)

  if [[ -z "${BRANCH}" ]]; then
    echo ""
    exit
  fi

  DIRTY_STATE=""
  DIRTY=$(__get_dirty_state)
  DEFAULT_BRANCH=$(__get_default_branch)
  
  if [[ "${DIRTY}" -gt 0 ]]; then
    DIRTY_STATE="#[fg=${UNSTAGED_COLOR}](${DIRTY} unstaged)"
  fi
  if [[ "${BRANCH}" == "${DEFAULT_BRANCH}" ]]; then
    COLOR="#[fg=${DEFAULT_BRANCH_COLOR}]"
  else
    COLOR="#[fg=${BRANCH_COLOR}]"
  fi

  echo "${PREFIX}${COLOR}${BRANCH} ${DIRTY_STATE}"
}

git_mux "$@"
