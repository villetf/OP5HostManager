## Detta skript är en del av OP5HostManager. Ett schemalagt jobb kör detta skript var 15 minut för att automatuppdatera OHM. Flytta inte detta skript.

Set-Location "C:\Users\$env:USERNAME\AppData\Local\OP5HostManager"
git pull