# OP5HostManager

OP5HostManager (OHM) är ett verktyg som används för att administrera OP5 via Powershellterminalen. 

Nuvarande version är: 1.3.0.

Du kan kontrollera vilken version av OHM som är installerat genom att köra `Get-Module OP5HostManager` i en Powershellterminal.

## Installation

För att använda OP5HostManager krävs Powershell 7 eller högre. Vid behov, installera Powershell 7 genom att köra följande: 
```cmd
winget install Microsoft.Powershell
```
Git måste också vara installerat på din dator. Vid behov, installera det genom att köra följande: 

```cmd
winget install Git.Git
```
Du behöver ha också ha tillgång till Operations Centers Gitlab-repo. Om du har det, och inte har clonat något från Gitlab-repo förut, kommer du få frågan att ange användarnamn och lösenord till Gitlab vid installation. Du kommer också få frågan när du använder OP5HostManager om du precis har ändrat ditt lösenord.

För att installera OP5HostManager, kör skriptet "installation ohm.ps1" som administratör i Powershell 7. Därefter får du upp ett utforskarfönster där du kan hitta en genväg som bara heter OHM. Dra denna ner till ditt aktivitetsfält.

När OP5HostManager är installerat uppdateras det automatiskt med hjälp av en schemalagd pull från Gitlab.

## Användning

OP5HostManager kan köras på flera olika sätt.

* Det enklaste sättet att använda OHM är genom att använda genvägen du tidigare drog ner till ditt aktivietsfält. Du kan också göra samma sak med cmdleten `Edit-OP5` (alternativt aliaset `ohm`) i ett terminalfönster. När man använder genvägen eller kör cmdleten får man upp en flervalslista där man får välja vad man vill göra. Man får därefter frågor för den information som behövs. `Edit-OP5` är smidigt när man ska lägga upp, flytta eller ta bort enstaka hostar. När man ska lägga till eller ta bort flera hostar går det dock att göra genom att ange hostarna separerade med kommatecken.


* De olika cmdlets som ingår i OP5HostManager kan köras direkt i en Powershellterminal. Detta resulterar i mer skrivande än andra metoder men är bra om man ska lägga upp flera hostar efter varandra. Man kan med Powershell också bygga skript som använder sig av OHM-cmdletarna, exempelvis genom att använda en foreach-loop för att lägga upp flera hostar med olika parametrar.
<br><br>
Följande cmdlets finns, samt deras respektive alternativ när man använder genvägen:
<br><br>

   ### Add-OP5Host ("Lägga upp Windowshost" samt "Lägga upp Linuxhost")

   Add-OP5Host lägger upp en host i OP5 med standardcheckarna för antingen Windows eller Linux, beroende på vad som är satt i OS-parametern. För Windows är dessa CPU Load, Cisco Amp, Disk Usage för det antal diskar man angett, Mem usage, PING, Uptime och Windows Updates.
   För Linux är standardcheckarna SSH Localhost, Crond Process, Disk Boot, Disk Root, DNS Response, Load Average per Core, Memory Free, NTP Offset, PING, Total Processes, Uptime, Zombie Processes och OS Updates. Syntaxen är `Add-OP5Host -Hostname "Namn på host" -System "System som körs på hosten (alias)" -Disks "Antal diskar" (om Windows) -Contactgroups "Lista med kontaktgrupper separerade med komma" -Servicegroups "Lista med servicegrupper separerade med komma" -OP5Environment "OP5 Test eller Prod" -OS "Windows eller Linux"`. Exempel:
   ```powershell
   Add-OP5Host -Hostname server01 -OP5Environment Prod -System "DNS" -Disks 4 -Contactgroups OC,TSFV -Servicegroups "DNS","DNS Test" -OP5Environment Test -OS "Windows"
   ``` 
   Tidigare användes separata cmdlets för Windows och Linux (Add-OP5WindowsHost och Add-OP5LinuxHost), men sedan version 1.3.0 är dessa en gemensam cmdlet.
   <br><br>

   ### Remove-OP5Host ("Ta bort host")
 
   Remove-OP5Host tar bort en angiven host i OP5. Innan dess skapas ett Powershellskript i mappen C:\Users\%USERNAME%\AppData\Local\OP5HostManager\Restore-OP5Host. Detta skript återställer hosten till det läge den var i när den togs bort, och till samma miljö. Återställningsskriptet kan antingen köras direkt eller med hjälp av cmdleten Restore-OP5Host. Syntaxen är `Remove-OP5Host -Hostname "Namn på host" -OP5Environment "OP5 Test eller Prod"`. Exempel:
   ```powershell
   Remove-OP5Host -Hostname server01 -OP5Environment "Prod"
   ```
   <br>

   ### Restore-OP5Host ("Återställa borttagen host")

   Restore-OP5Host återställer en host som tagits bort med hjälp av cmdleten Remove-OP5Host. Hosten återställs till det stadie den var i när den togs bort och till den miljö den togs bort från. För att cmdleten ska fungera måste hostens återställningsskript finnas i C:\Users\%USERNAME%\AppData\Local\OP5HostManager\Restore-OP5Host. Återställningskripten följer formatet hostnamn_återställning.ps1. Syntaxen är `Restore-OP5Host -Hostname "Namn på host"`. Exempel:
   ```powershell
   Restore-OP5Host -Hostname server01
   ```
   <br>

   ### Copy-OP5Host ("Kopiera host från Prod till Test")

   Copy-OP5Host kopierar en host från den miljö du är i till den andra. Är du exempelvis i Test anger du en host som finns i Test, då kopieras den till Prod. Alla underliggande checkar kopieras också, samt checkar som ligger på hostgrupper som hosten är medlem i. Kontaktgrupper kopieras inte. Syntaxen är `Copy-OP5Host -Hostname "Namn på host" -OP5Environment "OP5 Test eller Prod"`. Exempel:
   ```powershell
   Copy-OP5Host -Hostname server01 -OP5Environment "Prod"
   ```
   Ovanstående exempel flyttar alltså hosten server01 från Prod till Test.
<br><br>

## Support

För buggrapporter och förbättringsförslag, [öppna ett issue i Gitlab.](https://gitlab.ltkalmar.se/oc/op5hostmanager/-/issues "Issue") Märk issuet med någon av labelarna "Bugg" eller "Förbättringsförslag".
