# Sicurezza e privacy — 17 ottobre 2026

## Perimetro ed esito

Esplora Italia 0.2.0 e un pacchetto preliminare di Explorer++ 1.5.0.2844 con profilo rapido e integrazione della traduzione italiana. Non e una certificazione di sicurezza, un penetration test indipendente o una promessa di assenza di bug. Non viene dichiarato pronto per ogni impiego professionale.

La revisione copre provenienza del core, codice degli strumenti di confezionamento/installazione, modifica delle risorse testuali, impostazioni di prestazioni e parti selezionate del codice upstream. Non copre tutto il codice C++, le librerie di sistema o ogni estensione presente sul computer.

## Provenienza e modifiche

Gli archivi ufficiali sono bloccati da SHA-256. Le attestazioni sono verificate con `gh attestation verify`, imponendo repository `derceg/explorerplusplus`, workflow `.github/workflows/build.yml`, commit `adf72c76b883271427ba16c39f9d6f5011488a42` e runner ospitati da GitHub. La pipeline ufficiale e disponibile su https://github.com/derceg/explorerplusplus/actions/runs/36395179975.

Il core `Explorer++.exe` e ricompilato con eventi del pool COM creati prima dei worker e controllo WAIT_FAILED. Ha superato 864 test senza errori. La sua attestazione separata impone il repository di questa edizione, il workflow esplora-native.yml e il commit 895c39b5e985cfaf9e27c457094fa0990bb4a37e. Build riuscita: https://github.com/mattia-di-chiara-5/QTTabBar-Italiano-Windows10/actions/runs/39039770214. Hash del core, patch e test sono nel lock file. Il nuovo core non eredita l'attestazione upstream. La DLL italiana originale proviene dall'archivio attestato; il localizzatore ammette solo DLL con dimensione del codice ed entry point pari a zero. Prima di cambiare un blocco di stringhe controlla ogni testo originale previsto; dopo la scrittura rilegge ogni traduzione. Non aggiunge codice eseguibile. Il nuovo hash e elencato nel manifest. L'attestazione dell'archivio originale non costituisce una firma della DLL modificata o dell'intero pacchetto.

Il pacchetto non ha firma Authenticode. Gli hash garantiscono corrispondenza rispetto ai valori pubblicati, non certificano da soli un editore o l'assenza di malware. La provenienza attestata identifica una pipeline: non dimostra che il codice non contenga vulnerabilita.

Il pacchetto include sorgenti upstream del commit dichiarato, patch C++, risultati dei test, testo della licenza, attribuzioni, sorgente del localizzatore e mappa delle modifiche. Gli script corrispondenti di compilazione sono nella cartella native del repository. Il core e distribuito sotto GPL-3.0-only; la compilazione C++ e le dipendenze vcpkg restano documentate dal progetto upstream. Nessuna libreria QTTabBar e incorporata.

## Installazione e privilegi

Installazione nella cartella dell'utente, controllo dei file prima della copia, destinazione fissa, elenco chiuso dei nomi ammessi e verifica delle copie. Una versione preesistente differente viene rifiutata; la configurazione esistente e conservata. Nessuna disinstallazione automatica, riavvio di Explorer, associazione predefinita, servizio, hook globale, attivita pianificata o avvio automatico aggiunti da questa edizione.

Avviare normalmente dall'account utente: l'app non richiede elevazione. Se avviata da un processo amministrativo puo ereditarne i privilegi. Le estensioni della Shell eventualmente caricate operano nel contesto dell'app. Un'app separata limita alcuni effetti sul desktop, ma non e un sandbox.

## Dati, rete e funzionalita upstream

`config.xml` contiene preferenze, segnalibri, percorsi e dati di navigazione in chiaro. Non e cifrato con DPAPI. Non distribuire il proprio file di configurazione, log o dump contenenti dati personali. Il profilo non riapre automaticamente la sessione precedente; l'utente puo modificarlo dalle opzioni.

Il confezionamento non aggiunge telemetria, account o un server. Navigazione SMB, provider cloud, aggiornamenti richiesti dal menu, file aperti e funzioni upstream possono comunicare in rete secondo le proprie impostazioni. I plug-in Lua upstream non vengono abilitati dal collegamento di questa edizione. I menu possono avviare programmi e script su richiesta dell'utente, come in un file manager completo.

## Risultati e limiti delle prove

Sono stati osservati su Windows 10: avvio con percorso accentato, 500 elementi nella cartella locale, due schede, ZIP di 100 elementi, cambio scheda e selezione da tastiera. Una misura breve su nuova istanza senza interrogazioni di accessibilita ha mostrato 0% di un core a riposo e circa 49 MiB; non e un benchmark generale.

Altre istanze hanno mostrato consumo persistente vicino a un core, anche prima delle interrogazioni esplicite UI Automation. Il thread principale campionato ricade in App::Run/GetMessageW; i thread del pool restano quasi inattivi. La causa non e stata accertata e non viene attribuita all'antivirus sulla sola presenza di suoi moduli. Le catture Windows.Graphics.Capture sono terminate in timeout: il collaudo visivo automatizzato completo non e concluso. Non sono certificati screen reader, DPI misti, NAS lenti, sessioni lunghe, tutte le copie o tutte le estrazioni. Esaminare queste limitazioni prima di usare l'anteprima per attivita importanti.

La versione stabile upstream 1.4.0 ha incontrato crash e mancata risposta nelle prove locali; la build 1.5 selezionata ha superato l'apertura degli stessi tipi di dati. Questo non dimostra che tutti i difetti della 1.4 siano risolti o che la 1.5 sia una release stabile.

## Debito del componente precedente

Nel codice legacy QTTabBar, `QTUtility2.ReadRegBinary<T>` e `QTUtility.ByteArrayToObject` usano BinaryFormatter. Microsoft considera il formato insicuro con input non fidati anche con binder. L'esposizione concreta dipende da chi puo modificare i dati e dai privilegi; non e stato dimostrato un exploit remoto. Il problema non e dichiarato risolto nella DLL legacy. Esplora Italia non collega quel codice e non importa il relativo stato binario.

Riferimento: https://learn.microsoft.com/dotnet/standard/serialization/binaryformatter-security-guide.

CVE-2023-54334 descrive Explorer32++ 1.3.5.531. Il record non e una prova che la versione 1.5 sia vulnerabile o esente da vulnerabilita: https://www.cve.org/CVERecord?id=CVE-2023-54334. Non viene distribuita la vecchia 1.3.5.

## Sistema operativo e conformita

Windows 10 ha terminato il supporto ordinario il 14 ottobre 2025. Nel 2026 occorre verificare attivazione/applicabilita degli aggiornamenti estesi e patch effettivamente installate. Una nuova app non compensa un sistema operativo non aggiornato. Fonti Microsoft: https://learn.microsoft.com/en-us/windows/release-health/release-information e https://support.microsoft.com/en-us/windows/deployment/updates-lifecycle/windows-10-support-has-ended-on-october-14-2025.

Non si dichiara una certificazione GDPR, ISO 27001 o una conformita normativa generale. Licenze, contesto d'impiego, accessi ai file, conservazione e responsabilita organizzative richiedono valutazioni specifiche. Questa documentazione rende esplicite condizioni e limiti; non e un parere legale.
Il localizzatore viene inoltre provato con testo originale incompatibile, ID duplicati, immagine troncata e tentativo di sovrascrivere la sorgente. Questi input sono rifiutati; gli originali restano invariati. Le prove girano anche in Windows PowerShell 5.1.

Il baseline dichiara Lua 5.4.8, per cui sono state pubblicate correzioni successive in Lua 5.4.9. Non e stato completato un audit di tutte le dipendenze: vedere DIPENDENZE.md. La patch al pool COM non aggiorna Lua. I plug-in non vengono abilitati dal collegamento.
