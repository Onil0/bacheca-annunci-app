import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Indirizzo del server: IP del Mac sulla stessa rete Wi-Fi dello smartphone.
/// Il server lo stampa all'avvio (es. http://192.168.1.23:8080).
const String baseUrl = 'http://192.168.1.23:8080';

class ApiException implements Exception {
  final String messaggio;
  ApiException(this.messaggio);
  @override
  String toString() => messaggio;
}

// ---------------------------------------------------------------------------
// Modelli
// ---------------------------------------------------------------------------

class Annuncio {
  final int id;
  final String titolo;
  final String descrizione;
  final String? sede;
  final String? azienda;
  final DateTime creatoIl;
  final int numCandidature;

  Annuncio({
    required this.id,
    required this.titolo,
    required this.descrizione,
    this.sede,
    this.azienda,
    required this.creatoIl,
    this.numCandidature = 0,
  });

  factory Annuncio.fromJson(Map<String, dynamic> j) => Annuncio(
    id: j['id'] as int,
    titolo: j['titolo'] as String,
    descrizione: j['descrizione'] as String,
    sede: j['sede'] as String?,
    azienda: j['azienda'] as String?,
    creatoIl: DateTime.parse(j['creato_il'] as String),
    numCandidature: (j['num_candidature'] ?? 0) as int,
  );
}

class Candidatura {
  final int id;
  final String nome;
  final String cognome;
  final String email;
  final String cvNome;
  final DateTime inviataIl;

  Candidatura({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    required this.cvNome,
    required this.inviataIl,
  });

  factory Candidatura.fromJson(Map<String, dynamic> j) => Candidatura(
    id: j['id'] as int,
    nome: j['nome'] as String,
    cognome: j['cognome'] as String,
    email: j['email'] as String,
    cvNome: j['cv_nome_originale'] as String,
    inviataIl: DateTime.parse(j['inviata_il'] as String),
  );

  /// URL per aprire il PDF (il token serve perché il browser non invia header).
  Uri get cvUrl => Uri.parse('$baseUrl/candidature/$id/cv?token=${Api.token}');
}

String formattaData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ---------------------------------------------------------------------------
// Client REST
// ---------------------------------------------------------------------------

class Api {
  static String? token;
  static String? nomeAzienda;

  static bool get autenticato => token != null;

  /// Ripristina la sessione salvata sul telefono (persistenza del login).
  static Future<void> caricaSessione() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    nomeAzienda = p.getString('nomeAzienda');
  }

  static Future<void> _salvaSessione(String? t, String? nome) async {
    token = t;
    nomeAzienda = nome;
    final p = await SharedPreferences.getInstance();
    if (t == null) {
      await p.remove('token');
      await p.remove('nomeAzienda');
    } else {
      await p.setString('token', t);
      await p.setString('nomeAzienda', nome ?? '');
    }
  }

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<dynamic> _richiesta(
    Future<http.Response> Function() chiamata,
  ) async {
    http.Response r;
    try {
      r = await chiamata().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException('Il server non risponde');
    } on SocketException {
      throw ApiException(
        'Server non raggiungibile: controlla Wi-Fi e indirizzo',
      );
    } on http.ClientException {
      throw ApiException(
        'Server non raggiungibile: controlla Wi-Fi e indirizzo',
      );
    }

    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return body;

    if (r.statusCode == 401 && token != null) {
      await _salvaSessione(null, null); // sessione scaduta o non valida
    }
    final msg = body is Map && body['errore'] != null
        ? body['errore'] as String
        : 'Errore ${r.statusCode}';
    throw ApiException(msg);
  }

  static Future<dynamic> _get(String path) => _richiesta(
    () => http.get(Uri.parse('$baseUrl$path'), headers: _headers()),
  );

  static Future<dynamic> _post(String path, Map<String, dynamic> dati) =>
      _richiesta(
        () => http.post(
          Uri.parse('$baseUrl$path'),
          headers: _headers(),
          body: jsonEncode(dati),
        ),
      );

  // R1
  static Future<void> registrazione(
    String nome,
    String email,
    String password,
  ) async {
    await _post('/auth/registrazione', {
      'nome': nome,
      'email': email,
      'password': password,
    });
  }

  // R2
  static Future<void> login(String email, String password) async {
    final r = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    await _salvaSessione(r['token'] as String, r['azienda']['nome'] as String);
  }

  // R3
  static Future<void> logout() async {
    try {
      await _post('/auth/logout', {});
    } catch (_) {
      // anche se il server non risponde, la sessione locale viene chiusa
    }
    await _salvaSessione(null, null);
  }

  // R5
  static Future<List<Annuncio>> annunci() async {
    final lista = await _get('/annunci') as List;
    return lista
        .map((e) => Annuncio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Annuncio> annuncio(int id) async =>
      Annuncio.fromJson(await _get('/annunci/$id') as Map<String, dynamic>);

  // R4
  static Future<void> pubblicaAnnuncio(
    String titolo,
    String descrizione,
    String sede,
  ) async {
    await _post('/annunci', {
      'titolo': titolo,
      'descrizione': descrizione,
      'sede': sede,
    });
  }

  static Future<List<Annuncio>> mieiAnnunci() async {
    final lista = await _get('/miei-annunci') as List;
    return lista
        .map((e) => Annuncio.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // R6
  static Future<void> candidati({
    required int annuncioId,
    required String nome,
    required String cognome,
    required String email,
    required String cvNome,
    required Uint8List cvBytes,
  }) async {
    await _post('/annunci/$annuncioId/candidature', {
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'cvNome': cvNome,
      'cvBase64': base64Encode(cvBytes),
    });
  }

  // R7
  static Future<List<Candidatura>> candidature(int annuncioId) async {
    final lista = await _get('/annunci/$annuncioId/candidature') as List;
    return lista
        .map((e) => Candidatura.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
