## OP5HostManager (OHM) version 1.2.7



## Funktion för att få fram valalternativ
function Edit-OP5 {
   <#
     .Synopsis
     Visar en lista där du kan välja mellan de olika funktioner som finns i OP5HostManager.

     .Description
     Visar en lista där du kan välja mellan de olika funktioner som finns i OP5HostManager. Syftet med Edit-OP5 är att förenkla användningen av OHM, och minska behovet av att skriva in ett stort antal parametrar. Istället ställer Edit-OP5 de nödvändiga frågorna.

     Cmdleten har parametern: $OP5Environment

     Anger man ingen miljö används den senast använda miljön. Finns det ingen senast använda väljs Prod som standard.

     Cmdleten är bara kompatibel med Powershell 7 och uppåt.

     .Example
     Edit-OP5 -OP5Environment Prod
   #>

   [CmdletBinding()]
   param (
      [Parameter(Mandatory=$False, HelpMessage="OP5 Test eller Prod")]
        [validateSet("Prod","Test")]
        [string]$OP5Environment
   )

   ## Om man inte angett en miljö, kolla i .ohmenv-filen, finns den inte så ta prod, har man angett en miljö så skriv den till .ohmenv
   if (!$OP5Environment) {
      if (Test-Path "C:\Users\$env:USERNAME\AppData\Local\.ohmenv") {
         $OP5Environment = Get-Content "C:\Users\$env:USERNAME\AppData\Local\.ohmenv"
      } else {
         $OP5Environment = "Prod"
         New-Item -Path "C:\Users\$env:USERNAME\AppData\Local\.ohmenv" -Value $OP5Environment -Force
      }
   } else {
      New-Item -Path "C:\Users\$env:USERNAME\AppData\Local\.ohmenv" -Value $OP5Environment -Force
   }

   do {
      $continueRepeating = $true

      ## Definierar variabler utifrån miljö
      if ($OP5Environment -match "Test") {
            $notUsedEnvironment = "Prod"
            $env = "op5test.lkl.ltkalmar.se"
      } else {
         $notUsedEnvironment = "Test"
         $env = "op5.lkl.ltkalmar.se"
      }

      ## Ge alternativ på vad man vill göra och frågar användaren vilket
      Clear-Host
      Write-Host "Välkommen till OP5HostManager (OHM). Med OHM kan du enkelt administrera OP5 via Powershellterminalen."`n
      if ($OP5Environment -eq "Test") {
         Write-Host "Du befinner dig i $OP5Environment ($env)."`n -ForegroundColor Green
      } else {
         Write-Host "Du befinner dig i $OP5Environment ($env)."`n -ForegroundColor Red
      }
      Write-Host "Välj vad du vill göra:"`n
      Write-Host "1. Lägga upp Windowshost (Add-OP5WindowsHost)"
      Write-Host "2. Lägga upp Linuxhost (Add-OP5LinuxHost)"
      Write-Host "3. Ta bort host (Remove-OP5Host)"
      Write-Host "4. Återställa borttagen host (Restore-OP5Host)"
      Write-Host "5. Kopiera host från $OP5Environment till $notUsedEnvironment (Copy-OP5Host)"
      Write-Host "6. Byta miljö till $notUsedEnvironment"
      Write-Host "7. Avsluta"`n
      do {
         ## Frågar om val, kollar att den är ett heltal och inom valalternativen, repeterar tills den har ett giltigt val
         try {
            [int]$selection = Read-Host "Ange ditt val"
            if (($selection -ge 8) -or ($selection -le 0)) {
               Write-Host "Du måste ange ett heltal mellan 1 och 7" -ForegroundColor Red
               $selection = ""
            }
         }
         catch {
            if ($_ -match "Cannot convert value") {
               Write-Host "Du måste ange ett heltal." -ForegroundColor Red
            } else {
               Show-ErrorMessage -ErrorMessage $_
               return
            }
         }
      } until (
         $selection
      )
      
      switch ($selection) {
         1 {
            ## Lägga upp Windowshost (med Add-OP5Host)
            Get-HostData -OS Windows
         }
         2 {
            ## Lägga upp Linuxhost (med Add-OP5Host)
            Get-HostData -OS Linux
         }
         3 {
            ## Frågar om och testar autentiseringsuppgifter
            Get-Authentication -Env $env

            ## Frågar efter host att ta bort, kontrollerar att den finns och kör Remove-OP5Host
            do {
               Clear-Host
               $hostname = Read-Host "Ange namn på den host du vill ta bort"
            } until ($hostname)
            Remove-OP5Host -Hostname $hostname -OP5Environment $OP5Environment
         }
         4 {
            ## Frågar efter host att återställa och kör Restore-OP5Host
            Clear-Host
            Write-Host "Restore-OP5Host används för att återställa hostar som tagits bort med cmdleten Remove-OP5Host. Funktionen återställer hosten och samtliga checkar till det läge den var i när den togs bort. Observera att hosten återställs till den miljö den togs bort från."`n
            $hostname = Read-Host "Ange den host du vill återställa"
            Restore-OP5Host -Hostname $hostname
         }
         5 {
            ## Frågar efter host att kopiera och kör Copy-OP5Host
            Clear-Host
            Get-Authentication -Env $env
            Clear-Host
            $hostname = Read-Host "Ange den host du vill kopiera från $OP5Environment till $notUsedEnvironment"
            Copy-OP5Host -Hostname $hostname -OP5Environment $OP5Environment
         }
         6 {
            ## Sätter nuvarande miljö i en tillfällig variabel
            $tempEnvName = $OP5Environment
            ## Sätter den ej nuvarande miljön till nuvarande
            $OP5Environment = $notUsedEnvironment
            ## Sätter miljön i den tillfälliga variabeln som den ej nuvarande miljön
            $notUsedEnvironment = $tempEnvName
            ## Skriver till .ohmenv
            New-Item -Path "C:\Users\$env:USERNAME\AppData\Local\.ohmenv" -Value $OP5Environment -Force
         }
         7 {
            ## Avslutar OHM
            Clear-Host
            return
         }
      }
   } while (
      $continueRepeating -eq $true
   )
}

## Funktion för att lägga upp OP5-host
function Add-OP5Host {
    <#
      .Synopsis
      Lägger upp en host i OP5 med standardcheckarna för antingen Windows eller Linux.

      .Description
      Lägger upp en host i OP5 med standardcheckarna för antingen Windows eller Linux, beroende på vad som är satt i OS-parametern. För Windows är dessa CPU Load, Cisco Amp, Disk Usage för det antal diskar man angett, Mem usage, PING, Uptime och Windows Updates.
      För Linux är standardcheckarna SSH Localhost, Crond Process, Disk Boot, Disk Root, DNS Response, Load Average per Core, Memory Free, NTP Offset, PING, Total Processes, Uptime, Zombie Processes och OS Updates.

      Cmdleten har parametrarna:  $Hostname, $System, $Disks (mellan 0 och 24 stycken), $Contactgroups, $Servicegroups, $OP5Environment (Prod eller Test), $LastHost och $OS (Windows eller Linux). 

      Cmdleten är bara kompatibel med Powershell 7 och uppåt.

      .Example
      Add-OP5Host -Hostname "server01" -OP5Environment "Prod" -System "Cosmic" -Disks 4 -Contactgroups "OC","TSFV" -Servicegroups "Cosmic","Cosmic Test" -OS "Windows"
   #>

   [CmdletBinding()]
   param (
      [Parameter(Mandatory=$true, HelpMessage="Host som ska läggas upp")]
        [string]$Hostname,
      
      [Parameter(Mandatory=$true, HelpMessage="System som ska köras på hosten (alias i OP5)")]
        [string]$System,

      [Parameter(Mandatory=$false, HelpMessage="Antal diskar som finns på hosten")]
        [validateRange(0,24)]
        [int]$Disks,

      [Parameter(Mandatory=$false, HelpMessage="Kontaktgrupp(er) som ska läggas på hosten")]
        [array]$Contactgroups,

      [Parameter(Mandatory=$false, HelpMessage="Servicegrupp(er) som ska läggas på hostens checkar")]
        [array]$Servicegroups,

      [Parameter(Mandatory=$false, HelpMessage="OP5 Test eller Prod")]
        [validateSet("Prod","Test")]
        [string]$OP5Environment="Prod",

      [Parameter(Mandatory=$false)]
        [bool]$LastHost = $true,

      [Parameter(Mandatory=$true)]
         [validateSet("Windows","Linux")]
         [string]$OS
   )


   ## Sätter rätt funktions-ID så att rätt logg skrivs till OHM
   if ($OS -eq "Windows") {
      $functionID = 102
   } else {
      $functionID = 103
   }

   ## Kollar ifall det finns flera hostar angivna, tar bort eventuella mellanslag och kör Add-OP5Host för varje host, frågar därefter om sparning
   if ($Hostname -match ",") {
      $hostArray = $Hostname.Split(",") | ForEach-Object {$_.Trim()}
      foreach ($object in $hostArray) {
         Add-OP5Host -Hostname $object -System $System -Disks $Disks -Contactgroups $Contactgroups -Servicegroups $Servicegroups -OP5Environment $OP5Environment -LastHost $false -OS $OS
      }
      Confirm-HostSaveInfo -OP5Environment $OP5Environment -EnvironmentURI $env -Hostname $hostArray[0] -FunctionID $functionID -HostArray $hostArray
      return
   } else {
      $hostArray = @()
   }

   ## Kollar vilken miljö som angetts
   if ($OP5Environment -match "Test") {
      $env = "op5test.lkl.ltkalmar.se"
   } else {$env = "op5.lkl.ltkalmar.se"}

   ## Hämtar autentiseringsuppgifter
   Get-Authentication -Env $env

   ## Kontrollerar hostnamn
   $Hostname = Test-Hostname -Hostname $Hostname

   ## Om hostnamnet matchar PC-namn, gör till små bokstäver och lägg på .lkl.ltkalmar.se, annars hämta IP-adress
   if ($Hostname -match "^(PC|PCX)\d{5,6}") {
      $address = "$($Hostname.ToLower()).lkl.ltkalmar.se"
   } else {
      $address = Get-IPAddress -Hostname $Hostname
      if (!$address) {
         return
      }
   }
   
   ## Kolla om varje kontaktgrupp finns
   if ($Contactgroups) {
      $contactgroupsList = @()
      foreach ($cg in $contactgroups) {
         if (Test-ContactGroup -Contactgroup $cg) {
            $contactgroupsList += $cg
         }
      }
   }
   
   ## Kolla om varje servicegrupp finns
   if ($Servicegroups) {
      $servicegroupsList = @()
      foreach ($sg in $Servicegroups) {
         if (Test-Servicegroup -Servicegroup $sg) {
            $servicegroupsList += $sg
         }
      }
   }
   
   ## Hämtar rätt info om hostar och checkar från json-filer, beroende på OS
   if ($OS -eq "Windows") {
      $hostTable = Get-Content -Path "$env:LOCALAPPDATA\OP5Hostmanager\resources\windowsHostConfig.json" | ConvertFrom-Json
      $servicesArray = Get-Content -Path "$env:LOCALAPPDATA\OP5Hostmanager\resources\windowsServicesConfig.json" | ConvertFrom-Json
      $disksArray = Get-Content -Path "$env:LOCALAPPDATA\OP5Hostmanager\resources\windowsDisksConfig.json" | ConvertFrom-Json
   } else {
      $hostTable = Get-Content -Path "$env:LOCALAPPDATA\OP5Hostmanager\resources\linuxHostConfig.json" | ConvertFrom-Json
      $servicesArray = Get-Content -Path "$env:LOCALAPPDATA\OP5Hostmanager\resources\linuxServicesConfig.json" | ConvertFrom-Json
   }

   $hostTable.host_name = $Hostname
   $hostTable.address = $address
   $hostTable.alias = $system
   $hostTable.contact_groups = $contactgroupsList
   
   Clear-Host
   Write-Host "Lägger upp hosten $Hostname" -ForegroundColor Green

   ## Skapar hosten
   $succeded = Send-OP5Host -HostHashTable $hostTable -Environment $env

   ## Om ett fel uppstod vid skapande av host blir $succeeded false, och funktionen avslutas
   if (!$succeded) {
      return
   }

   ## Skapar varje check i arrayen från json-fil
   foreach ($table in $servicesArray) {
      $table.host_name = $Hostname
      $table.contact_groups = $contactgroupsList
      $table.servicegroups = $servicegroupsList
      Send-OP5Service -Environment $env -ServiceHashTable $table
   }

   ## Skapar rätt antal diskcheckar om det är Windows
   if ($OS -eq "Windows" -and $Disks) {
      for ($i = 0; $i -lt $Disks - 1; $i++) {
         $disksArray[$i].host_name = $Hostname
         $disksArray[$i].contact_groups = $contactgroupsList
         $disksArray[$i].servicegroups = $servicegroupsList
         Send-OP5Service -Environment $env -ServiceHashTable $disksArray[$i]
      }
   }
   
   Clear-Host

   ## Avslutar nuvarande iteration av funktionen om flera hostar läggs upp samtidigt
   if (!$LastHost) {
      return
   }

   ## Fråga om att spara ändringar
   Confirm-HostSaveInfo -OP5Environment $OP5Environment -EnvironmentURI $env -Hostname $Hostname -FunctionID $functionID -HostArray $hostArray
}

## Funktion för att ta bort host och skapa återställningsskript
function Remove-OP5Host {
   <#
     .Synopsis
     Tar bort en host i OP5 och skapar skript för återställning, som kan exekveras antingen direkt eller med Restore-OP5Host. 

     .Description
     Tar bort en angiven host i OP5. Innan dess skapar den dock ett Powershellskript i mappen C:\Users\%USERNAME%\AppData\Local\OP5HostManager\Restore-OP5Host. Detta skript återställer hosten till det läge den var i när den togs bort. Återställningsskriptet kan antingen köras direkt eller med hjälp av cmdleten Restore-OP5Host.
     Cmdleten har parametrarna: $Hostname, $OP5Environment och $LastHost

     Cmdleten är bara kompatibel med Powershell 7 och uppåt.

     .Example
     Remove-OP5Host -Hostname server01 -OP5Environment Prod
   #>
   
   [CmdletBinding()]
   param (
      [Parameter(Mandatory=$true, HelpMessage="Host som ska tas bort")]
         [string]$Hostname,

      [Parameter(Mandatory=$False, HelpMessage="OP5 Test eller Prod")]
         [validateSet("Prod","Test")]
         [string]$OP5Environment="Prod",

      [Parameter(Mandatory=$false)]
         [bool]$LastHost = $true
   )

   ## Kollar ifall det har angetts flera hostar, isåfall kör funktionen för varje host
   if ($Hostname -match ",") {
      $hostArray = $Hostname.Split(",") | ForEach-Object {$_.Trim()}
      foreach ($object in $hostArray) {
         $LastHost = $true
         if ($object -ne $hostArray[-1]) {
            $LastHost = $false
         }
         Remove-OP5Host -Hostname $object -OP5Environment $OP5Environment -LastHost $LastHost
      }
      return
   }

   ## Kolla vilken miljö som angetts
   if ($OP5Environment -match "Test") {
      $env = "op5test.lkl.ltkalmar.se"
   } else {$env = "op5.lkl.ltkalmar.se"}

   ## Kollar om autentiseringsuppgifter har angetts, annars frågar om det och testar att de funkar
   Get-Authentication -Env $env

   ## Om hostnamnet matchar ett PC, PCX, LKL eller COx-namn med små bokstäver, gör bokstäverna stora och kolla att hostnamnet finns
   $hostname = Test-Hostname -Hostname $hostname
   try {
      Invoke-RestMethod -Uri "https://$env/api/config/host/$hostname" -Method "GET" -Credential $cred | Out-Null
   }
   catch {
      if (($_ | ConvertFrom-Json).error -eq "Object not found") {
         Write-Host "Hosten $hostname finns inte." -ForegroundColor Red
         Start-Sleep -Seconds 2
         Clear-Host
         return
         $hostname = ""
      } else {
         Show-ErrorMessage -ErrorMessage $_
         return
      }
   }

   $backupPath = "$env:LOCALAPPDATA\OP5HostManager\Restore-OP5Host\"
   $backupName = "${Hostname}_återställning.ps1"
   $modulePath = "$env:LOCALAPPDATA\OP5HostManager\"

   ## Hämtar all info om hosten, kollar därefter vilka services som finns på hosten
   try {
      $hostInfo = Invoke-RestMethod -Uri "https://$env/api/config/host/$Hostname" -Method "GET" -Credential $cred
      $hostJson =  $hostInfo | Select-Object -Property * -ExcludeProperty services | ConvertTo-Json -EscapeHandling EscapeNonAscii -Compress
      $serviceObject = $hostInfo.services
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }

   ## Definierar inledningen på återställningsskriptet där man hämtar autentiseringsuppgifter och lägger upp hosten
   $textblock = @"
   ## Återställningsskript för $Hostname

   if (!`$cred) {
      `$cred = Get-Credential -Title "Autentisering" -Message "Ange användarnamn och lösenord"
      try {
         Invoke-RestMethod -Uri "https://$env/api/config/timeperiod" -Method "GET" -Credential `$cred | Out-Null
      }
      catch {
         Write-Host "Ett fel uppstod. Se nedan:" -ForegroundColor Red
         Write-Host ""
         Write-Host `$_ -ForegroundColor Red
         Start-Sleep -Seconds 5
         return "Avslutar..."
      }
   }

   try {
      Invoke-RestMethod -Uri "https://$env/api/config/host" -Method "POST" -Credential `$cred -ContentType "application/json" -Body '$hostJson' | Out-Null
   }
   catch {
      Write-Host "Ett fel uppstod i samband med återuppläggning av hosten. Se nedan:" -ForegroundColor Red
      Write-Host ""
      Write-Host `$_
      Start-Sleep -Seconds 5
      return "Avslutar..."
   }
"@

   ## För varje service på hosten, hämta all info om servicen, konvertera till JSON och lägg till i återställninggskriptet
   foreach ($service in $serviceObject) {
      $service | Add-Member -MemberType NoteProperty -Name "host_name" -Value $Hostname
      $newService = $service | ConvertTo-Json -EscapeHandling EscapeNonAscii -Compress
      $textblock += "`n`n"
      $textblock += @"
   try {
      Invoke-RestMethod -Uri 'https://$env/api/config/service' -Method 'POST' -Credential `$cred -ContentType 'application/json' -Body $newService | Out-Null
   }
   catch {
      Write-Host "Ett fel uppstod i samband med uppläggning av checken $($service.service_description). Se nedan:" -ForegroundColor Red
      Write-Host ""
      Write-Host `$_
      Start-Sleep -Seconds 5
      return "Avslutar..."
   }
"@
   }

   ## Lägger till kod i återställningsskriptet för att hämta ändringar
   $textblock += @"

   Clear-Host

   try {
      `$changes = Invoke-RestMethod -Uri "https://$env/api/config/change" -Method "GET" -Credential `$cred
   }
   catch {
      Write-Host "Ett fel uppstod i samband med hämtning av ändringar. Se nedan:" -ForegroundColor Red
      Write-Host ""
      Write-Host `$_
      Start-Sleep -Seconds 5
      return "Avslutar..."
   }
"@

   ## Lägger till miljö med rätt textfärg
   if ($OP5Environment -eq "Test") {
      $textBlock += @"
      `n Write-Host "Du befinner dig i $OP5Environment ($env)." -ForegroundColor Green
"@
   } else {
      $textBlock += @"
      `n Write-Host "Du befinner dig i $OP5Environment ($env)." -ForegroundColor Red
"@
   }

   ## Lägger till del för att bekräfta ändringar
   $textBlock += @"
   `n`n
   Write-Host "Granska dina ändringar:"
   `$changes | Select-Object type,object_type,name,user,timestamp | Format-Table

   do {
      `$confirmAnswer = Read-Host "Skriv Y för att acceptera ändringarna eller N för att avbryta"
   } until ("Y", "N" -contains `$confirmAnswer)

   if (`$confirmAnswer -eq "Y") {
      try {
         Invoke-RestMethod -Uri "https://$env/api/config/change" -Method "POST" -Credential `$cred | Out-Null
         Write-Host "Host återställd, går till OP5" -ForegroundColor Green
         Start-Sleep -Seconds 2
         Start-Process "https://$env/monitor/index.php/listview?q=%5Bservices%5D%20host.name%3D%22$Hostname%22"
      }
      catch {
         Write-Host "Ett fel uppstod i samband med sparning av ändringar. Se nedan:" -ForegroundColor Red
         Write-Host ""
         Write-Host `$_
         Start-Sleep -Seconds 5
         return "Avslutar..."
      }
   } else {
      try {
         Invoke-RestMethod -Uri "https://$env/api/config/change" -Method "DELETE" -Credential `$cred | Out-Null
         Write-Host "Återställning avbruten" -ForegroundColor Red
         Start-Sleep -Seconds 3
      }
      catch {
         Write-Host "Ett fel uppstod i samband med ångring av ändringar. Se nedan:" -ForegroundColor Red
         Write-Host ""
         Write-Host `$_
         Start-Sleep -Seconds 5
         return "Avslutar..."
      }
   }
"@

   ## Raderar hosten (utan att spara ändringen)
   Invoke-RestMethod -Uri "https://$env/api/config/host/$Hostname" -Method "DELETE" -Credential $cred | Out-Null

   if (!$LastHost) {
      $textblock | Out-File $backupPath$backupName -Encoding utf8BOM
      return
   }

   Clear-Host

   ## Hämtar ändringar och frågar användaren om att spara
   try {
      $changes = Invoke-RestMethod -Uri "https://$env/api/config/change" -Method "GET" -Credential $cred
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }
   if ($OP5Environment -eq "Test") {
      Write-Host "Du befinner dig i $OP5Environment ($env)."`n -ForegroundColor Green
   } else {
      Write-Host "Du befinner dig i $OP5Environment ($env)."`n -ForegroundColor Red
   }
   Write-Host "Granska dina ändringar:"
   $changes | Select-Object type,object_type,name,user,timestamp | Format-Table

   do {
      $confirmAnswer = Read-Host "Skriv Y för att acceptera ändringarna eller N för att avbryta"
   } until (
      "Y", "N" -contains $confirmAnswer
   )

   ## Om svaret är ja, gör en pull i mappen, spara ändringarna, skriv återställningsskriptet till en fil, därefter gör en commit och push
   if ($confirmAnswer -eq "Y") {
      try {
         Set-Location $modulePath
         git pull *> $null
         Invoke-RestMethod -Uri "https://$env/api/config/change" -Method "POST" -Credential $cred | Out-Null
         Send-Log -FunctionID 104 -CurrentObject $Hostname | Out-Null
         $textblock | Out-File $backupPath$backupName -Encoding utf8BOM
         Set-Location $modulePath

         git add "./Restore-OP5Host/" *> $null 
         git commit -m "Laddar upp backupskript" *> $null
         git push *> $null
         Clear-Host
         Write-Host "Host borttagen, återställningsskript skapat i $backupPath och pushat till Gitlab." -ForegroundColor Green
         Start-Sleep -Seconds 2
      }
      catch {
         Show-ErrorMessage -ErrorMessage $_
         return
      }
   } else {
      try {
         Invoke-RestMethod -Uri "https://$env/api/config/change" -Method "DELETE" -Credential $cred | Out-Null
         Write-Host "Borttagning avbruten" -ForegroundColor Red
         Start-Sleep -Seconds 3
      }
      catch {
         Show-ErrorMessage -ErrorMessage $_
         return
      }
   }
}

## Funktion för att återställa host
function Restore-OP5Host {
   <#
     .Synopsis
     Återställer en host som tagits bort med hjälp av cmdleten Remove-OP5Host. 

     .Description
     Återställer en host som tagits bort med hjälp av cmdleten Remove-OP5Host. Hosten återställs till det stadie den var i när den togs bort och till den miljö den togs bort från. För att cmdleten ska fungera måste hostens återställningsskript finnas i C:\Users\%USERNAME%\AppData\Local\OP5HostManager\Restore-OP5Host. Återställningskripten följer formatet hostnamn_återställning.ps1.

     Cmdleten har parametern: $Hostname

     Cmdleten är bara kompatibel med Powershell 7 och uppåt.

     .Example
     Restore-OP5Host -Hostname server01
   #>

   [CmdletBinding()]
   param (
      [Parameter(Mandatory=$true, HelpMessage="Host som ska återställas")]
      [string]$Hostname
   )
   
   ## Om hostnamnet matchar ett PC, PCX, LKL eller COx-namn med små bokstäver, gör bokstäverna stora
   $Hostname = Test-Hostname -Hostname $Hostname
   $backupName = "${Hostname}_återställning.ps1"
   Set-Location "$env:LOCALAPPDATA\OP5HostManager\Restore-OP5Host\"
   
   ## Gör en pull
   try {
      git pull *> $null
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }

   ## Om återställningsskriptet hittas, kör det, annars säg till
   if (Test-Path .\"$backupName") {
      try {
         Clear-Host
         Invoke-Expression .\$backupName
         Send-Log -FunctionID 105 -CurrentObject $Hostname | Out-Null
      }
      catch {
         Show-ErrorMessage -ErrorMessage $_
         return
      }
   } else {
      Write-Host "Skriptet $backupname kunde inte hittas." -ForegroundColor Red
      Start-Sleep -Seconds 3
   }
}

## Funktion för att kopiera host mellan miljöer
function Copy-OP5Host {
   <#
     .Synopsis
     Kopierar en host från den miljö du är i till den andra.

     .Description
     Kopierar en host från den miljö du är i till den andra. Är du exempelvis i Test anger du en host som finns i Test, då kopieras den till Prod. Alla underliggande checkar kopieras också.

     Cmdleten har parametrarna:  $Hostname, $OP5Environment

     Cmdleten är bara kompatibel med Powershell 7 och uppåt.

     .Example
     Copy-OP5Host -Hostname server01 -OP5Environment Prod
   #>

   [CmdletBinding()]
   param (
      [Parameter(Mandatory=$true, HelpMessage="Host som ska återställas")]
      [string]$Hostname,

      [Parameter(Mandatory=$False, HelpMessage="OP5 Test eller Prod")]
      [validateSet("Prod","Test")]
      [string]$OP5Environment="Prod"
   )

   ## Kolla vilken miljö som angetts
   if ($OP5Environment -match "Test") {
      $env = "op5test.lkl.ltkalmar.se"
      $notUsedEnv = "op5.lkl.ltkalmar.se"
   } else {
      $env = "op5.lkl.ltkalmar.se"
      $notUsedEnv = "op5test.lkl.ltkalmar.se"
   }

   ## Kolla om autentiseringsuppgifter har angetts, annars fråga om det och testar att de funkar
   Get-Authentication -Env $env

   ## Om hostnamnet matchar ett PC, PCX, LKL eller COx-namn med små bokstäver, gör bokstäverna stora
   $Hostname = Test-Hostname -Hostname $Hostname

   try {
      ## Hämtar info om hosten
      $hostInfo = Invoke-RestMethod -Uri "https://$env/api/config/host/$Hostname" -Method "GET" -Credential $cred | Select-Object -Property * -ExcludeProperty services
      ## Hämtar lista över hostgrupper i den mottagande miljön
      $hgList = (Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/hostgroup" -Method "GET" -Credential $cred).name
      $hgArray = @()
      ## Kollar för varje hostgrupp om den finns i den mottagande miljön
      foreach ($hg in $hostInfo.hostgroups) {
         if ($hgList -ccontains $hg) {
            $hgArray += $hg
         }
      }
      $hostInfo.hostgroups = $hgArray
      ## Tar bort värden för kontaktgrupper, templates, parents och children för att undvika fel
      $hostInfo.contact_groups = @()
      $hostInfo.template = "default-host-template"
      $hostInfo.parents = ""
      $hostInfo.children = ""
      $hostJson = $hostInfo | ConvertTo-Json -EscapeHandling EscapeNonAscii -Compress
      
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }

   ## Lägger upp hosten
   try {
      Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/host" -Method "POST" -Credential $cred -ContentType "application/json" -Body $hostJson | Out-Null
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }

   ## Hämtar info om hostens checkar
   try {
      $serviceObject = (Invoke-RestMethod -Uri "https://$env/api/config/host/$Hostname" -Method "GET" -Credential $cred).services
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }

   ## Hämtar lista över tillgängliga checkkommandon i mottagande miljön
   $commandsList = (Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/command" -Method "GET" -Credential $cred).name
   ## Hämtar lista över tillgängliga servicegrupper i mottagande miljön
   $sgList = (Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/servicegroup" -Method "GET" -Credential $cred).name
   $missingCommandList = @()
   ## Kollar för varje service ifall checkkommando och servicegrupper finns i mottagande miljön, om checkkommandot finns så läggs servicen upp, sätter standardvärden på template och kontaktgrupper
   foreach ($service in $serviceObject) {
      if ($commandsList -cnotcontains $service.check_command) {
         Write-Host "Checkkommandot '$($service.check_command)' som används för checken '$($service.service_description)' finns inte definierat i $notUsedEnv. Går vidare till nästa check...`n" -ForegroundColor Red
         $missingCommandList += $service.check_command
      } else {
         $service.template = "default-service"
         $sgArray = @()
         foreach ($sg in $service.servicegroups) {
            if ($sgList -ccontains $sg) {
               $sgArray += $sg
            }
         }
         $service.servicegroups = $sgArray
         $service.contact_groups = @()
         $service | Add-Member -MemberType NoteProperty -Name host_name -Value $hostname
         $jsonService = $service | ConvertTo-Json -EscapeHandling EscapeNonAscii -Compress
         try {
            Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/service" -Method 'POST' -Credential $cred -ContentType 'application/json' -Body $jsonService | Out-Null
         }
         catch {
            Show-ErrorMessage -ErrorMessage $_
            return
         }
      }
   }
   
   ## Kollar ifall det finns några checkar på någon av hostgrupperna, isåfall lägg till dem direkt på hosten
   $newHostInfo = (Invoke-RestMethod -Uri "https://$env/api/config/host/$Hostname" -Method "GET" -Credential $cred).hostgroups
   foreach ($hg in $newHostInfo) {
      ## Om det finns /, ersätt med den URL-enkodade varianten, anledningen till att man inte URL-enkodar vanligt är att OP5 av någon anledning URL-kodar / till %252F istället för %2F (förmodligen pga bugg)
      if ($hg -match "/") {
         $hg = $hg.Replace("/", "%252F")
      }
      ## Hämtar services på aktuell hostgrupp och lägger upp dem som vanliga checkar
      $hgServices = (Invoke-RestMethod -Uri "https://$env/api/config/hostgroup/$hg" -Method "GET" -Credential $cred).services
      if ($hgServices) {
         foreach ($service in $hgServices) {
            if ($commandsList -cnotcontains $service.check_command) {
               Write-Host "Checkkommandot '$($service.check_command)' som används för checken '$($service.service_description)' finns inte definierat i $notUsedEnv. Går vidare till nästa check...`n" -ForegroundColor Red
               $missingCommandList += $service.check_command
            } else {
               $service.contact_groups = @()
               $service.template = "default-service"
               $service | Add-Member -MemberType NoteProperty -Name host_name -Value $hostname
               $hgServicesJson = $service | ConvertTo-Json -EscapeHandling EscapeNonAscii
               try {
                  Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/service" -Method 'POST' -Credential $cred -ContentType 'application/json' -Body $hgServicesJson | Out-Null
               }
               catch {
                  Show-ErrorMessage -ErrorMessage $_
                  return
               }
            }
         }
      }
   }

   ## Skriv ut de kommandon som saknas och hur många checkar som använder dem, frågar om man ändå vill lägga till
   if ($missingCommandList) {
      Write-Host ""
      foreach ($object in ($missingCommandList | Group-Object)) {
         Write-Host "$($object.Name) (används av $($object.Count) checkar)"
      }
      Write-Host ""
      $continueAnswer = Read-Host "Ovanstående checkkommandon saknades vid uppläggning av checkar, och om du fortsätter kommer inte dessa checkar läggas till. Vill du fortsätta? (Y/N)"
      if (($continueAnswer -eq "N") -or ($continueAnswer -eq "No")) {
         Write-Host "Avbryter..." -ForegroundColor Red
         Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/change" -Method "DELETE" -Credential $cred | Out-Null
         return
      }
   }

   Clear-Host

   ## Visa ändringar och fråga om sparning, om ja lägg upp och gå till OP5
   try {
      $changes = Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/change" -Method "GET" -Credential $cred
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }
   Write-Host "Granska dina ändringar som kommer göras i ${notUsedEnv}:"
   $changes | Select-Object type,object_type,name,user,timestamp | Format-Table

   do {
      $confirmAnswer = Read-Host "Skriv Y för att acceptera ändringarna eller N för att avbryta"
   } until ("Y", "N" -contains $confirmAnswer)

   if ($confirmAnswer -eq "Y") {
      try {
         Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/change" -Method "POST" -Credential $cred | Out-Null
         if ($env -eq "op5.lkl.ltkalmar.se") {
            Send-Log -FunctionID 106 -CurrentObject $Hostname | Out-Null
         } else {
            Send-Log -FunctionID 107 -CurrentObject $Hostname | Out-Null
         }
         Write-Host "Host upplagd, går till OP5" -ForegroundColor Green
         Start-Sleep -Seconds 2
         Start-Process "https://$notUsedEnv/monitor/index.php/listview?q=%5Bservices%5D%20host.name%3D%22$Hostname%22"
      }
      catch {
         Show-ErrorMessage -ErrorMessage $_
         return
      }
   } else {
      try {
         Invoke-RestMethod -Uri "https://$notUsedEnv/api/config/change" -Method "DELETE" -Credential $cred | Out-Null
         Write-Host "Återställning avbruten" -ForegroundColor Red
         Start-Sleep -Seconds 3
      }
      catch {
         Show-ErrorMessage -ErrorMessage $_
         return
      }
   }
}

## Funktion för att fråga användaren om hostdata
function Get-HostData {
   param (
      [Parameter(Mandatory=$False)]
        [validateSet("Linux","Windows")]
        [string]$OS
   )

   ## Frågar om och testar autentiseringsuppgifter
   Get-Authentication -Env $env
   Clear-Host
   $hostname = Read-Host "Ange host som ska läggas upp"
   $system = Read-Host "Ange vilket system som ska köras (alias)"

   ## Om Windows, frågar om antal diskar och ser till att det inte är fler än 24
   if ($OS -eq "Windows") {
      do {
         try {
            $disksNumber = ""
            [int]$disksNumber = Read-Host "Ange antal diskar"
            if ($disksNumber -gt 24) {
               Write-Host "Du kan inte ange fler än 24 diskar." -ForegroundColor Red
               $disksNumber = ""
            }
         }
         catch {
            if ($_ -match "Cannot convert value") {
               Write-Host "Du måste ange ett heltal." -ForegroundColor Red
               Start-Sleep -Seconds 3
            } else {
               Show-ErrorMessage -ErrorMessage $_
               return
            }
         }
      } until ($disksNumber)
   }

   ## Frågar efter kontaktgrupper och kontrollerar att de finns
   $contactgroupsList = @()
   do {
      $contactgroup = Read-Host "Ange kontaktgrupp för hosten, tryck enter för att gå vidare"
      if (!$contactgroup) {
         break
      }
      $allCGs = (Invoke-RestMethod -Uri "https://$env/api/config/contactgroup/" -Method "GET" -Credential $cred).name
      if (Test-ContactGroup -Contactgroup $contactgroup) {
         $contactgroupsList += $contactgroup
         Write-Host "Kontaktgruppen $contactgroup lades till" -ForegroundColor Green
      } elseif ($allCGs -match $contactgroup) {
         $cgMatchList = @("`nLiknande kontaktgrupper:")
         foreach ($row in $allCGs) {
            if ($row -match $contactgroup) {
               $cgMatchList += $row
            }
         }
         $cgMatchList += ""
         $cgMatchList
      }
   } until (!$contactgroup)

   ## Frågar efter servicegrupper och kontrollerar att de finns
   $servicegroupsList = @()
   do {
      $servicegroup = Read-Host "Ange servicegrupp för hostens checkar, tryck enter för att gå vidare"
      $allSGs = (Invoke-RestMethod -Uri "https://$env/api/config/servicegroup/" -Method "GET" -Credential $cred).name
      if (!$servicegroup) {
         break
      }
      if (Test-Servicegroup -Servicegroup $servicegroup) {
         $servicegroupsList += $servicegroup
         Write-Host "Servicegruppen $servicegroup lades till" -ForegroundColor Green
      } elseif ($allSGs -match $servicegroup) {
         $sgMatchList = @("`nLiknande servicegrupper:")
         foreach ($row in $allSGs) {
            if ($row -match $servicegroup) {
               $sgMatchList += $row
            }
         }
         $sgMatchList += ""
         $sgMatchList
      }
   } until (!$servicegroup)

   ## Kör Add-OP5Host med den insamlade infon som parametrar
   try {
      Add-OP5Host -Hostname $hostname -System $system -Disks $disksNumber -Contactgroups $contactgroupsList -Servicegroups $servicegroupsList -OP5Environment $OP5Environment -OS $OS 
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
   }
}

## Funktion för att lägga upp OP5-host
function Send-OP5Host {
   param (
      [Parameter(Mandatory=$true)]
      [object]$HostHashTable,

      [Parameter(Mandatory=$true)]
      [string]$Environment
   )

   ## Funktionen returnar true eller false beroende på om uppläggandet lyckades eller inte
   try {
      Invoke-RestMethod -Uri "https://$Environment/api/config/host" -Method "POST" -Credential $cred -ContentType "application/json" -Body ($HostHashTable | ConvertTo-Json -EscapeHandling EscapeNonAscii) | Out-Null
      return $true
   }
   catch {
      if (($_ | Test-Json -ErrorAction SilentlyContinue) && (($_ | ConvertFrom-Json).error -eq "Object already exists")) {
         Clear-Host
         Write-Host "$Hostname finns redan i OP5." -ForegroundColor Red
         Start-Sleep -Seconds 5
         return $false
      } else {
         Show-ErrorMessage -ErrorMessage $_
      }
   }
}

## Funktion för att lägga upp check
function Send-OP5Service {
   param (
      [Parameter(Mandatory=$true)]
      [object]$ServiceHashTable,

      [Parameter(Mandatory=$true)]
      [string]$Environment
   )

   try {
      Invoke-RestMethod -Uri "https://$Environment/api/config/service" -Method "POST" -Credential $cred -ContentType "application/json" -Body ($ServiceHashTable | ConvertTo-Json -EscapeHandling EscapeNonAscii) | Out-Null
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }
}

## Funktion för att hämta autentiseringsuppgifter
function Get-Authentication {
   param (
      [Parameter(Mandatory=$true)]
      [string]$Env
   )

   ## Kolla om .ohmcred.xml finns (filen där ens krypterade autentiseringsuppgifter lagras), isåfall importera innehållet, annars fråga om lösenordet
   if (Test-Path -Path "$env:LOCALAPPDATA\.ohmcred.xml") {
      $global:cred = Import-Clixml -Path "$env:LOCALAPPDATA\.ohmcred.xml"
   } else {
      Clear-Host
      $global:cred = Get-Credential -Title "Autentisering" -Message "Ange användarnamn och lösenord till OP5"
   }

   ## Testar uppgifterna, om det är rätt sätts $authIsCorrect till true vilket tar en ur loopen
   do {
      try {
         Invoke-RestMethod -Uri "https://$env/api/config/timeperiod" -Method "GET" -Credential $cred | Out-Null
         $authIsCorrect = $true
      }
      catch {
         if (($_ | Test-Json -ErrorAction SilentlyContinue) -and ($_ | ConvertFrom-Json).full_error -match "You need to login to access this page") {
            Write-Host "Användarnamn eller lösenord är felaktigt, försök igen" -ForegroundColor Red
            Write-Host ""
            $global:cred = Get-Credential -Title "Autentisering" -Message "Ange användarnamn och lösenord till OP5"
            $authIsCorrect = $false
         } else {
            Show-ErrorMessage -ErrorMessage $_
            return
         }    
      }
   } until ($authIsCorrect)
   ## När uppgifterna är rätt, skriv uppgifterna till .ohmcred.xml
   $cred | Export-Clixml -Path "$env:LOCALAPPDATA\.ohmcred.xml"
}

## Funktion för att kolla om hostnamn är skrivet med stora bokstäver, om inte ändra det
function Test-Hostname {
   param (
      [Parameter(Mandatory=$true)]
      [string]$Hostname
   )

   if ($Hostname -match "^[a-z]{2,3}\d{5,6}$|^[a-z]{3}\d{2,4}$") {
      $Hostname = $Hostname.ToUpper()
      return $Hostname
   } else {
      return $Hostname
   }
}

## Funktion för att hämta IP-adress från DNS:en
function Get-IPAddress {
   param (
      [Parameter(Mandatory=$true)]
        [string]$Hostname
   )

   try {
      ## Försök hämta IP-adress
      $address = (Resolve-DnsName -Name "$Hostname.lkl.ltkalmar.se" -ErrorAction Stop).IPAddress
   }
   catch {
      Start-Sleep -Seconds 2
      if ($_ -match "DNS-namnet finns inte.") {
         try {
            ## Om den inte hittar, prova DMZ
            $address = (Resolve-DnsName -Name "$Hostname.dmz.ltkalmar.se" -ErrorAction Stop).IPAddress
         }
         catch {
            if ($_ -match "DNS-namnet finns inte.") {
               ## Om det fortfarande inte funkar, fråga om IP eller hostnamn
               Clear-Host
               Write-Host "Hostnamnet `"$Hostname`" kunde inte hittas i DNS:en." -ForegroundColor Red
               $address = Read-Host "Specificera manuellt en IP-address eller hostnamn (inklusive xx.ltkalmar.se)"
            } else {
               Show-ErrorMessage -ErrorMessage $_
            }
         }
      } else {
         Show-ErrorMessage -ErrorMessage $_
      }
   }
   return $address
}

## Funktion för att kolla om kontaktgrupp finns
function Test-ContactGroup {
   param (
      [Parameter(Mandatory=$true)]
      [string]$Contactgroup
   )

   ## Hämtar alla kontaktgrupper från OP5
   try {
      $allCGs = (Invoke-RestMethod -Uri "https://$env/api/config/contactgroup/" -Method "GET" -Credential $cred).name
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }

   ## Kollar om aktuell grupp finns i listan
   if ($allCGs -ccontains $Contactgroup) {
      return $true
   } else {
      Write-Host "Kontaktgruppen $Contactgroup finns inte" -ForegroundColor Red
      return $false
   }
}

## Funktion för att kolla om servicegrupp finns
function Test-Servicegroup {
   param (
      [Parameter(Mandatory=$true)]
      [string]$Servicegroup
   )

   ## Hämtar alla servicegrupper från OP5
   try {
      $allSGs = (Invoke-RestMethod -Uri "https://$env/api/config/servicegroup/" -Method "GET" -Credential $cred).name
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }
   
   ## Kollar om aktuell grupp finns i listan
   if ($allSGs -ccontains $Servicegroup) {
      return $true
   } else {
      Write-Host "Servicegruppen $Servicegroup finns inte" -ForegroundColor Red
      return $false
   }
}

## Funktion för att fråga om man vill spara eller inte
function Confirm-HostSaveInfo {
   param (
      [Parameter(Mandatory=$true)]
      [string]$OP5Environment,

      [Parameter(Mandatory=$true)]
      [string]$EnvironmentURI,

      [Parameter(Mandatory=$true)]
      [string]$Hostname,

      [Parameter(Mandatory=$true)]
      [string]$FunctionID,

      [Parameter(Mandatory=$false)]
      [array]$HostArray
   )


   ## Hämtar ändringar och frågar om man vill spara eller inte
   Clear-Host
   try {
      $changes = Invoke-RestMethod -Uri "https://$EnvironmentURI/api/config/change" -Method "GET" -Credential $cred
   }
   catch {
      Show-ErrorMessage -ErrorMessage $_
      return
   }
   if ($OP5Environment -eq "Test") {
      Write-Host "Du befinner dig i $OP5Environment ($EnvironmentURI)."`n -ForegroundColor Green
   } else {
      Write-Host "Du befinner dig i $OP5Environment ($EnvironmentURI)."`n -ForegroundColor Red
   }

   Write-Host "Granska dina ändringar:"
   $changes | Select-Object type,object_type,name,user,timestamp | Format-Table
   
   do {
      $confirmAnswer = Read-Host "Skriv Y för att acceptera ändringarna eller N för att avbryta"
   } until (
      "Y", "N" -contains $confirmAnswer
   )

   ## Om svaret är ja, gör sparningen och gå till OP5-sidan, annars radera ändringarna
   if ($confirmAnswer -eq "Y") {
      $makeSave = {
         Invoke-RestMethod -Uri "https://$EnvironmentURI/api/config/change" -Method "POST" -Credential $cred | Out-Null
         Send-Log -FunctionID $FunctionID -CurrentObject $Hostname | Out-Null
         Write-Host "Host upplagd, går till OP5" -ForegroundColor Green
         Start-Sleep -Seconds 2
         if ($hostArray) {
            foreach ($object in $hostArray) {
               $object = $object.ToUpper()
               Start-Process "https://$EnvironmentURI/monitor/index.php/listview?q=%5Bservices%5D%20host.name%3D%22$object%22"
            }
         } else {
            Start-Process "https://$EnvironmentURI/monitor/index.php/listview?q=%5Bservices%5D%20host.name%3D%22$Hostname%22" 
         }
      }
      try {
         & $makeSave
      }
      catch {
         ## Gör så att den försöker igen om en stund om det är någon annan som sparar samtidigt
         if (($_ | Test-Json -ErrorAction SilentlyContinue) && (($_ | ConvertFrom-Json).error -match "Automatic configuration import failed")) {
            Write-Host "En annan sparning pågår." -ForegroundColor Red
            for ($i = 1; $i -le 15; $i++) {
               Write-Progress -Activity "Försöker igen om" -Status "$(16 - $i) sekunder" -PercentComplete (($i / 15) * 100)
               Start-Sleep -Seconds 1
            }
            Write-Progress -Completed
            try {
               & $makeSave
            }
            catch {
               Show-ErrorMessage -ErrorMessage $_
               return
            }
         } else {
            Show-ErrorMessage -ErrorMessage $_
            return
         }
      }
   } else {
      ## Raderar ändringen om svaret är nej
      try {
         Invoke-RestMethod -Uri "https://$EnvironmentURI/api/config/change" -Method "DELETE" -Credential $cred | Out-Null
         Write-Host "Uppläggning avbruten" -ForegroundColor Red
         Start-Sleep -Seconds 3
      }
      catch {
         Show-ErrorMessage -ErrorMessage $_
         return
      }
   }
}

## Funktion för att visa felmeddelande
function Show-ErrorMessage {
   param (
      [Parameter(Mandatory=$false)]
      [string]$ErrorMessage
   )
   Write-Host "Ett fel uppstod. Se nedan:" -ForegroundColor Red
   Write-Host ""
   Write-Host $_ -ForegroundColor Red
   Write-Host "Avslutar..."
   Start-Sleep -Seconds 5
   return
}

## Funktion för att skicka logg till Log4CjS
function Send-Log {
   param (
      [Parameter(Mandatory=$true)]
      [string]$FunctionID,

      [Parameter(Mandatory=$false)]
      [string]$CurrentObject
   )
   
   ## Hämtar fullt namn på användare
   $dom = $env:userdomain
   $usr = $env:username
   [string]$username = ([adsi]"WinNT://$dom/$usr,user").fullname

   if (!$username) {
      $username = "Okänd användare"
   }

   ## Sätter header med autentiseringsnyckel, användarnamn, använd funktion och berört objekt
   if ($currentObject) {
      $data = @{
         token = 'xxxxxxxxxxxxxxxxxxx' 
         user = $username
         button = $FunctionID
         object = $CurrentObject
      };
   } else {
      $data = @{
         token = 'xxxxxxxxxxxxxxxxxxx' 
         user = $username
         button = $FunctionID
      };
   }
   
   ## Gör anrop mot Log4CjS
   Invoke-RestMethod -Uri "https://serverx.lkl.ltkalmar.se/api/ohm/log" -Method Post -ContentType "application/json" -Body ($data | ConvertTo-Json)
}

## Definierar alias
New-Alias -Name ohm -Value Edit-OP5
New-Alias -Name ohmwin -Value Add-OP5WindowsHost
New-Alias -Name ohmlin -Value Add-OP5LinuxHost