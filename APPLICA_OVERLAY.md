# COME APPLICARE QUESTO OVERLAY AL FORK QTTabBar

Questo ZIP è pensato per essere estratto nella radice di un fork di:

    https://github.com/indiff/qttabbar

Non sovrascrive il README, il CHANGELOG o la licenza upstream.

Aggiunge:

- `I18N/Lng_QTTabBar_it_IT.xml`
- `README_IT.md`
- `CHANGELOG_IT.md`
- `Italiano/`
- `.github/workflows/validate-italiano.yml`

Procedura:

1. Creare il fork GitHub di `indiff/qttabbar`.
2. Clonare il fork sul PC.
3. Estrarre questo ZIP nella radice del clone.
4. Verificare `git status`.
5. Eseguire:
       git add .
       git commit -m "Add Italian Windows 10 edition v0.3.0"
       git push origin main
6. Creare una GitHub Release con tag `it-v0.3.0`.
7. Allegare il pacchetto offline:
       QTTabBar_Italiano_Windows10_Offline_v0.3.0.zip

NON aggiungere:
- log personali;
- backup .reg;
- token/password;
- cartelle ProgramData;
- file con nomi utente o percorsi personali.
