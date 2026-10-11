# QTTabBar Italiano — Windows 10 Edition 0.5.0

Edizione italiana con correzioni di stabilita, basata sui sorgenti upstream **QTTabBar 1.6.3** (tag `v1.6.3`, commit `8e5434b`). Mantiene l'italiano integrato introdotto nella 0.4.0.

## Correzioni

- Ogni thread di Esplora file ha la propria lista delle icone: evita gli accessi concorrenti a `ImageList`, coerenti con le eccezioni `IndexOfKey/ContainsKey` osservate durante il disegno delle schede.
- Riutilizzo dei pennelli grafici delle schede: elimina le allocazioni ripetute senza `Dispose` durante ogni ridisegno.
- Dipendenze dell'anteprima testo incorporate nella DLL, risolvibili anche quando la libreria viene caricata dalla GAC.
- Aggiornamento MSI transazionale dalla 1.5.6.1, backup dei dati di ripristino e riavvio limitato alla sessione corrente.
- L'installer non elimina la chiave condivisa di tutte le barre di Esplora file e non esegue `taskkill /IM explorer.exe` dal servizio MSI.

Queste correzioni non dimostrano che ogni crash di Explorer sia causato da QTTabBar. Il crash `ntdll.dll / 0xc0000409` richiede un dump per essere attribuito con certezza.

## Installazione

Richiesti Windows 10 x64 e .NET Framework 4.8. Scaricare dalla [release italiana](https://github.com/mattia-di-chiara-5/QTTabBar-Italiano-Windows10/releases) `QTTabBar-Italiano-Windows10-v0.5.0.zip`, estrarre e avviare **INSTALLA_STABILITA.cmd**. Accettare l'elevazione UAC. L'aggiornamento chiude le finestre di Esplora file: terminare prima copie ed estrazioni in corso.

La migrazione automatica supporta una nuova installazione o la 1.5.6.1 originale/italiana 0.4.0 con hash riconosciuto. Versioni diverse vengono rifiutate. La lingua integrata viene impostata su Italiano (indice 8). Se la barra non e visibile, abilitarla da Visualizza > Opzioni > QTTabBar.

La versione dell'edizione e **0.5.0**, la base e **1.6.3** e la versione file e **1.6.3.5**. L'identita COM rimane `1.6.3.0` per compatibilita con i plugin upstream; la versione interna MSI `1.6.4` serve all'aggiornamento e non indica un aggiornamento upstream alla 1.6.4.

## Ripristino

Avviare **RIPRISTINA_VERSIONE_PRECEDENTE.cmd** con lo stesso account Windows. Rimuove la nuova edizione e, se presente prima dell'aggiornamento, reinstalla l'MSI 1.5.6.1 verificato e la DLL esatta precedente; ripristina inoltre la configurazione salvata prima dell'installazione. I backup restano in `%ProgramData%\QTTabBar-Italiano\v0.5.0`, protetti per amministratori e SYSTEM. Non pubblicare i backup o i log personali.

## Compilazione e verifica

Usare Visual Studio Build Tools/MSBuild con targeting pack .NET 4.8, SDK Windows per l'interoperabilita COM, NuGet e WiX 3.14.1. Il workflow `italiano-stability.yml` documenta la sequenza completa. Ripristinare `QTTabBar/packages.config`, compilare `QTTabBar/QTTabBar.csproj` in Release/AnyCPU, eseguire `Italiano/tests/Run-Regression.ps1`, quindi `Italiano/scripts/Build-StabilityPackage.ps1`.

La creazione usa l'installer ufficiale 1.6.3 con SHA-256 `2F91AD5B04DE7518C9BDE708768E88BE4EBF8EB92AA3649B1FEED1B3DF239FDF` per i plugin e gli hook nativi. L'MSI originale di ripristino e incluso con SHA-256 `AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287`. I sorgenti corrispondenti alla base sono inclusi nella cronologia Git e nel merge del tag upstream.

I test coprono quattro thread STA con 2.000 cicli sulle icone, cultura e risorse italiane integrate, 2.000 ridisegni reali delle schede senza sostituzione dei pennelli e senza nuove eccezioni nel log. Il pacchetto non ha firma Authenticode; la DLL conserva lo strong name del progetto. La stabilita nell'uso prolungato, sulle cartelle di rete e con antivirus/altre estensioni richiede verifica sul PC.

Licenza GNU GPL v3: vedere LICENSE.txt. Crediti a Quizo, Paul Accisano, indiff e ai contributori upstream; localizzazione italiana dal commit `d2eddd9` dell'edizione 0.4.0.
