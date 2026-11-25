import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'main.dart';
import 'pagine_pubbliche.dart';

// ---------------------------------------------------------------------------
// R2 – Login
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _caricamento = false;

  Future<void> _accedi() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _caricamento = true);
    try {
      await Api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AreaRiservataPage()));
    } catch (e) {
      if (mounted) mostraMessaggio(context, e.toString(), errore: true);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  Future<void> _vaiARegistrazione() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RegistrazionePage()),
    );
    if (email != null && mounted) {
      _email.text = email;
      mostraMessaggio(context, 'Account creato! Ora accedi con le tue credenziali.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accesso aziende')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.business_center, size: 72, color: Colors.indigo),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci l\'email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Inserisci la password' : null,
              onFieldSubmitted: (_) => _accedi(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _caricamento ? null : _accedi,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _caricamento
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Accedi'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _vaiARegistrazione,
              child: const Text('Non hai un account? Registra la tua azienda'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// R1 – Registrazione
// ---------------------------------------------------------------------------

class RegistrazionePage extends StatefulWidget {
  const RegistrazionePage({super.key});
  @override
  State<RegistrazionePage> createState() => _RegistrazionePageState();
}

class _RegistrazionePageState extends State<RegistrazionePage> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _conferma = TextEditingController();
  bool _caricamento = false;

  Future<void> _registra() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _caricamento = true);
    try {
      await Api.registrazione(_nome.text.trim(), _email.text.trim(), _password.text);
      if (mounted) Navigator.pop(context, _email.text.trim());
    } catch (e) {
      if (mounted) mostraMessaggio(context, e.toString(), errore: true);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione azienda')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome azienda'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Email non valida' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password (min. 6 caratteri)'),
              obscureText: true,
              validator: (v) => (v == null || v.length < 6) ? 'Almeno 6 caratteri' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _conferma,
              decoration: const InputDecoration(labelText: 'Conferma password'),
              obscureText: true,
              validator: (v) => v != _password.text ? 'Le password non coincidono' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _caricamento ? null : _registra,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _caricamento
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crea account'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Area riservata: i miei annunci + nuovo annuncio + logout
// ---------------------------------------------------------------------------

class AreaRiservataPage extends StatefulWidget {
  const AreaRiservataPage({super.key});
  @override
  State<AreaRiservataPage> createState() => _AreaRiservataPageState();
}

class _AreaRiservataPageState extends State<AreaRiservataPage> {
  late Future<List<Annuncio>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = Api.mieiAnnunci();
  }

  Future<void> _ricarica() async {
    setState(() => _futuro = Api.mieiAnnunci());
    await _futuro.catchError((_) => <Annuncio>[]);
  }

  // R3 – Logout: si torna alla bacheca pubblica e lo stack di navigazione
  // viene svuotato, quindi l'area riservata non è più raggiungibile.
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vuoi uscire?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Esci')),
        ],
      ),
    );
    if (ok != true) return;
    await Api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BachecaPage()),
      (_) => false,
    );
    mostraMessaggio(context, 'Logout effettuato');
  }

  Future<void> _nuovoAnnuncio() async {
    final pubblicato = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuovoAnnuncioPage()),
    );
    if (pubblicato == true && mounted) {
      mostraMessaggio(context, 'Annuncio pubblicato in bacheca');
      _ricarica();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Api.nomeAzienda?.isNotEmpty == true ? Api.nomeAzienda! : 'Area riservata'),
        actions: [
          IconButton(tooltip: 'Logout', icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuovoAnnuncio,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo annuncio'),
      ),
      body: RefreshIndicator(
        onRefresh: _ricarica,
        child: FutureBuilder<List<Annuncio>>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              if (!Api.autenticato) {
                // token non più valido: torna al login
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  }
                });
              }
              return ListView(children: [
                const SizedBox(height: 160),
                Center(child: Text(snap.error.toString())),
              ]);
            }
            final annunci = snap.data!;
            if (annunci.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 160),
                Icon(Icons.post_add, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text('Non hai ancora pubblicato annunci')),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text('I miei annunci', style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final a in annunci)
                  Card(
                    child: ListTile(
                      title: Text(a.titolo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Pubblicato il ${formattaData(a.creatoIl)}'),
                      trailing: Chip(
                        avatar: const Icon(Icons.people_outline, size: 18),
                        label: Text('${a.numCandidature}'),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CandidatureAnnuncioPage(annuncio: a)),
                        );
                        _ricarica();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// R4 – Nuovo annuncio
// ---------------------------------------------------------------------------

class NuovoAnnuncioPage extends StatefulWidget {
  const NuovoAnnuncioPage({super.key});
  @override
  State<NuovoAnnuncioPage> createState() => _NuovoAnnuncioPageState();
}

class _NuovoAnnuncioPageState extends State<NuovoAnnuncioPage> {
  final _form = GlobalKey<FormState>();
  final _titolo = TextEditingController();
  final _descrizione = TextEditingController();
  final _sede = TextEditingController();
  bool _caricamento = false;

  Future<void> _pubblica() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _caricamento = true);
    try {
      await Api.pubblicaAnnuncio(_titolo.text.trim(), _descrizione.text.trim(), _sede.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostraMessaggio(context, e.toString(), errore: true);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titolo,
              decoration: const InputDecoration(labelText: 'Titolo', hintText: 'es. Sviluppatore Flutter junior'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sede,
              decoration: const InputDecoration(labelText: 'Sede (facoltativa)', hintText: 'es. Salerno / Remoto'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descrizione,
              decoration: const InputDecoration(labelText: 'Descrizione', alignLabelWithHint: true),
              minLines: 6,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _caricamento ? null : _pubblica,
              icon: const Icon(Icons.publish),
              label: const Text('Pubblica annuncio'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// R7 – Candidature ricevute per un annuncio
// ---------------------------------------------------------------------------

class CandidatureAnnuncioPage extends StatelessWidget {
  final Annuncio annuncio;
  const CandidatureAnnuncioPage({super.key, required this.annuncio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(annuncio.titolo)),
      body: FutureBuilder<List<Candidatura>>(
        future: Api.candidature(annuncio.id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          final lista = snap.data!;
          if (lista.isEmpty) {
            return const Center(child: Text('Nessuna candidatura ricevuta'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = lista[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?')),
                  title: Text('${c.nome} ${c.cognome}'),
                  subtitle: Text('${c.email}\nInviata il ${formattaData(c.inviataIl)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DettaglioCandidaturaPage(candidatura: c)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// R7 – Dettaglio candidatura + apertura CV
// ---------------------------------------------------------------------------

class DettaglioCandidaturaPage extends StatelessWidget {
  final Candidatura candidatura;
  const DettaglioCandidaturaPage({super.key, required this.candidatura});

  Future<void> _apriCv(BuildContext context) async {
    final ok = await launchUrl(candidatura.cvUrl, mode: LaunchMode.inAppBrowserView);
    if (!ok && context.mounted) {
      mostraMessaggio(context, 'Impossibile aprire il curriculum', errore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = candidatura;
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.person_outline), title: const Text('Nome'), subtitle: Text(c.nome)),
          ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Cognome'), subtitle: Text(c.cognome)),
          ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(c.email)),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Inviata il'),
            subtitle: Text(formattaData(c.inviataIl)),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Curriculum'),
            subtitle: Text(c.cvNome),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _apriCv(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Apri curriculum'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
