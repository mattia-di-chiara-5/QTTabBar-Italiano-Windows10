# Revisione di sicurezza QTTabBar Italiano 0.7.0 — 2–3 novembre 2026

Questa revisione riguarda QTTabBar, l'estensione caricata in Explorer, e i relativi sorgenti, plug-in, installer e workflow. Esplora Italia e un'app separata e non viene sostituita da questo aggiornamento. Non si dichiara una certificazione di sicurezza, conformita normativa o assenza di vulnerabilita.

## Metodo e perimetro

Inventario dell'intero repository; scansione dei sorgenti C# per serializer pericolosi; revisione manuale delle superfici IPC, stato persistente, Memo, aggiornamenti e build; regressioni sul candidato isolato; CodeQL C# e C/C++. I file decompilati o non elencati nei progetti non sono tutti codice eseguito: l'analisi automatica e la revisione dei punti esposti non equivalgono alla lettura manuale di ogni riga o a un penetration test indipendente. I binari di terze parti e le estensioni Shell esterne restano fuori da una revisione completa del loro codice macchina.

Due file legacy GBK/936 sono stati convertiti in UTF-8 preservando i testi originali. La versione CLR resta 1.6.3.0 per l'identita COM; FileVersion e 1.6.3.8 e l'edizione italiana e 0.7.0. Il pacchetto MSI usa un nuovo ProductCode e ProductVersion 1.6.7.

## Correzioni

- Rimosse le invocazioni esplicite a BinaryFormatter dal core e dal plug-in Memo. Eliminati il wrapper che ricostruiva delegati tramite reflection e il binder che pretendeva di rendere sicuro il formato. Microsoft precisa che un binder non elimina quel rischio: https://learn.microsoft.com/dotnet/standard/serialization/binaryformatter-security-guide.
- IPC V2: contratto chiuso di comandi e dati primitivi, nessun metodo/tipo/delegato scelto dal messaggio. JSON con UTF-8 rigoroso, limiti di byte, profondita, numero e lunghezza delle stringhe, validazione dell'intero documento e rifiuto di radici aggiuntive. Comandi ammessi distinti per server, processo principale e broadcast.
- Named pipe con sicurezza di trasporto Windows, autorizzazione dello stesso SID, endpoint separato dal protocollo vecchio e nessun endpoint creato da Explorer elevato. Quote e timeout limitati; inizializzazione asincrona con guardia contro avvii sovrapposti. Il servizio resta rientrante per supportare i callback WCF e usa una sola istanza.
- Il callback non chiude piu il canale dopo ogni comando. Il trasferimento viene preso in carico prima di consentire la chiusura della finestra sorgente; se fallisce, la finestra viene inizializzata normalmente. Una connessione ancora assente non e considerata prova che esista una finestra destinataria.
- Le schede bloccate usano REG_MULTI_SZ versionato, conservando Unicode e punti e virgola; array vuoti non ripristinano il vecchio stato. I vecchi valori binari sono conservati ma non deserializzati. E disponibile il ripiego sul vecchio valore testuale TabsLocked2, che era gia ambiguo per percorsi contenenti punti e virgola.
- La copia delle opzioni lavora soltanto sul Config vivo nel processo: categorie, font, liste, dizionari e array vengono copiati senza passare da un oggetto serializzato.
- Memo usa un documento XML tipizzato e versionato, senza DTD o resolver, con limiti di dimensione e oggetti. Scrittura limitata anche durante la serializzazione, sostituzione atomica e copia .bak. Un archivio illeggibile non viene sovrascritto con dati vuoti. I collegamenti cliccabili ammettono solo HTTP, HTTPS e mailto.
- Il controllo aggiornamenti automatico non apre piu il browser all'avvio. La pagina delle release viene aperta solo su richiesta esplicita.
- Rimosso un logger C++ inutilizzato che passava una std::wstring a una conversione printf per stringhe C e poteva lasciare un handle aperto. Eliminata da DllMain una costruzione inutilizzata del nome del processo che poteva generare un'eccezione su percorsi corti o conversioni non ASCII. Le DLL native vengono compilate esplicitamente per entrambe le architetture e caricate in processi di prova separati senza inizializzare gli hook.

## Aggiornamenti verificati

System.Text.Encoding.CodePages 10.0.14 e UTF.Unknown 2.8.0 sostituiscono 10.0.12 e 2.7.0; i test verificano il caricamento incorporato e la compatibilita con le identita precedenti. Rimossi Fody, Hotfix.Fody.Pdb, PropertyChanged.Fody e Virtuosity.Fody dal restore: non sono referenziati dai progetti attivi, che usano il task di weaving gia incluso. Il feed di ripristino e NuGet.org esplicito.

Il confronto upstream usa il commit 9b81f7222fc47356659c224855bdd799d044e93c, rilevato il 2 novembre. La differenza applicativa rispetto al punto comune e principalmente il ripristino dello scorrimento di 8d6e08028c603d793aa75e95b19e3503e05e47a1: non viene fuso automaticamente, perche introduce interrogazioni UI Automation sincrone sul cambio scheda e richiede un collaudo dedicato rispetto al profilo prestazioni italiano. I cambiamenti di documentazione upstream non sostituiscono le correzioni di questo ramo.

Il 3 novembre OSV e stato interrogato per le sei versioni runtime in packages.config e le tre PackageReference della suite MSTest: tutte le nove risposte sono state ricevute, senza advisory corrispondenti. Nessuna corrispondenza in un database non equivale a dimostrare l'assenza di vulnerabilita, ne include automaticamente tutti i binari incorporati, le dipendenze transitive e il sistema operativo.

## Prove

- Regressioni esistenti: 2.000 operazioni su icone in quattro thread STA, risorse italiane, dipendenze incorporate, 2.000 ridisegni; 10.000 richieste accorpate, risultati obsoleti scartati e provider lento senza bloccare il chiamante.
- 20 input ostili o non validi rifiutati: vecchi payload binari, tipo runtime iniettato, comando/versione sconosciuti, dimensioni e stringhe fuori quota, dati dopo la radice, DTD, archivio Memo non valido e duplicati.
- Richiesta reale autenticata su named pipe; servizio WCF e callback della DLL candidata, con due richieste consecutive, registrazione/rimozione di un riferimento di prova e rifiuto di un broadcast improprio.
- Clonazione delle opzioni, registro isolato con percorsi Unicode e punti e virgola, stato vuoto e conservazione dei dati precedenti; Memo XML con backup e originale preservato dopo salvataggio rifiutato.
- Build e caricamento delle DLL native a 32 e 64 bit, verifica degli export ABI. Questo controllo non inizializza gli hook e non sostituisce un collaudo dentro Explorer.

I risultati finali delle build, di CodeQL e del pacchetto sono consultabili nei workflow associati alla PR e al tag della release. Una pipeline riuscita non e una certificazione normativa.

## Compatibilita e limiti della prerelease

Tutti i processi Explorer che usano QTTabBar devono essere riavviati dopo un eventuale aggiornamento: istanze vecchie e nuove non condividono il protocollo IPC. Questa pubblicazione non installa o riavvia automaticamente software sul PC.

L'unione delle finestre mantiene i delegati solo nello stesso processo; non trasferisce piu grafi di schede tra processi. I comandi tipizzati mantengono apertura cartelle/gruppi, opzioni, aggiornamenti di configurazione e pulsanti. Le chiamate generiche interne restano locali. DeepClone supporta soltanto Config.

Il vecchio memo.dat non viene importato automaticamente o cancellato. Le nuove note sono in memo-v2.xml; il plug-in segnala la presenza dei dati precedenti. Per il recupero serve un convertitore che legga NRBF come dati, senza istanziare oggetti: non riabilitare BinaryFormatter per comodita. XML e impostazioni non sono cifrati; possono contenere dati personali.

Il rollback offline incluso e la precedente 0.6.0 e conserva i vecchi rischi: serve soltanto al ripristino di emergenza, non e una versione di sicurezza equivalente. I plug-in restano codice pienamente fidato, eseguito con i privilegi di Explorer. Nessuna separazione di processo o sandbox viene aggiunta a QTTabBar.

Restano necessari collaudi interattivi con Explorer, provider di rete, antivirus/estensioni di terze parti, sessioni prolungate e migrazione di configurazioni reali. La firma strong-name dell'assembly non e una firma Authenticode dell'editore. Windows e .NET devono avere aggiornamenti di sicurezza applicabili; non vengono modificati da questo lavoro.
