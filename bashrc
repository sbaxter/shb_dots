#!/usr/bin/env bash
# shellcheck disable=SC1091

# If not running interactively, don't do anything
test -z "$PS1" && return

# Source global definitions
test -f /etc/bashrc  && source /etc/bashrc
test -f "$HOME/.bash_private" && source "$HOME/.bash_private"

# COLORS
# -----------------------------------------------------------------------------
    NO_COLOR=$(tput sgr0)
        BOLD=$(tput bold)
       BLACK=$(tput setaf 0)
         RED=$(tput setaf 1)
       GREEN=$(tput setaf 2)
      YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
     MAGENTA=$(tput setaf 5)
        CYAN=$(tput setaf 6)
       WHITE=$(tput setaf 7)
       B_RED=$BOLD$RED
      B_BLUE=$BOLD$BLUE
   B_MAGENTA=$BOLD$MAGENTA
      B_CYAN=$BOLD$CYAN
     B_WHITE=$BOLD$WHITE
     B_GREEN=$BOLD$GREEN
    B_YELLOW=$BOLD$YELLOW
     B_BLACK=$BOLD$BLACK
    ON_BLACK=$(tput setab 0)
      ON_RED=$(tput setab 1)
    ON_GREEN=$(tput setab 2)
   ON_YELLOW=$(tput setab 3)
     ON_BLUE=$(tput setab 4)
  ON_MAGENTA=$(tput setab 5)
     ON_CYAN=$(tput setab 6)
    ON_WHITE=$(tput setab 7)

export NO_COLOR BOLD BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE
export B_RED B_BLUE B_MAGENTA B_CYAN B_WHITE B_GREEN B_YELLOW B_BLACK
export ON_BLACK ON_RED ON_GREEN ON_YELLOW ON_BLUE ON_MAGENTA ON_CYAN ON_WHITE

# Directory Colors
export LS_COLORS='di=0;32'
# -----------------------------------------------------------------------------


# DEFAULTS (stick them in .bash_profile)
# -----------------------------------------------------------------------------
: "${PROMPT_COLOR:=$YELLOW}"
: "${ORG:=}"
: "${REPO:=$HOME/repos}"
: "${WWW_HOME:=https://google.com}"
: "${USER_TAG:="($USER)"}"
# -----------------------------------------------------------------------------


# TERMINAL
# -----------------------------------------------------------------------------
# vi mode for editing the command line.
set -o vi

# vi as the default editor.
export VISUAL=vim
export EDITOR=$VISUAL
export GIT_EDITOR=$VISUAL

# Add bin files to $PATH
_bashrc="${BASH_SOURCE[0]}"
test -h "$_bashrc" && link=$(dirname "$(readlink "$_bashrc")")/bin
test -n "$link" && export PATH=$PATH:$link
test -h "$_bashrc" && viconf=$(dirname "$(readlink "$_bashrc")")/vi
test -z "$viconf" || export VI_CONFIG="$viconf"

export PATH=$PATH:/usr/local/bin:/usr/local/sbin

# cmd history
export HISTCONTROL=erasedups:ignoreboth
export HISTFILESIZE=500000
export HISTSIZE=100000
export HISTIGNORE="&:[ ]*:exit"
shopt -s histappend
shopt -s cmdhist

function reload {
  source "$HOME/.bashrc"
}

function title {
  echo -ne "\033]2;$1\007"
}

function setclock {
  rdate -s time.nist.gov
}
# -----------------------------------------------------------------------------


# PROMPT
# -----------------------------------------------------------------------------
function _gbranch {
  local sym
  sym=$(git symbolic-ref HEAD 2>/dev/null)
  test -z "$sym" && sym=$(git describe --contains --all HEAD)
  test -z "$sym" && sym=$(git rev-parse --short HEAD)
  echo "${sym##refs/heads/}"
}

function _gprompt {
  local branch w i u
  git status >/dev/null 2>&1 || return;

  if git log >/dev/null 2>&1; then
    branch=$(_gbranch)
    i=$(git diff-index --cached --quiet HEAD -- 2>/dev/null || echo "+")
  else
    branch='(init)'
    i=$(git diff --cached --quiet --exit-code || echo "+")
  fi

  w=$(git diff --no-ext-diff --quiet --exit-code || echo "!")
  u="$(test -z "$(git ls-files --others --exclude-standard -- ':/*' \
        2>/dev/null)" || echo "?")"

  echo "[$branch\[$CYAN\]$w$i$u\[$PROMPT_COLOR\]]"
}

function _prompt {
  local depth b e
  depth=$(pwd | sed 's/[^/]//g' | sed 's/^\///')
  b="$NO_COLOR$PROMPT_COLOR\n"
  e="$ON_BLACK$NO_COLOR"
  PS1="\[${b}\]$(_gprompt)\[$PROMPT_COLOR\][$HOSTNAME$USER_TAG:$depth\W]:\[$e\] "
  PS2="   \[$PROMPT_COLOR\]->\[$NO_COLOR\] "
}
PROMPT_COMMAND="_prompt"
# -----------------------------------------------------------------------------


# ALIASES
# -----------------------------------------------------------------------------
function _alias {
  alias "$1" >/dev/null 2>&1
  return
}

_alias ..     || alias ..='cd ..'
_alias ..2    || alias ..2='cd ../..'
_alias ..3    || alias ..3='cd ../../..'
_alias ..4    || alias ..4='cd ../../../..'
_alias ..5    || alias ..5='cd ../../../../..'
_alias assume || alias assume='source source-aws-assume-role'
_alias cp     || alias cp='cp -i'
_alias grep   || alias grep='grep --color=auto'
_alias ngrep  || alias ngrep='grep --color=auto --exclude-dir node_modules'
_alias ll     || alias ll='ls -hl'
_alias lla    || alias lla='ls -ahl'
_alias mfa    || alias mfa='source source-aws-mfa'
_alias mv     || alias mv='mv -i'
_alias rm     || alias rm='rm -i'
_alias vi     || alias vi=vim
_alias back   || alias back='cd -'
_alias blint  || alias blint='shellcheck -s bash'

# aws regions
for region in \
  eu-north-1 \
  ap-south-1 \
  eu-west-3 \
  eu-west-2 \
  eu-west-1 \
  ap-northeast-3 \
  ap-northeast-2 \
  ap-northeast-1 \
  sa-east-1 \
  ca-central-1 \
  ap-southeast-1 \
  ap-southeast-2 \
  eu-central-1 \
  us-east-1 \
  us-east-2 \
  us-west-1 \
  us-west-2; do
    # shellcheck disable=SC2139
    _alias $region || alias $region="export AWS_DEFAULT_REGION=$region AWS_REGION=$region"
done
# -----------------------------------------------------------------------------


# GIT
# -----------------------------------------------------------------------------

# git completion
test -f "$HOME/.git-completion.bash" && source "$HOME/.git-completion.bash"

# aliases
_hist="git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short"
# shellcheck disable=SC2139
_alias hist  || alias hist="$_hist"
_alias ga    || alias ga='git add'
_alias gc    || alias gc='git commit'
_alias gca   || alias gca='git commit --amend'
_alias gco   || alias gco='git checkout'
_alias gd    || alias gd='git diff'
_alias gpick || alias gpick='git cherry-pick -x'
_alias gpr   || alias gpr='git merge --no-ff'
_alias gpt   || alias gpt='git push --tags'
_alias gr    || alias gr='git pull --rebase'
_alias grm   || alias grm='git rm'
_alias groot || alias groot='cd $(git rev-parse --show-cdup) '
_alias gst   || alias gst='git status'
_alias gt    || alias gt='git tag -sam'

function grb {
  git for-each-ref --sort=-committerdate refs/remotes/ \
                   --format='%(refname:short)' \
                    --count=20
}

function gp {
  local branch
  git status >/dev/null 2>&1 || return;

  remote=origin
  test -z "$1" || remote="$1"

  branch=$(git symbolic-ref HEAD 2>/dev/null)
  test -z "$branch" && echo "Detached state?" && return 1
  echo "pushing to $remote/$branch"
  git push "$remote" "$branch"
}

function gu {
  local branch
  git status >/dev/null 2>&1 || return;

  branch=$(git symbolic-ref HEAD 2>/dev/null)
  test -z "$branch" && echo "Detached state?" && return 1
  echo "pulling from origin/$branch"
  git pull origin "$branch"
}

function gshow {
  git log --pretty=format:"%h" --grep "$1" | xargs git show
}
# -----------------------------------------------------------------------------


# AWS ENV + PROMPT TAG
# -----------------------------------------------------------------------------
function set-aws-env {
  local highlight id prefix secret
  test -n "$1" && highlight="$1" || highlight=CYAN
  prefix="$(echo "$ORG" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
  id="${prefix}_AWS_ACCESS_KEY_ID"
  secret="${prefix}_AWS_SECRET_ACCESS_KEY"
  export AWS_ACCESS_KEY_ID="${!id}"
  export AWS_SECRET_ACCESS_KEY="${!secret}"
  export AWS_ACCESS_KEY="${!id}"
  export AWS_SECRET_KEY="${!secret}"
  export AWS_DEFAULT_REGION=us-east-1
  export AWS_REGION=$AWS_DEFAULT_REGION
  export USER_TAG="(\[${!highlight}\]${ORG}\[${NO_COLOR}${PROMPT_COLOR}\])"
}
# -----------------------------------------------------------------------------


# REPOS
# -----------------------------------------------------------------------------
function repo {
  if test -z "$ORG"; then
    cd "$REPO/$1" || return
  else
    cd "$REPO/$ORG/$1" || return
  fi
}

# auto-complete for repo
function _repo_dir {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  if test "$COMP_CWORD" -eq 1; then
      # shellcheck disable=SC2207
      COMPREPLY=( $( compgen -W "$(cd "$REPO/$ORG" \
        && find . -mindepth 1 -maxdepth 1 -type d \
              -exec basename {} \;)" -- "$cur" ) )
  elif test "$COMP_CWORD" -eq 2; then
      # shellcheck disable=SC2207
      COMPREPLY=( $( compgen -W "$(cd "$REPO/$ORG/$prev" \
        && find . -mindepth 1 -maxdepth 1 -type d \
              -exec basename {} \;)" -- "$cur" ) )
  fi
  return 0
}
complete -F _repo_dir repo

# shellcheck disable=SC2139
_alias wip || alias wip="cd $REPO/wip"

function towip {
  mv "$1" "$REPO/wip/."
}

function gclone {
  test -z "$1" && echo "give me a repo to clone" && return
  cd "$REPO" || return
  git clone "git@github.com:$1"
  cd "$(echo "$1" | sed 's/^.*\///')" || return
}

function coco {
  if test "$1" = "clone"; then
    test -n "$2" || { echo "coco clone: needs a repo to clone" >&2; return 1; }

    local path="$2"
    test -z "$ORG"  || path="${ORG}/${path}"
    test -z "$REPO" || path="${REPO}/${path}"

    git clone \
      "ssh://git-codecommit.$AWS_DEFAULT_REGION.amazonaws.com/v1/repos/$2" \
        "$path" \
      && cd "$path" || return
  else
    local term
    test -n "$2" && term="$2" || term="$1"
    local q="repositories[?contains(repositoryName,\`$term\`)][repositoryName]"
    aws codecommit list-repositories --output text --query "$q"
  fi
}
# -----------------------------------------------------------------------------


# EMACS
# -----------------------------------------------------------------------------
function e {
  { test -z "$1" || test -d "$1"; } && echo "slow down!" && return 1

  ! test -f "$1" && echo -n "create? (y/N) " && read -r c

  test -n "$c" && test "$c" = "y" && touch "$1"

  test -f "$1" && emacs "$1" || return 1
}
# -----------------------------------------------------------------------------


# GPG
# -----------------------------------------------------------------------------
function encryptfilefor {
  gpg -a --encrypt --recipient "$1" < "$2" > "$2.gpg"
}

function sign {
  gpg -a --detach-sign "$1"
}
# -----------------------------------------------------------------------------


# PROCESS/PKG MGMT
# -----------------------------------------------------------------------------
if test "$(uname -s)" != Darwin; then
  function start {
    "/etc/init.d/${1}" start
  }

  function restart {
    "/etc/init.d/${1}" restart
  }

  function stop {
    "/etc/init.d/${1}" stop
  }

  function isinstalled {
    rpm -qa | grep -i "$1"
  }
fi

function isrunning {
  #shellcheck disable=SC2009
  ps -ef | grep -i "$1" | grep -v grep
}

function wpid {
  #shellcheck disable=SC2009
  ps -ef | grep -i "$1" | grep -v grep | awk '{print $2}'
}

# -----------------------------------------------------------------------------


# SED
# -----------------------------------------------------------------------------
function dedup {
  sed -i '$!N; /^\(.*\)\n\1$/!P; D' "$1"
}

function upcase {
  sed -i 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' "$1"
}

function downcase {
  sed -i 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' "$1"
}

function unDOS {
  sed -i 's/.$//' "$1"
}

function noextraspaces {
  sed -i 's/^[ \t]*//;s/[ \t]*$//' "$1"
}

function notrailinglines {
  sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$1"
}

function noHTML {
  sed -i -e :a -e 's/<[^>]*>//g;/</N;//ba' "$1"
}

function trailingspaces {
  sed -i '' -e's/[ \t]*$//' "$1"
}

function doublespace {
  sed -i 'G' "$1"
}

function safedoublespace {
  sed -i '/^$/d;G' "$1"
}

function singlespace {
  sed -i 'n;d' "$1"
}

function blanklinebefore {
  sed -i "/$1/{x;p;x;}" "$2"
}

function blanklineafter {
  sed -i "/$1/G" "$2"
}

function reverseline {
  sed -i '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' "$1"
}

function appendlines {
  sed -e :a -e -i '/\\$/N; s/\\\n//; ta' "$1"
}
# -----------------------------------------------------------------------------


# PORTS
# -----------------------------------------------------------------------------
if test "$(uname -s)" != Darwin; then
  function specificcloseport {
    iptables --delete INPUT \
             --protocol tcp \
             --match state \
             --state NEW \
             --match tcp \
             --dport "$1" \
             --source "$2" \
             --jump ACCEPT
  }

  function specificopenport {
    iptables --insert INPUT \
             --protocol tcp \
             --match state --state NEW \
             --match tcp \
             --dport "$1" \
             --source "$2" \
             --jump ACCEPT
  }

  function openport {
    iptables --insert INPUT \
             --protocol tcp \
             --match state \
             --state NEW \
             --match tcp \
             --dport "$1" \
             --jump ACCEPT
  }

  function closeport {
    iptables --delete INPUT \
             --protocol tcp \
             --match state \
             --state NEW \
             --match tcp \
             --dport "$1" \
             --jump ACCEPT
  }
fi

function listenports {
  lsof | grep LISTEN
}
# -----------------------------------------------------------------------------


# NET
# -----------------------------------------------------------------------------
function internalip {
 ifconfig \
    | grep -B1 "inet addr" \
    | awk '{ if ( $1 == "inet" ) {
             print $2
           } else if ( $2 == "Link" ) {
             printf "%s:" ,$1 }
           }' \
    | awk -F: '{ print $1 ": " $3 }';
}

function externalip {
  curl checkip.amazonaws.com
}
# -----------------------------------------------------------------------------


# DIRECTORY AND FILE
# -----------------------------------------------------------------------------
function lookat {
  vim -R "$1"
}

function follow {
  cat "$1" && tail -f -n0 "$1"
}

function findtextinfiles {
  find . -name "$1" -exec "grep" -n "$2" {} \;
}

function linecount {
  grep -c $ "$1"
}

function ldir {
  #shellcheck disable=SC2010
  ls -l | grep ^d
}

function unspacefilenames {
  if test -z "$1"; then
    for f in *; do mv "$f" "$(echo "$f" | tr ' ' '_')"; done
  else
    mv "$1" "$(echo "$1" | tr ' ' '_')"
  fi
}

function clonedirsfrom {
  (cd "$1" || return; find ./ -type d ! -name .) | xargs mkdir
}

function copythisdirto {
  cp -r -p -P -u ./* "$1"
}

function howbigis {
  test -z "$1" && echo "no file specified" && return;
  ! test -f "$1" && echo "$1 not found" && return;

  du -sh "$1" | awk '{print $1}'
}

if test "$(uname -s)" = Darwin; then
  function pb {
    pbcopy < "$1"
  }
  function pbclear {
    pbcopy < /dev/null
  }
  _alias pc || alias pc="tr -d '\n' | pbcopy"
fi

function l80 {
  local pattern=.
  local recursive=--recursive
  if test -n "$1"; then
    pattern="$1"
    recursive=
  fi
  grep --exclude-dir .git --line-number $recursive '.\{80\}' "$pattern"
}
# -----------------------------------------------------------------------------


# FILE PERMISSIONS
# -----------------------------------------------------------------------------
function my {
  chown "$(whoami)":"$(whoami)" "$1"
}

function owner {
  chown -R "$1" ./*
  chgrp -R "$1" ./*
}
# -----------------------------------------------------------------------------


# FILE COMPRESSION
# -----------------------------------------------------------------------------
if hash gnutar 2>/dev/null; then
  _alias tar || alias tar=gnutar
fi

function addtotar {
  tar -rf "$1" "$2"
}
# -----------------------------------------------------------------------------


# SYM LINK
# -----------------------------------------------------------------------------
function reassign {
  ! test -L "$1" && { echo "$1 is not a symbolic link."; return 1; }
  ! test -e "$2" && { touch "$2"; echo "created empty file named $2"; }
  ! test -e "$2" && { echo "unable to create $2"; return 1; }

  rm -f "$1"
  ln -s "$2" "$1"
  ls -l "$1"
}
# -----------------------------------------------------------------------------


# URL ENCODE/DECODE
# -----------------------------------------------------------------------------
function urlencode {
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "%c" "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

function urldecode {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}
# -----------------------------------------------------------------------------


# LYNX
# -----------------------------------------------------------------------------
if type lynx >/dev/null 2>&1; then
  _alias lynx || alias lynx='lynx -accept_all_cookies -vikeys'
fi

function google {
  local args query search
  args="$*"
  test -z "$args" || query=$(urlencode "${args}")
  test -z "$query" || search="search?q=${query}&oq=${query}"

  lynx "https://www.google.com/${search}"
}

function wiki {
  local args query s wiki
  args="$*"
  type gsed >/dev/null && s="gsed" || s="sed"
  test -z "$args" || args=$(echo "$args" | $s -e 's/\b\(.\)/\u\1/g' | tr ' ' _)
  test -z "$args" || query=$(urlencode "${args}")
  test -z "$query" || wiki="wiki/${query}"
  lynx "https://en.wikipedia.org/${wiki}"
}
# -----------------------------------------------------------------------------


# JAVA
# -----------------------------------------------------------------------------
! test -f /usr/libexec/java_home || JAVA_HOME=$(/usr/libexec/java_home)
export JAVA_HOME
# -----------------------------------------------------------------------------


# PYTHON
# -----------------------------------------------------------------------------
function venv {
  test -n "$1" && version=$1 || version=3.10
  test -f venv/bin/activate || virtualenv -p "python${version}" venv
  source venv/bin/activate
  pip3 install --upgrade pip setuptools pylint
  ! test -f setup.py || pip3 install -e .[dev]
  ! test -f requirements.txt || pip3 -r requirements.txt
}
# -----------------------------------------------------------------------------


# GETOPT
# -----------------------------------------------------------------------------
! test -f /usr/bin/getopt || export GNU_GETOPT=/usr/bin/getopt
# -----------------------------------------------------------------------------


# HOMEBREW
# -----------------------------------------------------------------------------
if test "$(uname -s)" = Darwin; then
  # Set PATH, MANPATH, etc., for Homebrew.
  brew=/opt/homebrew/bin/brew
  test -x $brew || brew=/usr/local/bin/brew
  eval "$($brew shellenv)"

  alias brup="brew upgrade && brew cleanup"
fi
# -----------------------------------------------------------------------------


# COMPLETE
# -----------------------------------------------------------------------------
! type aws_completer >/dev/null 2>&1 || complete -C aws_completer aws
# -----------------------------------------------------------------------------
