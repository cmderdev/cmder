## Config

All config files must be in this folder. If there is no option to set this folder 
directly, it has to be hardlinked.

* `aliases`: aliases in cmd; called form vendor\init.bat; autocreated from
  `vendor\aliases.example`.
* `*.lua`: clink completions and prompt filters; called from vendor\cmder.lua after all
  other prompt filter and clink completions are initialized; add your own.
* `user_profile.{sh|bat|ps1}`: startup files for bash|cmd|powershell tasks; called from their
  respective startup scripts in `vendor\`; autocreated on first start of such a task
* `.history`: the current commandline history; autoupdated on close
* `settings`: settings for readline; overwritten on update
* `ConEmu.xml`: settings from ConEmu (=the UI of cmder -> Preferences); overwritten on update
