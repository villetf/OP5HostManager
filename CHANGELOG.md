# Changelog

Alla ändringar kommer antecknas i denna fil.

## [1.3.0] - 2024-06-19

### Added

- Lade till att om man försöker lägga till en kontakt/servicegrupp som inte finns så får man upp en lista över liknande grupper.
- Lade till att om hostnamnet inte finns i DNS:en när man ska lägga upp får man alternativet att manuellt ange IP eller hostnamn.

### Changed

- Det är nu möjligt att lägga upp hostar med upp till 24 diskar (från C fram till Z).
- Lagt till kommentarer och slagit ihop funktioner.

### Fixed

- Fixade buggen som gjorde att man inte fick spara sina ändringar.

## [1.2.7] - 2024-03-22

### Fixed

- Fixade buggen som gjorde att när man lägger upp en ny Linuxhost fick man inte bekräfta sina ändringar
- Fixade buggen som gjorde att bara en host visades i webbläsaren när man lade upp flera nya hostar.

## [1.2.6] - 2024-02-28

### Added

- Lade till så att man kan lägga upp och ta bort flera hostar på samma gång genom att separera dem med kommatecken. (Issue #11)

### Changed

- Förbättrad felhantering om kommandon saknas i mottagarmiljön när man använder Copy-OP5Host. (Issue #9)
- Sparade autentiseringsuppgifter kontrolleras nu att de fungerar i varje körning.

### Fixed

- Fixade problemet med att OHM avslutades om man försökte spara samtidigt som någon annan. (Issue #12)

## [1.2.5] - 2024-01-11

### Changed

- Inloggningsuppgifter sparas nu som en krypterad XML, vilket gör att man inte behöver skriva in inloggningsuppgifter efter första gången.

## [1.2.4] - 2023-12-08

### Added

- Lade till loggning till Log4CjS.

## [1.2.3] - 2023-09-08

### Fixed

- Fixade så att Windows Updates-skripten får rätt argument, vilket det inte fick tidigare.

## [1.2.2] - 2023-09-06

### Changed

- Förbättrade felhanteringen gällande autentiseringsuppgifter, så om man skriver fel nu får man direkt försöka igen istället för att kommandot avslutas.
- Förbättrade felhanteringen gällande om man skriver ett felaktigt hostnamn, vilket gjorde det mindre missvisande.
- När man använder Edit-OP5 och är klar med en uppgift återgår den nu till Edit-OP5 istället för att avsluta.
- Bröt ut kontroll av autentiseringuppgifter i en egen funktion för att förbättra kodens läsbarhet.
- Bröt ut API-anrop vid uppläggning av host till egen funktion, vilket förkortar koden och ökar läsbarheten.

## [1.2.1] - 2023-09-05

### Changed

- När man ska granska en sparning visas nu även länk till vilken miljö man är i.
- När man kör OHM-genvägen och en funktion avslutas kommer man tillbaka till en powershellterminal istället för att fönstret stängs ner.

### Fixed

- Fixade buggen som gjorde att miljö inte byttes när man försökte byta miljö i Edit-OP5.
- Fixade buggen som gjorde att vissa hostnamn felaktigt blev omvandlad till stora bokstäver.

## [1.2.0] - 2023-08-15

### Added

- OS Updates-check i Add-OP5LinuxHost.
- Windows Updates-check i Add-OP5WindowsHost.
- Kommentarer i koden som kan användas för att förstå och navigera i koden.

### Changed

- Bytte namn på alla checkar till gällande namnstandard.
- Förbättrade kodens läsbarhet genom att bryta ut felhanteringen till en egen funktion.

### Removed

- Swap-checken i Add-OP5LinuxHost, i enlighet med gällande beslut.

## [1.1.1] - 2023-06-07

### Fixed

- Fixade bugg som gjorde att Restore-OP5Host failade före sparning.
- Restore-OP5Host gör nu en git pull före sparning av backupskript för att undvika konflikter med existerande commits.

## [1.1.0] - 2023-05-31

### Added

- Modulmanifest som gör att man kan få info om modulen, t ex versionsnummer genom Get-Module OP5HostManager.
- Aliasen "ohm" som kör Edit-OP5, "ohmwin" som kör Add-OP5WindowsHost, och "ohmlin" som kör Add-OP5LinuxHost.
- Edit-OP5 sparar nu vilken miljö man var i sist och använder det när kommandot körs igen. (Issue #4)
- Edit-OP5 har nu "Avsluta" som ett alternativ.

### Changed

- Färgkodningen är nu röd för Prod och grön för Test istället för tvärtom. (Issue #2)
- Move-OP5Host heter nu Copy-OP5Host för att vara mer korrekt. (Issue #3)
- Inloggningsuppgifter sparas nu som en krypterad global variabel vilket gör att man inte behöver skriva in lösenord igen om man använder flera funktioner i samma Powershellsession.
- Copy-OP5Host kontrollerar nu vilka kontaktgrupper, servicegrupper, hostgrupper och checkkommandon som finns på målservern och tar bort de som inte finns från anropet. (Issue #6)  

## [1.0.1] - 2023-05-23

### Fixed

- Fixade buggen som gjorde att hostar som innehöll ÅÄÖ inte kunde läggas upp.

### Changed

- Tog bort att swapchecken läggs på linuxservrar i Add-OP5LinuxHost.

## [1.0.0] - 2023-05-08

### Added 

- Add-OP5WindowsHost lägger upp en host i OP5 med standardcheckarna för Windows.
- Add-OP5LinuxHost lägger upp en host i OP5 med standardcheckarna för Linux.
- Remove-OP5Host som tar bort en host i OP5 och skapar skript för återställning.
- Restore-OP5Host som återställer en host som tagits bort med hjälp av cmdleten Remove-OP5Host.
- Move-OP5Host kopierar en host från den miljö du är i till den andra.
- Edit-OP5 som visar en lista där man kan välja mellan de olika funktioner som finns i OP5HostManager.