Stop-Service -Name 'wuauserv'

Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'EnableFeaturedSoftware' -Value 1 -Type DWord
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'IncludeRecommendedUpdates' -Value 1 -Type DWord

"Set ServiceManager = CreateObject(""Microsoft.Update.ServiceManager"")" | Out-File -FilePath 'C:\temp.vbs'
"Set NewUpdateService = ServiceManager.AddService2(""7971f918-a847-4430-9279-4a52d1efe18d"",7,"""")" | Out-File -FilePath 'C:\temp.vbs' -Append

cscript C:\temp.vbs
Remove-Item -Path 'C:\temp.vbs' -Force

Start-Service -Name 'wuauserv'
