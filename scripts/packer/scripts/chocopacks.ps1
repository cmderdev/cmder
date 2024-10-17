choco install -y boxstarter.winconfig

# Editors
choco install -y notepadplusplus

# Terminals
choco install -y microsoft-windows-terminal
choco install -y fluent-terminal
choco install -y hyper
choco install -y tabby
choco install -y conemu

# other
choco install -y poshgit

# IDE/Software development
choco install -y vscode
choco install -y visualstudio2022community --execution-timeout 9000 --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop;includeRecommended"

md C:\users\vagrant\bin
if (test-path "a:/set-shortcut.ps1") {
  copy "a:/set-shortcut.ps1" C:\users\vagrant\bin
} elseif (test-path "e:/set-shortcut.ps1") {
  copy "e:/set-shortcut.ps1" C:\users\vagrant\bin
}

