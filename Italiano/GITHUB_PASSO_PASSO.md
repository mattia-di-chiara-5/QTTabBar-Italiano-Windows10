# GitHub passo per passo per la v0.4.0

Questa procedura parte dal repository locale:

    C:\GitHub\QTTabBar-Italiano-Windows10

Il branch corretto è feature/italian-built-in e la base deve essere
44a83bef8cdf5fb67c6d7f6434821c6f602542e7.

## 1. Controllo locale prima dei commit

Aprire PowerShell 7 e usare:

    cd C:\GitHub\QTTabBar-Italiano-Windows10
    git branch --show-current
    git rev-parse HEAD
    git status --short
    .\Italiano\tools\Test-ItalianResources.ps1

I primi due comandi devono mostrare feature/italian-built-in e 44a83bef...

## 2. Test runtime obbligatorio

Estrarre l'asset QTTabBar-Italiano-Windows10-v0.4.0.zip e avviare:

    INSTALLA_QTTABBAR_ITALIANO.cmd

Accettare UAC. Poi verificare in Esplora file:

1. QTTabBar è visibile e crea/chiude schede;
2. il menu contestuale e le Opzioni sono in italiano;
3. Opzioni, Language mostra Italiano selezionato;
4. Use language file è disattivato;
5. Esplora file resta stabile dopo chiusura e riapertura.

Eseguire anche il rollback:

    RIPRISTINA_QTTABBAR_ORIGINALE.cmd

Verificare che torni la DLL precedente; infine reinstallare la v0.4.0 e
ripetere il controllo rapido.

## 3. Primo commit: sorgente built-in

    git add QTTabBar/Config.cs
    git add QTTabBar/OptionsDialog/Options13_Language.xaml
    git add QTTabBar/QTTabBar.csproj
    git add QTTabBar/QTUtility.cs
    git add QTTabBar/Resources_String_it_IT.cs
    git add QTTabBar/Resources_String_it_IT.resx
    git diff --cached --check
    git commit -m "feat(i18n): add built-in Italian localization"

Se git diff --cached --check segnala solo CR a fine riga nei file legacy,
eseguire il controllo preservando i CRLF storici:

    git -c core.whitespace=cr-at-eol diff --cached --check

Non normalizzare QTUtility.cs.

## 4. Secondo commit: installer, test e documentazione

    git add Italiano
    git add .github/workflows/validate-italian.yml
    git add README.md
    git diff --cached --check
    git commit -m "build(release): add verified Italian installer and rollback"

## 5. Pubblicare il branch

    git push -u origin feature/italian-built-in

Non usare force push.

## 6. Preparare il branch stabile

Crearlo una sola volta dalla baseline:

    git switch -c release/0.4 44a83bef8cdf5fb67c6d7f6434821c6f602542e7
    git push -u origin release/0.4
    git switch feature/italian-built-in

Su GitHub:

1. aprire il repository mattia-di-chiara-5/QTTabBar-Italiano-Windows10;
2. scegliere Pull requests, poi New pull request;
3. base: release/0.4;
4. compare: feature/italian-built-in;
5. titolo: QTTabBar Italiano v0.4.0;
6. attendere il workflow Validate Italian localization;
7. unire con Create a merge commit;
8. non eliminare subito feature/italian-built-in.

## 7. Tag e GitHub Release

Dopo il merge:

    git fetch origin
    git switch release/0.4
    git pull --ff-only
    git tag -a it-v0.4.0 -m "QTTabBar Italiano v0.4.0"
    git push origin it-v0.4.0

Su GitHub:

1. aprire Releases, poi Draft a new release;
2. scegliere il tag it-v0.4.0;
3. titolo: QTTabBar Italiano v0.4.0;
4. copiare il testo di Italiano/release/RELEASE_NOTES_v0.4.0.md;
5. allegare QTTabBar-Italiano-Windows10-v0.4.0.zip;
6. aggiungere nella descrizione lo SHA-256 dello ZIP;
7. salvare prima come draft;
8. scaricare l'asset dal draft e verificarne nuovamente l'hash;
9. solo dopo pubblicare la release.

## 8. Vincoli storici

- non modificare il tag it-v0.3.0;
- non fondere master o develop moderni nella linea 1.5.6;
- non caricare snapshot, file .reg, log o backup GAC;
- non committare lo ZIP offline nel repository: è un asset della Release;
- per un futuro QTTabBar moderno usare un branch upgrade separato.
