# Verifica v0.4.0 del 2026-08-27

## Superato

- branch feature/italian-built-in sulla baseline 44a83bef;
- working tree sorgente conforme all'handoff;
- 42 chiavi italiane su 42;
- 489 segmenti su 489;
- parità placeholder e segmenti vuoti;
- SHA-256 RESX:
  C0AB7A24941DD212015C5E60CF8AD870F69C4BBF686F789AEDF899CE3070D393;
- build QTTabBar Release Any CPU senza errori;
- bin e obj della build byte-identici;
- audit ILDASM no-loader della RC1;
- risorsa Resources_String_it_IT.resources presente;
- ResourceManager e Version_LangFile presenti;
- proprietà spuriosa Language assente;
- snapshot Stage 4.0.2 completo;
- pacchetto offline creato e verificato file per file;
- sintassi di tutti gli script PowerShell verificata;
- protezione anti-ricorsione UAC verificata.
- strong-name della RC1 verificata con sn.exe;
- installer senza chiamate di rete e con hash DLL/MSI obbligatori;
- staging amministrativo contro sostituzioni tra controllo hash e uso;
- mutex globale contro installazione/ripristino simultanei;
- ACL di stato limitata a Administrators e SYSTEM;
- rollback vincolato all'hash esatto della baseline e a un solo backup della
  chiave HKCU\Software\QTTabBar\Config\Lang;
- workflow GitHub con permessi read-only e action fissata a commit.

## RC1 congelata per la release

QTTabBar.dll:

77F1351E8672FD5C8EBDC49C9A28E4D66EA267BC7FF8B2BF872AADD62EBA7B36

Il compilatore legacy non produce hash riproducibili tra build successive a
causa dei metadati di build. La release usa quindi la RC1 congelata già
auditata, non la DLL generata da un rebuild successivo.

## Test runtime Windows 10

Superato il 2026-08-27 su Windows 10 Pro x64 22H2 build 19045:

- installazione UAC completata con log persistente;
- GAC uguale alla RC1 congelata;
- Explorer carica fisicamente la stessa QTTabBar.dll;
- processo Explorer rispondente;
- lingua integrata impostata su Italiano, indice 8, file XML disattivato;
- nessun evento crash Explorer/QTTabBar 1000, 1001 o 1026 dopo l'installazione;
- backup di rollback presente e uguale alla baseline originale.

Il ripristino modifica GAC, registro ed Explorer e richiede UAC. La release
contiene controlli preventivi e rollback automatico; la procedura resta
documentata in GITHUB_PASSO_PASSO.md.

## Limiti dichiarati

- RC1 strong-name valida ma non firmata Authenticode;
- Windows Defender è disattivato perché sul PC di prova è attivo Avast 26.7;
  i servizi Avast e la protezione in tempo reale risultano attivi, ma non è
  stato registrato un report di scansione on-demand esportabile.

## Asset definitivo

QTTabBar-Italiano-Windows10-v0.4.0.zip

    D31D917E3C41342F27D24E7310C82700567D162FADD8EF4B564F416B2C79B221

Dimensione: 2.044.074 byte. Il manifesto interno contiene otto file e tutti gli
hash sono stati ricalcolati dopo l'estrazione con esito positivo.
