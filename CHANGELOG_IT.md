# Changelog

## v0.6.0
- cache degli elementi asincrona sul percorso mouse/disegno;
- richieste accorpate ogni 33 ms, un solo lavoro in corso e scarto dei risultati superati;
- client UI Automation creato e usato sul medesimo thread MTA;
- rifiuto dei percorsi di rete prima dei controlli delle sottocartelle;
- protezioni per geometrie incomplete e conteggi di pagina nulli;
- profilo rapido: anteprime e menu delle sottocartelle con Maiusc;
- Microsoft System.Text.Encoding.CodePages aggiornato a 10.0.12;
- test con provider lento, 10.000 richieste e DLL candidata isolata dalla GAC;
- aggiornamento verificato dalla 0.5.0 con backup/ripristino.
## v0.5.0
- aggiornamento dei sorgenti alla base upstream 1.6.3;
- italiano integrato mantenuto dalla 0.4.0;
- ImageList separata per ogni thread STA di Explorer;
- riutilizzo dei pennelli delle schede;
- dipendenze gestite incorporate per il caricamento dalla GAC;
- MSI con aggiornamento transazionale e wrapper con backup/ripristino;
- nessuna cancellazione della chiave condivisa Toolbar;
- test di regressione concorrenti e di ridisegno.
## v0.3.0
- pacchetto offline Windows 10 x64;
- localizzazione italiana;
- validazione XML corretta;
- rilevamento sicuro delle proprietà del Registro;
- nessuna reinstallazione se QTTabBar 1.5.6.x è già presente;
- diagnostica;
- riavvio Esplora file;
- disinstallazione;
- verifica SHA-256.

## v0.2.2
- correzione `DisplayName`, `DisplayVersion`, `UninstallString`,
  `QuietUninstallString`.

## v0.2.1
- corretta gestione delle chiavi QTTabBar assenti.

## v0.2.0
- primo setup integrato.

## v0.1.0
- prima localizzazione italiana.
