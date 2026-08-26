# QTTabBar Italiano — Windows 10 Edition

Personalizzazione italiana di **QTTabBar** per Windows 10 x64.

## Stato

- progetto italiano: `v0.3.0`
- baseline QTTabBar testata: `v1.5.6-beta.1`
- target: Windows 10 x64
- test iniziale: Windows 10 Pro 22H2 build 19045

## Funzioni del progetto

- localizzazione italiana;
- installazione/riparazione;
- diagnostica;
- riavvio controllato di Esplora file;
- disinstallazione;
- controlli SHA-256;
- pacchetto offline pubblicabile nelle GitHub Releases.

## Installazione utente

Scaricare dalla pagina **Releases**:

`QTTabBar_Italiano_Windows10_Offline_v0.3.0.zip`

Estrarre e avviare:

`INSTALLA_O_RIPARA_QTTABBAR_ITALIANO.cmd`

Se QTTabBar è già installato:

`RIPARA_SOLO_LINGUA_ITALIANA.cmd`

## Attivazione

In Esplora file:

1. `Visualizza > Opzioni > QTTabBar`
2. clic destro sulla barra QTTabBar > `QTTabBar Options`
3. `Language > Use language file`
4. selezionare `Lng_QTTabBar_it_IT.xml`
5. `Apply > OK`

## Repository

```text
.github/
docs/
i18n/
installer/
scripts/
release/
README.md
CHANGELOG.md
CONTRIBUTING.md
SECURITY.md
UPSTREAM.md
THIRD_PARTY_NOTICES.md
LICENSE
```

## Release v0.3.0

SHA-256 pacchetto offline:

`C66988B1577ED098AF75C1D62722D637AFDD03BAA219361A25D89BF2C1C5C66C`

SHA-256 MSI QTTabBar usato:

`AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287`

## Sicurezza

Non pubblicare log grezzi, file `.reg`, backup di sistema, token, password o
percorsi personali.

## Licenza

GNU GPL v3. Vedere `LICENSE`, `UPSTREAM.md` e `THIRD_PARTY_NOTICES.md`.
