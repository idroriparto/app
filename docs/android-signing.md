# Firma delle release Android

Le release Android di IdroRiparto usano il package ID
`it.idroriparto.idroriparto`. Android accetta un APK come aggiornamento solo se
ha lo stesso package ID, una firma compatibile e un `versionCode` maggiore della
versione già installata.

Il progetto non usa più la chiave debug per le release. Ogni APK distribuito da
GitHub Actions deve essere firmato con **la stessa keystore privata release**.
La chiave non va mai aggiunta al repository, agli artifact o agli archivi
sorgenti.

Fonti ufficiali:

- [Flutter: build e firma Android](https://docs.flutter.dev/deployment/android#sign-the-app)
- [Android Developers: app signing](https://developer.android.com/studio/publish/app-signing)
- [GitHub Actions: uso dei secret](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)

## Migrazione dalla firma precedente

La chiave che ha firmato le versioni Android precedenti non è disponibile. Non
è quindi tecnicamente possibile aggiornare quelle installazioni con il nuovo
certificato: Android rifiuterebbe l'APK per proteggere l'identità dell'app.

Per la **prima** release firmata con la nuova chiave, comunica agli utenti di:

1. esportare l'archivio JSON dall'app, se hanno dati da mantenere;
2. disinstallare la vecchia app;
3. installare l'APK release firmato con la nuova chiave;
4. importare l'archivio JSON.

Dalla prima installazione firmata con la nuova chiave in poi, gli APK successivi
si installeranno come normali aggiornamenti e conserveranno i dati locali.

## 1. Crea e conserva la keystore una sola volta

Su un computer fidato, fuori dal repository, esegui:

```bash
keytool -genkey -v \
  -keystore "$HOME/idroriparto-release.jks" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -alias idroriparto
```

`keytool` richiede interattivamente password e dati del certificato. Conserva
in modo sicuro e ridondante:

- il file `idroriparto-release.jks`;
- la password del keystore;
- l'alias `idroriparto`;
- la password della chiave.

Non inviare mai questi valori in chat e non caricarli nel repository. La perdita
della chiave impedirebbe la distribuzione di aggiornamenti per le installazioni
firmate con essa.

Registra l'impronta del certificato per future verifiche:

```bash
keytool -list -v \
  -keystore "$HOME/idroriparto-release.jks" \
  -alias idroriparto
```

## 2. Configura la build locale

Copia il modello incluso:

```bash
cp android/key.properties.example android/key.properties
```

Inserisci in `android/key.properties` il percorso **assoluto** della keystore e
le credenziali reali. Questo file è ignorato da Git. Poi crea l'APK:

```bash
flutter build apk --release
```

Una build `flutter run` o `flutter build apk --debug` continua a usare la
chiave debug e non richiede questa configurazione. Una build release priva di
firma viene invece bloccata intenzionalmente.

## 3. Inserisci i secret in GitHub Actions

Codifica la keystore per il secret GitHub, senza salvare il file risultante nel
repository.

Linux:

```bash
base64 -w 0 "$HOME/idroriparto-release.jks" > /tmp/idroriparto-keystore.b64
```

macOS:

```bash
base64 < "$HOME/idroriparto-release.jks" | tr -d '\n' > /tmp/idroriparto-keystore.b64
```

In **Repository → Settings → Secrets and variables → Actions**, crea questi
repository secret:

| Nome | Valore |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | contenuto del file Base64 creato sopra |
| `ANDROID_KEYSTORE_PASSWORD` | password del keystore |
| `ANDROID_KEY_ALIAS` | `idroriparto` |
| `ANDROID_KEY_PASSWORD` | password della chiave |

La workflow ripristina la keystore in `RUNNER_TEMP`, controlla alias e password,
passa le credenziali a Gradle solo tramite variabili d'ambiente e cancella il
file temporaneo al termine del job. Senza i quattro secret, la build Android
release fallisce invece di pubblicare un APK firmato con una chiave debug
variabile.

## 4. Incrementa sempre la versione Android

In `pubspec.yaml`, il valore dopo `+` diventa il `versionCode` Android. A ogni
release deve essere un intero positivo e maggiore di quello precedente.

```yaml
version: 1.0.5+5
```

Per questa versione la tag GitHub deve essere `v1.0.5`. La workflow verifica che
la tag coincida con la parte SemVer prima del `+` e che sia presente un build
number positivo.

## 5. Verifica l'APK prima della distribuzione

Dopo la build, controlla la firma con gli Android Build Tools:

```bash
apksigner verify --verbose --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```

Confronta il certificato SHA-256 con quello annotato al primo rilascio. Deve
restare identico in tutte le release future.
