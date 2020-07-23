@echo off

:: Below are the default Cmder session settings:
::
:: See "%CMDER_ROOT%\README.md" for details on these settings.
::
:: `Cmder.exe` Arguments:
:: ----------------------
:: 
:: `/c [cmder_user_cfg_root]
:: set cmder_user_bin=[cmder_user_cfg_root]\bin
:: set cmder_user_config=[cmder_user_cfg_root]\config
::
:: `init.bat` Arguments
:: --------------------
::
:: `/d`
:: debug_output=0
::
:: `/v`
:: verbose_output=0
::
:: `/f`
:: fast_init=0
::
:: `/nix_tools`
:: nix_tools=1
::
:: `/t`
:: time_init=0
::
:: `/max_depth`
:: max_depth=1
::
:: `/user_aliases`
:: user_aliases=
::
:: `/git_install_root`
:: GIT_INSTALL_ROOT=
::
:: `/home`
:: HOME=
::
:: `/svn_ssh`
:: SVN_SSH=

echo Applying Cmder VSCode settings from '%~0'...

if defined CMDER_CONFIGURED (
    :: Set Cmder settings here for when VSCode is launched inside Cmder.
    set verbose_output=1
) else (
    :: Set Cmder settings here for when VSCode is launched from outside Cmder.
    set verbose_output=1
)

:: Set all required Cmder VSCode terminal environment settings above this line.
echo Applying Cmder VSCode settings is complete!
