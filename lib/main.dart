import 'package:flutter/material.dart';

import 'api.dart';
import 'pagine_pubbliche.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.caricaSessione();
  runApp(const BachecaApp());
}

class BachecaApp extends StatelessWidget {
  const BachecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bacheca Lavoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const BachecaPage(),
    );
  }
}

/// Messaggio rapido in basso.
void mostraMessaggio(BuildContext context, String testo, {bool errore = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(testo),
    backgroundColor: errore ? Theme.of(context).colorScheme.error : null,
  ));
}
