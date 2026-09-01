# IdroRiparto

App Flutter per la **ripartizione dei consumi e delle spese dell’acqua condominiale**.

Pensata per amministratori, consiglieri e condomini che vogliono un prospetto chiaro, ripetibile e pronto per l’assemblea. I dati restano sul dispositivo: niente account, niente cloud.

## Cosa fa

- Anagrafica del condominio e delle **unità immobiliari** (millesimi, occupanti, sfitto, sottocontatore).
- **Campagne di lettura** del contatore generale e dei sottocontatori.
- Registrazione della **bolletta** del gestore, voce per voce:
  - quota fissa / canone
  - acquedotto
  - fognatura
  - depurazione
  - IVA e altre voci
- Quattro criteri di riparto, confrontabili sulla stessa bolletta:
  1. **Millesimi** — criterio residuale dell’art. 1123 c.c.
  2. **Consumo** — in proporzione ai m³ dei sottocontatori
  3. **Occupanti** — se deliberato in assemblea
  4. **Misto** — quote fisse da un lato, consumi a m³ dall’altro, **parti comuni e perdite** spalmate a parte
- Avvisi automatici: millesimi ≠ 1.000, letture mancanti, perdite elevate, unità sfitte.
- **Prospetto PDF** (tabella + tagliandi individuali) e **CSV** per Excel.
- Tema chiaro / scuro e backup JSON.

## Metodo misto (quello che usa la prassi)

1. La **quota fissa** si divide per millesimi, parti uguali o occupanti.
2. La quota variabile (acquedotto + fognatura + depurazione) ha un prezzo medio €/m³.
3. Ogni unità paga i **propri metri cubi**.
4. La differenza tra contatore generale (o m³ fatturati) e somma dei sottocontatori — giardino, androne, perdite — si ripartisce come spesa comune.
5. IVA e altre voci si spalmano in proporzione al subtotale.
6. Gli arrotondamenti al centesimo vengono chiusi sull’unità con la quota più alta, così la somma coincide sempre con la bolletta.

Il regolamento contrattuale o una delibera possono imporre un criterio diverso. IdroRiparto è uno strumento di calcolo, non un parere legale.

## Avvio

Requisiti: Flutter 3.32+ (testata con 3.44), Dart 3.8+.

```bash
cd idroriparto
flutter pub get
flutter test
flutter run -d chrome          # oppure un emulatore / un telefono
flutter build apk              # Android
flutter build ios              # iOS (su macOS)
flutter build web              # cartella build/web
```

Al primo avvio puoi **creare il tuo condominio** oppure aprire l’esempio **Palazzo Solferino** (Milano, 8 unità, letture 2025–2026 e due bollette MM già ripartite).

## Struttura

```
lib/
  main.dart
  theme/app_theme.dart
  models/models.dart
  data/store.dart            # persistenza locale (SharedPreferences)
  data/demo_data.dart
  services/riparto_engine.dart
  services/pdf_service.dart
  screens/                   # home, unità, letture, bollette, riparto, impostazioni
  widgets/
```

## Piattaforme

Android, iOS e Web. La persistenza usa `shared_preferences` (LocalStorage sul web).
