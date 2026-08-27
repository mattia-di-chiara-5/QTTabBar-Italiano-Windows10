# QTTabBar Italiano per Windows 10

Questa directory contiene il livello italiano della linea v0.4.0.

- installer/: installazione, migrazione e rollback;
- tools/: snapshot, validazione risorse e creazione asset offline;
- release/: note di rilascio.

La lingua italiana è incorporata in QTTabBar.dll; il vecchio XML v0.3 non è
necessario. La sorgente resta ancorata al commit upstream
44a83bef8cdf5fb67c6d7f6434821c6f602542e7.

## Validazione rapida

Da PowerShell:

    .\Italiano\tools\Test-ItalianResources.ps1

## Build della DLL

Da PowerShell:

    & "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" '.\QTTabBar Rebirth.sln' /t:QTTabBar:Rebuild /p:Configuration=Release '/p:Platform=Any CPU' /nologo

Per l'audit fisico usare hash e ILDASM sul file esatto, non Assembly.Load.
