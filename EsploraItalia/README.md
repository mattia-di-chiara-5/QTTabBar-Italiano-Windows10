# Esplora Italia — anteprima 0.2.0

File manager nativo a schede per Windows 10 x64, basato su **Explorer++ 1.5.0.2844**, creato da David Erceg e collaboratori. E un'app separata da Esplora file: usa icone Fluent, tema di sistema e un profilo che privilegia la velocita. Autori e licenze originali sono conservati.

Questa edizione completa 81 stringhe italiane dei menu, corregge l'avvio del pool COM nel core e prepara installazione per utente e verifiche di provenienza. Il core corretto ha superato **864 test nativi, zero errori**, incluso lo stress test aggiunto di 64 costruzioni/esecuzioni/arresti. Non viene presentato come un motore originale scritto da zero o come software privo di bug.

## Installazione

Scaricare `EsploraItalia-Windows10-x64-v0.2.0-preview.zip` dalla release **esplora-it-v0.2.0-preview**, confrontare lo SHA-256 pubblicato ed estrarre tutti i file. Avviare `Explorer++.exe`: la configurazione portabile resta accanto all'eseguibile.

Lo script facoltativo `INSTALLA.ps1 -DesktopShortcut` installa in `%LOCALAPPDATA%\Programs\EsploraItalia\0.2.0-preview` e crea **Esplora Italia** nel menu Start e sul desktop. Non richiede diritti amministrativi. Il primo avvio apre la cartella personale; reinstallando la stessa versione viene conservato il suo `config.xml`. Le cartelle di versioni precedenti non vengono rimosse. Il collegamento imposta lingua italiana e cartella di lavoro corretta.

L'edizione non aggiunge DLL a Explorer, associazioni predefinite, intercettazione di Win+E, servizi o avvio automatico. QTTabBar gia installato resta distinto: usare il nuovo collegamento per provare questa app.

| Comando | Uso |
| --- | --- |
| Ctrl+T / Ctrl+W | Apre / chiude una scheda |
| Ctrl+Tab | Scheda successiva |
| Ctrl+L | Scrivi il percorso |
| Ctrl+D | Crea un segnalibro |
| Ctrl+C / Ctrl+V | Copia e incolla attraverso la Shell |
| F5 | Aggiorna |
| Strumenti > Opzioni | Tema, caratteri e preferenze |

Per disinstallare, chiudere l'app e rimuovere cartella della versione e collegamenti. Conservare `config.xml` per mantenere segnalibri e preferenze. Contiene percorsi in chiaro: non pubblicarlo.

## Profilo rapido e isolamento

Vista dettagli, estensioni visibili, icone Fluent e tema di Windows. Anteprime, suggerimenti automatici, miniature della barra applicazioni e calcolo ricorsivo delle dimensioni disabilitati. Albero laterale e sincronizzazione inizialmente disattivati, riattivabili dalle opzioni. Le condivisioni non vengono riaperte automaticamente all'avvio.

Le schede condividono il processo dell'app. Un provider lento puo ancora far attendere l'app; il programma non viene caricato dentro `explorer.exe`. Non e un sandbox di sicurezza e non garantisce prestazioni identiche su ogni NAS o estensione.

## Correzione e provenienza

Base upstream: commit `adf72c76b883271427ba16c39f9d6f5011488a42`, build di sviluppo 1.5.0.2844. Gli eventi del pool COM vengono ora creati prima dei thread che li usano; WAIT_FAILED termina esplicitamente l'app anziche lasciare proseguire il ciclo. Questa e una correzione di inizializzazione, non una soluzione dimostrata all'anomalia del thread principale osservata nel collaudo automatico.

Il core viene compilato dalla pipeline di questo repository; la sua attestazione Sigstore viene verificata separatamente da quelle degli archivi ufficiali upstream. Versione base, hash del core, workflow, commit di build e test sono fissati in `ORIGINE.json`. La DLL italiana deriva dall'archivio ufficiale attestato ed e modificata solo nelle risorse testuali, con verifica prima e dopo la scrittura. La DLL modificata non eredita l'attestazione dell'originale.

Il pacchetto non ha firma Authenticode. Provenienza attestata non significa assenza di vulnerabilita o certificazione normativa. Sono inclusi sorgenti upstream, `CORE-FIXES.patch`, `TEST-NATIVI.xml`, codice del localizzatore e mappa italiana. Script della build nativa e relativi vincoli sono pubblicati nella cartella `native` del repository.

Leggere `COLLAUDO.md`, `SICUREZZA.md`, `DIPENDENZE.md` e `RICERCA_OSINT.md`. La GUI ha elencato 500 file in una cartella accentata e 100 elementi in uno ZIP. La versione 0.1 con core ufficiale ha ricevuto un riscontro manuale di uso fluido. Le misure a riposo sono variabili: campioni a zero CPU e picchi nel collaudo automatico, con causa non accertata. Catture grafiche automatiche e intera estrazione ZIP non sono ancora collaudate completamente. Resta un'anteprima.

## Build

Con GitHub CLI autenticato e .NET Framework 4.8, dalla radice del repository:

```powershell
.\EsploraItalia\scripts\Build-Package.ps1
```

La procedura verifica input bloccati da hash, tre attestazioni, localizzazione e pacchetto. Recupera il core corretto dalla build fissata; non lo ricompila localmente. Per ricompilarlo con Visual Studio e vcpkg:

```powershell
.\EsploraItalia\native\Build-Core.ps1 -SourceDirectory C:\Build\explorer-source -OutputDirectory C:\Build\native-output
```

La directory sorgente deve essere nuova. Una ricompilazione non e garantita identica byte per byte alla pipeline; non sostituire arbitrariamente gli hash nel lock file.

Licenza GPL-3.0-only per core e strumenti di questa edizione. Non e un prodotto Microsoft o una release ufficiale del progetto Explorer++. Il manifest descrive i file iniziali; `config.xml` cambia durante l'uso. L'installatore usa il modello immutabile `PROFILO-RAPIDO.xml` per una nuova installazione e conserva il file personale gia presente.