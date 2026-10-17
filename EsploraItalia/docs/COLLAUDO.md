# Collaudo dell'anteprima 0.2.0

Data: 17 ottobre 2026. Ambiente: Windows 10 x64. Core corretto basato su Explorer++ 1.5.0.2844, SHA-256 `60DB6409C66282B6545DD83B115A37AEDDA43C16EF77809377C78F96E569E1BB`. Edizione italiana preliminare, non un benchmark comparativo completo.

| Prova | Esito osservato |
| --- | --- |
| Provenienza degli ZIP ufficiali | Attestazioni Sigstore verificate imponendo repository, workflow, commit e runner ospitati GitHub |
| Integrita del pacchetto | 19 file nel manifest; hash, versione core e profilo controllati |
| Compatibilita Windows PowerShell 5.1 | Build e controlli eseguiti; corretta la lettura degli array JSON |
| Traduzione | 81 stringhe modificate e rilette; menu principali italiani osservati nella UI accessibile |
| Input non valido al localizzatore | Rifiutati testo precedente errato, ID duplicati, PE troncato e sovrascrittura della sorgente |
| Cartella con caratteri accentati | 500 elementi elencati |
| Schede e tastiera | Due schede, cambio scheda e selezione osservati; riscontro manuale di normale risposta |
| ZIP con caratteri accentati | 100 elementi elencati; estrazione completa tramite la GUI ancora da collaudare |
| CPU a riposo dopo uso manuale | 0% di un core in entrambe le istanze nel campione di tre secondi; non e un valore garantito |
| Memoria nelle due istanze finali | Circa 21 e 124 MiB; configurazioni/stati diversi, nessuna conclusione comparativa |
| Anomalia nel collaudo automatico | Carico elevato in campioni precedenti, stack del thread principale in App::Run/GetMessageW. Causa non accertata |
| Verifica visiva automatica | Non conclusa: cattura con timeout; alcuni input automatici non hanno ricevuto il focus |
| Installazione per utente | La 0.1 ha verificato 14 file immutabili dopo copia; la 0.2 ne prevede 18, configurazione personale distinta dal modello |

## Perimetro della sicurezza

L'analisi CodeQL C# e le build di regressione sono controlli utili, non un audit completo del core C++. Nel codice QTTabBar storico rimane una segnalazione di deserializzazione non sicura (`cs/unsafe-deserialization-untrusted-input`); Esplora Italia non importa quel formato e non carica QTTabBar. Non viene dichiarata risolta la segnalazione nel vecchio componente.

Vedere anche [sicurezza e limiti](SICUREZZA.md), [ricerca di 16 progetti](RICERCA_OSINT.md) e [dipendenze dichiarate](DIPENDENZE.md). L'elenco delle dipendenze non e uno SBOM completo e la ricerca non dimostra l'assenza di CVE.

## Prova della correzione nativa

La build del core corretto ha superato 864 test nativi, zero errori e zero test disabilitati, in circa 6,6 secondi. Il gruppo ComStaThreadPoolExecutorTest contiene quattro test riusciti e include i 64 cicli aggiunti di costruzione/esecuzione/arresto. Gli eventi del pool COM vengono creati prima dei worker e WAIT_FAILED viene controllato. Core e attestazione provengono dalla build 39039770214 del repository di questa edizione. La GUI del core corretto ha elencato 500 file e 100 elementi ZIP; il primo campione locale ha mostrato carico elevato sulla cartella e zero sullo ZIP, senza dimostrare una causa. La patch non viene presentata come soluzione dimostrata al carico del thread principale.

## Prove ancora necessarie

Copia, spostamento e intera estrazione ZIP attraverso la GUI; NAS irraggiungibili o lenti; centinaia di migliaia di file; DPI misti e screen reader; sessioni prolungate; estensioni Shell di terze parti. Non usare la sola apertura dei 100 elementi come prova di estrazione riuscita. Non sono state disabilitate protezioni del sistema per ottenere i risultati.