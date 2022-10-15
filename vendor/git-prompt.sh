function getGitStatusSetting() {
  gitStatusSetting=$(git --no-pager config -l 2>/dev/null)

  if [[ -n ${gitStatusSetting} ]] && [[ ${gitStatusSetting} =~ cmder.status=false ]] || [[ ${gitStatusSetting} =~ cmder.shstatus=false ]]
  then
    echo false
  else
    echo true
  fi
}

function getSimpleGitBranch() {
  gitDir=$(git rev-parse --git-dir 2>/dev/null)
  if [ -z "$gitDir" ]; then
    return 0
  fi

  headContent=$(< "$gitDir/HEAD")
  if [[ "$headContent" == "ref: refs/heads/"* ]]
  then
    echo " (${headContent:16})"
  else
  echo " (HEAD detached at ${headContent:0:7})"
  fi
}

if test -f /etc/profile.d/git-sdk.sh
then
  TITLEPREFIX=SDK-${MSYSTEM#MINGW}
else
  TITLEPREFIX=$MSYSTEM
fi

if test -f ~/.config/git/git-prompt.sh
then
  if [[ $(getGitStatusSetting) == true ]]
  then
    . ~/.config/git/git-prompt.sh
  fi
else
  PS1='\[\033]0;$MSYSTEM:${PWD//[^[:ascii:]]/?}\007\]' # set window title
  # PS1="$PS1"'\n'                 # new line
  PS1="$PS1"'\[\033[32m\]'       # change to green
  PS1="$PS1"'\u@\h '             # user@host<space>
  # PS1="$PS1"'\[\033[35m\]'       # change to purple
  # PS1="$PS1"'$MSYSTEM '          # show MSYSTEM
  PS1="$PS1"'\[\033[33m\]'       # change to brownish yellow
  PS1="$PS1"'\w'                 # current working directory
  if test -z "$WINELOADERNOEXEC"
  then
    GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
    COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
    COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
    COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"
    if test -f "$COMPLETION_PATH/git-prompt.sh"
    then
      . "$COMPLETION_PATH/git-completion.bash"
      if [[ $(getGitStatusSetting) == true ]]
      then
        . "$COMPLETION_PATH/git-prompt.sh"
        PS1="$PS1"'\[\033[36m\]'  # change color to cyan
        PS1="$PS1"'`__git_ps1`'   # bash function
      else
        PS1="$PS1"'\[\033[37;1m\]'  # change color to white
        PS1="$PS1"'`getSimpleGitBranch`'
      fi
    fi
  fi
  PS1="$PS1"'\[\033[0m\]'        # change color
  PS1="$PS1"'\n'                 # new line
  PS1="$PS1"'λ '                 # prompt: always λ
fi

MSYS2_PS1="$PS1"               # for detection by MSYS2 SDK's bash.basrc