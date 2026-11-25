# Bacheca annunci di lavoro – App Flutter

App mobile per una bacheca di annunci di lavoro. Le aziende si registrano, pubblicano annunci e consultano le candidature ricevute. I candidati, senza login, consultano la bacheca e si candidano allegando il curriculum in PDF.

Back-end (Dart + SQLite): <https://github.com/Onil0/bacheca-annunci-backend>

## Requisiti coperti

| Requisito | Descrizione | Dove nell'app |
|---|---|---|
| R1 | Registrazione dell'azienda | Registrazione azienda |
| R2 | Login dell'azienda | Accesso aziende |
| R3 | Logout dell'azienda | Area riservata → icona di logout |
| R4 | Pubblicazione di un annuncio | Area riservata → Nuovo annuncio |
| R5 | Consultazione della bacheca senza login | Bacheca annunci, Dettaglio annuncio |
| R6 | Candidatura con CV in PDF senza login | Dettaglio annuncio → Candidati |
| R7 | Consultazione delle candidature e del CV | Area riservata → annuncio → candidatura → Apri curriculum |

## Scenari

### S1 – Pubblicare un annuncio (R1, R2, R4)

Punto di partenza: l'azienda non ha un account.

1. L'azienda apre la schermata di registrazione, inserisce i dati e conferma. L'app crea l'account.
2. L'azienda esegue il login con email e password. L'app l'autentica e mostra l'area riservata.
3. L'azienda avvia la creazione di un nuovo annuncio, inserisce titolo e descrizione, e conferma.
4. L'app pubblica l'annuncio, che compare nella bacheca.

**Nell'app:** Bacheca annunci → **Area aziende** → **Non hai un account? Registra la tua azienda** → Nome azienda, Email, Password, Conferma password → **Crea account** → si torna ad Accesso aziende con l'email già inserita → Password → **Accedi** → Area riservata → **Nuovo annuncio** → Titolo, Sede (facoltativa), Descrizione → **Pubblica annuncio** → messaggio "Annuncio pubblicato in bacheca". L'annuncio compare nella Bacheca annunci (trascinare verso il basso per aggiornare).

### S2 – Candidarsi a un annuncio (R5, R6)

Punto di partenza: il candidato apre l'app senza autenticarsi.

1. L'app mostra l'elenco degli annunci pubblicati.
2. Il candidato seleziona un annuncio e l'app ne mostra il dettaglio.
3. Il candidato avvia la candidatura, compila nome, cognome ed email, allega il curriculum e conferma l'invio.
4. L'app registra la candidatura e mostra un messaggio di conferma.

**Nell'app:** all'apertura c'è la **Bacheca annunci** → tocca un annuncio → **Dettaglio annuncio** → **Candidati** → Nome, Cognome, Email → **Allega curriculum (PDF)** (si apre il selettore dei file, sono accettati solo PDF) → **Invia candidatura** → finestra "Candidatura inviata!" → **OK** per tornare alla bacheca.

### S3 – Consultare le candidature e uscire (R7, R3)

Punto di partenza: l'azienda è autenticata e ha almeno un annuncio con candidature.

1. L'azienda apre l'elenco dei propri annunci e ne seleziona uno. L'app mostra le candidature ricevute.
2. L'azienda ne seleziona una e vede i dati del candidato, poi apre il curriculum allegato.
3. L'azienda esegue il logout.
4. L'app torna alla schermata pubblica e l'area riservata non è più accessibile.

**Nell'app:** Bacheca annunci → **Area aziende** (con la sessione salvata si apre direttamente l'Area riservata) → **I miei annunci**, ognuno con il numero di candidature → tocca un annuncio → elenco delle candidature → tocca una candidatura → **Candidatura** (nome, cognome, email, data, nome del file) → **Apri curriculum** (il PDF si apre nel browser interno all'app) → torna all'Area riservata → **icona di logout** in alto a destra → **Esci** → si torna alla Bacheca annunci con il messaggio "Logout effettuato". Toccando di nuovo **Area aziende** viene chiesto il login.

## Schermate principali

| Schermata | File | Contenuto |
|---|---|---|
| Bacheca annunci | `lib/pagine_pubbliche.dart` | Schermata iniziale pubblica: elenco annunci con azienda e sede, aggiornamento trascinando verso il basso, pulsante "Area aziende". |
| Dettaglio annuncio | `lib/pagine_pubbliche.dart` | Titolo, azienda, sede, data, descrizione e pulsante "Candidati". |
| Candidatura | `lib/pagine_pubbliche.dart` | Form con nome, cognome, email (validata) e allegato PDF. |
| Accesso aziende | `lib/pagine_azienda.dart` | Login con email e password, link alla registrazione. |
| Registrazione azienda | `lib/pagine_azienda.dart` | Nome azienda, email, password (minimo 6 caratteri) e conferma. |
| Area riservata | `lib/pagine_azienda.dart` | "I miei annunci" con il numero di candidature, pulsante "Nuovo annuncio", logout. |
| Nuovo annuncio | `lib/pagine_azienda.dart` | Titolo, sede facoltativa, descrizione. |
| Candidature ricevute | `lib/pagine_azienda.dart` | Elenco dei candidati per un annuncio. |
| Dettaglio candidatura | `lib/pagine_azienda.dart` | Dati del candidato e pulsante "Apri curriculum". |

Il client REST e i modelli (`Annuncio`, `Candidatura`) sono in `lib/api.dart`. Il token di login è salvato sul telefono con `shared_preferences`, quindi l'azienda resta autenticata anche dopo aver chiuso l'app. Se il server rifiuta il token, la sessione viene cancellata e l'app torna al login.

## Come avviare

1. **Avviare il back-end** (vedi il [repository del back-end](https://github.com/Onil0/bacheca-annunci-backend)):
   ```bash
   dart pub get
   dart run bin/server.dart
   ```
   Il server stampa gli indirizzi IP del computer.
2. **Impostare l'indirizzo del server** in `lib/api.dart`, usando l'IP della rete Wi-Fi stampato dal server:
   ```dart
   const String baseUrl = 'http://192.168.1.53:8080';
   ```
   Lo smartphone deve essere sulla stessa rete Wi-Fi del computer.
3. **Installare le dipendenze e avviare l'app** con lo smartphone collegato:
   ```bash
   flutter pub get
   flutter run
   ```

### iOS

Il server usa HTTP (non HTTPS) sulla rete locale. In `ios/Runner/Info.plist` sono già presenti:

- `NSAppTransportSecurity` → `NSAllowsArbitraryLoads = true`, per permettere le connessioni HTTP;
- `NSLocalNetworkUsageDescription`, il testo della richiesta di accesso alla rete locale.

Al primo avvio iOS chiede il permesso di accedere alla rete locale: va concesso, altrimenti l'app non raggiunge il server.

Su iPhone una build di debug si apre solo da `flutter run` o da Xcode. Per avere un'app che si apre dall'icona serve una build release (`flutter run --release`).

### Android

L'app è stata provata su iOS. Per usarla su Android, in `android/app/src/main/AndroidManifest.xml` vanno aggiunti:

- sopra `<application>`: `<uses-permission android:name="android.permission.INTERNET"/>`
- nel tag `<application>`: `android:usesCleartextTraffic="true"`

## Pacchetti usati

| Pacchetto | Uso |
|---|---|
| `http` | Chiamate REST al back-end |
| `shared_preferences` | Salvataggio del token di login sul telefono |
| `file_picker` | Scelta del curriculum PDF (versione 13.x) |
| `url_launcher` | Apertura del PDF del curriculum |
