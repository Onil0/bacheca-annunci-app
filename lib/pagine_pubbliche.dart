import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'api.dart';
import 'main.dart';
import 'pagine_azienda.dart';

// ---------------------------------------------------------------------------
// R5 – Bacheca pubblica (schermata iniziale, nessun login)
// ---------------------------------------------------------------------------

class BachecaPage extends StatefulWidget {
  const BachecaPage({super.key});
  @override
  State<BachecaPage> createState() => _BachecaPageState();
}

class _BachecaPageState extends State<BachecaPage> {
  late Future<List<Annuncio>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = Api.annunci();
  }

  Future<void> _ricarica() async {
    setState(() => _futuro = Api.annunci());
    await _futuro.catchError((_) => <Annuncio>[]);
  }

  Future<void> _apriAreaAziende() async {
    final pagina = Api.autenticato ? const AreaRiservataPage() : const LoginPage();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pagina));
    if (mounted) _ricarica();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca annunci'),
        actions: [
          TextButton.icon(
            onPressed: _apriAreaAziende,
            icon: const Icon(Icons.business),
            label: const Text('Area aziende'),
          ),
        ],
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
              return _MessaggioCentrale(icona: Icons.wifi_off, testo: snap.error.toString());
            }
            final annunci = snap.data!;
            if (annunci.isEmpty) {
              return const _MessaggioCentrale(
                  icona: Icons.work_off_outlined, testo: 'Nessun annuncio pubblicato');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: annunci.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final a = annunci[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.work_outline)),
                    title: Text(a.titolo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([a.azienda, a.sede].whereType<String>().join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DettaglioAnnuncioPage(annuncio: a)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MessaggioCentrale extends StatelessWidget {
  final IconData icona;
  final String testo;
  const _MessaggioCentrale({required this.icona, required this.testo});

  @override
  Widget build(BuildContext context) {
    // ListView così il pull-to-refresh funziona anche qui
    return ListView(
      children: [
        const SizedBox(height: 160),
        Icon(icona, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(testo, textAlign: TextAlign.center))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// R5 – Dettaglio annuncio
// ---------------------------------------------------------------------------

class DettaglioAnnuncioPage extends StatelessWidget {
  final Annuncio annuncio;
  const DettaglioAnnuncioPage({super.key, required this.annuncio});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio annuncio')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(annuncio.titolo, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (annuncio.azienda != null)
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.business), title: Text(annuncio.azienda!)),
          if (annuncio.sede != null)
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.place_outlined), title: Text(annuncio.sede!)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text('Pubblicato il ${formattaData(annuncio.creatoIl)}'),
          ),
          const Divider(height: 32),
          Text('Descrizione', style: t.titleMedium),
          const SizedBox(height: 8),
          Text(annuncio.descrizione, style: t.bodyLarge),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Candidati'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CandidaturaPage(annuncio: annuncio)),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// R6 – Form di candidatura
// ---------------------------------------------------------------------------

class CandidaturaPage extends StatefulWidget {
  final Annuncio annuncio;
  const CandidaturaPage({super.key, required this.annuncio});
  @override
  State<CandidaturaPage> createState() => _CandidaturaPageState();
}

class _CandidaturaPageState extends State<CandidaturaPage> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _cognome = TextEditingController();
  final _email = TextEditingController();
  PlatformFile? _cv;
  Uint8List? _cvBytes;
  bool _invio = false;

  Future<void> _scegliCv() async {
    final r = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (r.isEmpty) return;
    final file = r.first;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _cv = file;
      _cvBytes = bytes;
    });
  }

  Future<void> _invia() async {
    if (!_form.currentState!.validate()) return;
    if (_cv == null || _cvBytes == null) {
      mostraMessaggio(context, 'Allega il curriculum in PDF', errore: true);
      return;
    }
    setState(() => _invio = true);
    try {
      await Api.candidati(
        annuncioId: widget.annuncio.id,
        nome: _nome.text.trim(),
        cognome: _cognome.text.trim(),
        email: _email.text.trim(),
        cvNome: _cv!.name,
        cvBytes: _cvBytes!,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Candidatura inviata!'),
          content: Text('La tua candidatura per "${widget.annuncio.titolo}" è stata registrata.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (mounted) mostraMessaggio(context, e.toString(), errore: true);
    } finally {
      if (mounted) setState(() => _invio = false);
    }
  }

  String? _obbligatorio(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Ti stai candidando per:', style: Theme.of(context).textTheme.bodyMedium),
            Text(widget.annuncio.titolo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome'), textCapitalization: TextCapitalization.words, validator: _obbligatorio),
            const SizedBox(height: 12),
            TextFormField(controller: _cognome, decoration: const InputDecoration(labelText: 'Cognome'), textCapitalization: TextCapitalization.words, validator: _obbligatorio),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Email non valida' : null,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _scegliCv,
              icon: const Icon(Icons.attach_file),
              label: Text(_cv == null ? 'Allega curriculum (PDF)' : 'Cambia file'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            if (_cv != null)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(_cv!.name),
                subtitle: Text('${(_cvBytes!.length / 1024).toStringAsFixed(0)} KB'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _invio ? null : _invia,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _invio
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Invia candidatura'),
            ),
          ],
        ),
      ),
    );
  }
}
