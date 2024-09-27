try {
   ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {
   if ($_ -match "Method invocation is supported only on core types") {
      Write-Host "Du måste köra skriptet som administratör i Powershell 7."
      Start-Sleep -Seconds 5
      exit
   }
}

if ($PSVersionTable.PSEdition -ne "Core") {
   Write-Host "Detta kräver Powershell 7 för att powershell 5 suger dase"
   Start-Sleep -Seconds 5
   exit
}

New-Item -ItemType Directory -Name "$env:LOCALAPPDATA\OP5HostManager"
Set-Location "$env:LOCALAPPDATA\OP5HostManager"
git init --initial-branch=main
git remote add OHM https://gitlab.ltkalmar.se/oc/op5hostmanager
git pull OHM main
git add *
git commit -m "Första commiten"
git push --set-upstream OHM main
git config --global --add safe.directory C:/Users/$env:USERNAME/AppData/Local/OP5HostManager
if (!(Test-Path -Path "$env:ProgramFiles\PowerShell\7\Microsoft.PowerShell_profile.ps1")) {
   New-Item -ItemType File -Path "$env:ProgramFiles\PowerShell\7\Microsoft.PowerShell_profile.ps1" -Force
}

$usr = $env:USERNAME
Add-Content -Path "$env:ProgramFiles\PowerShell\7\Microsoft.PowerShell_profile.ps1" -Value "Import-Module `"C:\Users\$usr\AppData\Local\OP5HostManager\OP5HostManager.psm1`""


$sid = (Get-ADUser $usr).SID.Value

$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
   <RegistrationInfo>
      <Date>2023-04-26T15:22:31.5980977</Date>
      <Author>LKL\lklf2hz</Author>
      <Description>Gör en Git pull i mappen C:\Users\%USERNAME%\AppData\Local\OP5HostManager för att uppdatera OP5HostManager.</Description>
      <URI>\Git pull (OHM)</URI>
   </RegistrationInfo>
   <Triggers>
      <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>SessionLock</StateChange>
      <UserId>LKL\$usr</UserId>
      </SessionStateChangeTrigger>
   </Triggers>
   <Principals>
      <Principal id="Author">
      <UserId>$sid</UserId>
      <RunLevel>LeastPrivilege</RunLevel>
      </Principal>
   </Principals>
   <Settings>
      <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
      <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
      <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
      <AllowHardTerminate>false</AllowHardTerminate>
      <StartWhenAvailable>true</StartWhenAvailable>
      <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
      <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
      </IdleSettings>
      <AllowStartOnDemand>true</AllowStartOnDemand>
      <Enabled>true</Enabled>
      <Hidden>true</Hidden>
      <RunOnlyIfIdle>false</RunOnlyIfIdle>
      <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
      <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
      <WakeToRun>false</WakeToRun>
      <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
      <Priority>7</Priority>
   </Settings>
   <Actions Context="Author">
      <Exec>
      <Command>"C:\Program Files\PowerShell\7\pwsh.exe"</Command>
      <Arguments>-WindowStyle Hidden -File C:\Users\$usr\AppData\Local\OP5HostManager\Perform-Pull.ps1</Arguments>
      </Exec>
   </Actions>
</Task>
"@
Register-ScheduledTask -Xml $xml -TaskName "Git pull (OHM)"
Start-Process -FilePath "$env:LocalAppData\OP5HostManager"
