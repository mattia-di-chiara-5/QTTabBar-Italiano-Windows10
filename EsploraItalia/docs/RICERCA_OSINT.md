# Ricerca pubblica dei progetti — 17 ottobre 2026

## Metodo e limiti

Ricerca GitHub per nomi e argomenti (QTTabBar, WindowTabs, UnitedSets, file manager a schede, Windows), lettura dei repository ufficiali e dei requisiti, controllo metadati e licenze. Cinque query mirate hanno restituito 70 repository distinti prima della selezione; molti sono script, temi, applicazioni non Windows o risultati non pertinenti. Una prima ricerca generica conteneva rumore e non e stata usata per le conclusioni.

La selezione qui sotto confronta 16 progetti pertinenti o utili per distinguere gli approcci. Non e possibile garantire di aver censito tutti i repository GitHub. Stelle e data di un push non dimostrano qualita o sicurezza. Non sono stati eseguiti installer o script di terzi. Non si attribuiscono nuove vulnerabilita sulla sola base di una issue.

La lettura e piu approfondita per il codice locale QTTabBar, il clone WindowTabs e il clone Explorer++; per gli altri progetti copre documentazione, licenze, struttura e requisiti selezionati. Non e un audit completo del loro codice.

## Confronto

| Progetto ufficiale | Approccio / punti utili | Valutazione per questa esigenza |
| --- | --- | --- |
| [indiff/qttabbar](https://github.com/indiff/qttabbar) | Schede dentro Explorer; GPL-3.0 | Grande superficie storica, hook/UI Automation e serializzazione binaria; un errore vive nello stesso processo della Shell. Non e la base del nuovo nucleo. |
| [standard-software/WindowTabs](https://github.com/standard-software/WindowTabs) | Raggruppamento esterno di finestre; MIT; italiano e DPI | Soluzione interessante per mantenere le finestre originali. Sorgenti F#, dipendenze storiche e gestione generale di finestre/hook richiedono un'adozione piu ampia del compito. |
| [leafOfTree/WindowTabs](https://github.com/leafOfTree/WindowTabs) | Fork attivo del raggruppatore; MIT | Stessa famiglia architetturale; le schede esterne non eliminano i blocchi interni del singolo Explorer. |
| [payaneco/WindowTabs](https://github.com/payaneco/WindowTabs) | Base storica MIT | Utile per genealogia del progetto; ultimo push osservato nel 2019, preferibili i fork mantenuti per un'eventuale adozione. |
| [Windows-Apps-Hub/UnitedSets](https://github.com/Windows-Apps-Hub/UnitedSets) | Gruppi di finestre di applicazioni; MIT | Il README presenta una beta e segnala possibili problemi. Non si assume stabilita di produzione solo dall'aspetto grafico. |
| [derceg/explorerplusplus](https://github.com/derceg/explorerplusplus) | File manager nativo C++ a schede; GPL-3.0 | Alternativa matura e valida, buona fonte di riferimenti Shell. Potrebbe essere preferibile a una nuova app se serve subito un prodotto gia consolidato. Stack C++ e build vcpkg piu estesi. |
| [tablacus/TablacusExplorer](https://github.com/tablacus/TablacusExplorer) | Gestore nativo a schede con add-on; MIT; Windows 10 | Alternativa compatta e flessibile. Scripting e add-on ampliano funzioni e superficie da verificare. Non si conclude che sia lento o insicuro. |
| [files-community/Files](https://github.com/files-community/Files) | App moderna con multitasking, integrazioni e community; MIT | Riferimento importante per esperienza utente. Lo stack moderno e le numerose integrazioni richiedono una build e un audit piu ampi; non si deduce che supporti solo Windows 11. |
| [w4po/ExplorerTabUtility](https://github.com/w4po/ExplorerTabUtility) | Automazione delle schede native di Explorer; MIT | Richiede Windows 11 22H2/build 22621 o successivo: non aggiunge il controllo schede mancante in Windows 10. |
| [incom2/TabExplorer](https://github.com/incom2/TabExplorer) | Wrapper dichiarato della Shell nativa; MIT | Approccio vicino al requisito. Il materiale consultato non consente una revisione completa del sorgente del binario: nessuna garanzia di compatibilita totale assunta dal README. |
| [omeryanar/FileExplorer](https://github.com/omeryanar/FileExplorer) | App .NET 4.8, schede, vista ad albero, temi, menu personalizzati; MIT | Buona alternativa funzionale. La vista e un motore/interfaccia propri: non e il medesimo contenitore nativo isolato scelto qui. Prestazioni dichiarate dall'autore non misurate su questo PC. |
| [cairoshell/cairoshell](https://github.com/cairoshell/cairoshell) | Ambiente desktop alternativo; Apache-2.0 | Obiettivo piu ampio della navigazione a schede. Non introdurre un nuovo desktop per risolvere questo problema. |
| [aleksey-hoffman/sigma-file-manager](https://github.com/aleksey-hoffman/sigma-file-manager) | Versione 2, schede, split, estensioni, stack Tauri presente | Progetto ricco; il campo licenza dell'API risulta NOASSERTION, va letto il testo effettivo prima del riuso. Non e stato copiato codice. Non si descrive la versione attuale come un semplice progetto Electron sulla base dei topic storici. |
| [vanjac/chromafiler](https://github.com/vanjac/chromafiler) | Gestore spaziale nativo; GPL-3.0, Windows 7–11 | Idee interessanti per la navigazione. L'autore dichiara di non lavorarci piu attivamente; interazione a colonne differente dalle schede richieste. |
| [VioletGiraffe/file-commander](https://github.com/VioletGiraffe/file-commander) | Due pannelli, plug-in, C++23 e Qt 6.8+; Apache-2.0 | Valida famiglia alternativa, ma interfaccia e stack diversi dalla Shell nativa Windows scelta dall'utente. |
| [alexx2000/doublecmd](https://github.com/alexx2000/doublecmd) | Double Commander, due pannelli e multipiattaforma; GPL-2.0 | Soluzione esistente da considerare per produttivita. Non e un componente da incorporare alla cieca in un nuovo programma GPL v3. |

## Riferimenti fissati della lettura tecnica

- WindowTabs standard-software: `47acaefe1dd292ef1b2a91fad18727a2f9460853`.
- Explorer++: `adf72c76b883271427ba16c39f9d6f5011488a42`.
- Files: `6b721e819e4006670c5926325450fef9157aa6b4`.
- FileExplorer: `0be875d80e033b96a9b1d7c1f141595823ef29ee`.
- ChromaFiler: `bd022d33dc5d6ccbb4b784fb97277c3a79cb6aac`.
- File Commander: `8691b8665b36f0365affcf3e33c7ce9c739a4a65`.
- Double Commander: `8e06d85dd090ce1f97b5974590a13ca1b12a7221`.

## Decisione verificata con le prove

L'utente ha scelto un'app separata, dando priorita alla stabilita. Il prototipo di contenitore IExplorerBrowser con un processo per scheda e stato scartato: i primi conteggi non bastavano a verificarne la visibilita; aggiunto quel controllo e corretta la finestra figlia, il test di blocco ha rilevato attese della barra delle schede e un successivo blocco del collaudo. Non e stato installato o rilasciato come prodotto.

Il comportamento e coerente con il rischio di accoppiamento delle code di input delle finestre tra processi. Anche SWP_ASYNCWINDOWPOS e asincrono soltanto tra code diverse: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos. Non viene attribuita alla sola separazione dei processi una garanzia di reattivita della UI incorporata.

La base scelta per l'anteprima e Explorer++ 1.5.0.2844, senza modifiche al core. La sua pipeline ufficiale riuscita numero 35 corrisponde al commit `adf72c76b883271427ba16c39f9d6f5011488a42`; il calcolo del numero di build aggiunge 2809. Le attestazioni del binario e delle traduzioni sono state verificate imponendo quel commit. La build ufficiale e qui: https://github.com/derceg/explorerplusplus/actions/runs/36395179975.

La release stabile 1.4.0, confrontata anche attraverso i download del sito ufficiale e GitHub, ha incontrato problemi nelle prove locali. La 1.5 ha aperto la cartella accentata di 500 file e lo ZIP di 100 elementi. Essendo upstream una build di sviluppo, la confezione italiana resta esplicitamente un'anteprima. Nessuna conclusione di superiorita assoluta rispetto agli altri progetti.

Esplora Italia aggiunge 81 traduzioni dei menu, profilo rapido con icone Fluent e tema di sistema, installazione per utente e verifiche di provenienza/integrita. La DLL di risorse viene modificata tramite una mappa pubblica; il core mantiene il proprio nome, gli autori e la licenza GPL-3.0-only. Non viene presentato come software originale scritto interamente da zero.

Restano da approfondire un'anomalia di carico osservata anche prima delle interrogazioni esplicite UI Automation, il collaudo visivo, le operazioni reali di estrazione/copia, DPI misti e cartelle NAS. I test non certificano assenza di bug o sicurezza di tutti i progetti censiti.