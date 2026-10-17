# Esplora Italia — anteprima 0.1.0

Un pacchetto italiano di **Explorer++**, con schede, icone Fluent, tema di sistema e un profilo che privilegia la velocita. E un'app separata da Esplora file di Windows 10. Il motore resta quello del progetto Explorer++, creato da David Erceg e collaboratori.

Questa edizione completa 81 stringhe dei nuovi menu rimaste in inglese nella traduzione ufficiale e prepara installazione per utente, controlli di integrita e documentazione italiana. Non viene presentata come un nuovo motore scritto da zero.

## Installazione e uso

Richiede Windows 10 x64. Scaricare lo ZIP dalla release **esplora-it-v0.1.0-preview**, verificarne lo SHA-256 pubblicato, estrarre tutto in una cartella e avviare `Explorer++.exe`. La configurazione e portabile e deve restare accanto all'eseguibile.

Lo script facoltativo `INSTALLA.ps1 -DesktopShortcut`, eseguito dalla cartella estratta, copia i file in `%LOCALAPPDATA%\Programs\EsploraItalia\0.1.0-preview` e crea il collegamento **Esplora Italia** nel menu Start e sul desktop. Non richiede diritti di amministratore. Il collegamento imposta lingua italiana e cartella di lavoro corretta. Il primo avvio dopo l'installazione apre la cartella personale; le installazioni successive conservano le preferenze esistenti.

Non registra DLL in Explorer, non sostituisce associazioni o Win+E, non imposta avvio automatico e non disinstalla QTTabBar. Il vecchio Explorer con QTTabBar resta distinto: per provare questa soluzione usare il nuovo collegamento.

| Comando | Uso |
| --- | --- |
| Ctrl+T | Nuova scheda |
| Ctrl+W | Chiudi scheda |
| Ctrl+Tab | Scheda successiva |
| Ctrl+L | Scrivi il percorso |
| Ctrl+D | Crea un segnalibro |
| Ctrl+C / Ctrl+V | Copia e incolla attraverso la Shell |
| F5 | Aggiorna |
| Strumenti > Opzioni | Tema, caratteri e preferenze |

Per disinstallare: chiudere l'app, rimuovere la cartella della versione e i relativi collegamenti. Conservare `config.xml` se si vogliono mantenere segnalibri e preferenze. Il file contiene percorsi in chiaro: trattarlo come dato personale e non pubblicarlo.

## Profilo rapido

Vista dettagli, estensioni visibili, icone Fluent e tema di Windows. Anteprime, suggerimenti automatici, miniature della barra applicazioni e calcolo ricorsivo delle dimensioni sono disabilitati. Anche l'albero laterale e la sua sincronizzazione sono inizialmente disattivati; si possono riattivare dalle opzioni. Le condivisioni non vengono riaperte automaticamente all'avvio. Le operazioni native e i menu contestuali restano disponibili.

L'isolamento e tra **l'app e il desktop**. Le schede appartengono allo stesso processo: un provider lento puo far attendere l'app, ma il programma non viene caricato dentro `explorer.exe`. Non si promettono assenza di blocchi o prestazioni identiche su qualsiasi NAS o estensione.

## Versione e provenienza

Core upstream **1.5.0.2844**, build di sviluppo pubblicata il 28 settembre 2026, commit `adf72c76b883271427ba16c39f9d6f5011488a42`. E una build preliminare upstream, non la release stabile 1.4.0. La 1.4.0 ha incontrato problemi nelle prove locali con percorsi accentati; la 1.5 ha aperto la cartella di 500 file e lo ZIP di 100 elementi.

Le attestazioni Sigstore dei due archivi ufficiali sono state verificate con GitHub CLI, imponendo repository, workflow, commit e runner GitHub. L'eseguibile e identico al core attestato. La DLL italiana parte dall'archivio ufficiale attestato ed e modificata solo nelle risorse testuali, con verifica del contenuto precedente e successivo: la DLL modificata non eredita l'attestazione dell'originale. I sorgenti e la mappa delle modifiche sono inclusi o pubblicati con la release.

Il pacchetto e l'eseguibile non hanno firma Authenticode. Provenienza attestata non significa assenza di vulnerabilita o certificazione normativa. Leggere `SICUREZZA.md`, `RICERCA_OSINT.md`, `ORIGINE.json` e `SHA256SUMS.json`.

Il collaudo con UI Automation ha prodotto un'anomalia di CPU in un'istanza; una nuova istanza senza interrogazioni di accessibilita ha mostrato 0% di un core nel campione breve a riposo. Il risultato non e un benchmark generale e la causa dell'anomalia non e stata accertata. Il rilascio resta un'anteprima da collaudare sul proprio sistema.

## Build del pacchetto

Dalla radice del repository, con GitHub CLI autenticato e .NET Framework 4.8 disponibile:

```powershell
.\EsploraItalia\scripts\Build-Package.ps1
```

La procedura scarica soltanto input bloccati da hash, verifica le attestazioni, compila il piccolo localizzatore di risorse e controlla il pacchetto. Non ricompila il core C++: il suo sorgente corrispondente e incluso nello ZIP; la build C++ upstream richiede Visual Studio e vcpkg, come descritto nel suo BUILDING.md. La release contiene anche la sorgente del localizzatore e la mappa italiana.

Licenza GPL-3.0-only per il core e gli strumenti di questa edizione. Autori e licenze originali sono conservati. Non e un prodotto Microsoft e non e la versione ufficiale italiana del progetto Explorer++.
Il manifest descrive i file iniziali. `config.xml` cambia durante l'uso; l'installatore usa il modello immutabile `PROFILO-RAPIDO.xml` e conserva il file personale gia installato.