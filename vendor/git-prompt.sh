# Returns 1 if git status for Cmder is disabled, otherwise returns 0
function getGitStatusSetting() {
  local gitConfig

  # Get all git config entries for the current repository without pager
  gitConfig=$(git --no-pager config -l 2>/dev/null) || return 0  # treat failure as enabled

  # Check if git status for Cmder is disabled
  if [[ $gitConfig =~ (^|$'\n')cmder\.status=false($|$'\n') ]] || \
     [[ $gitConfig =~ (^|$'\n')cmder\.shstatus=false($|$'\n') ]]
  then
    return 1  # disabled
  fi

  return 0
}

# Prints current branch or detached HEAD short commit hash
function getSimpleGitBranch() {
  local gitDir
  gitDir=$(git rev-parse --git-dir 2>/dev/null) || return 0

  local headFile="$gitDir/HEAD"
  [ -f "$headFile" ] || return 0

  local headContent
  headContent=$(< "$headFile")
  if [[ "$headContent" =~ ^ref:\ refs/heads/(.+)$ ]]
  then
    echo " (${BASH_REMATCH[1]})"
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
  if getGitStatusSetting
  then
    . ~/.config/git/git-prompt.sh
  fi
else
  # Taken parts from https://github.com/git-for-windows/build-extra/blob/main/git-extra/git-prompt.sh
  PS1='\[\033]0;${TITLEPREFIX:+$TITLEPREFIX:}${PWD//[^[:ascii:]]/?}\007\]' # set window title to TITLEPREFIX (if set) and current working directory
  # PS1="$PS1"'\n'               # new line (disabled)
  PS1="$PS1"'\[\033[32m\]'       # change to green and bold
  PS1="$PS1"'\u@\h '             # user@host<space>
  PS1="$PS1${MSYSTEM:+\[\033[35m\]$MSYSTEM }" # show MSYSTEM in purple (if set)
  PS1="$PS1"'\[\033[1;33m\]'     # change to dark yellow in bold
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
      if getGitStatusSetting
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
  PS1="$PS1"'\[\033[0m\]'        # reset color
  PS1="$PS1"'\n'                 # new line
  PS1="$PS1"'\[\033[30;1m\]'     # change color to grey in bold
  PS1="$PS1"'λ '                 # prompt: Cmder uses λ
  PS1="$PS1"'\[\033[0m\]'        # reset color
fi

MSYS2_PS1="$PS1"               # for detection by MSYS2 SDK's bash.basrc

# Evaluate all user-specific Bash completion scripts (if any)
if test -z "$WINELOADERNOEXEC"
then
  for c in "$HOME"/bash_completion.d/*.bash
  do
    # Handle absence of any scripts (or the folder) gracefully
    test ! -f "$c" ||
    . "$c"
  done
fi
