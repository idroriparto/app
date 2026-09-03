import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Repository pubblico da cui l'app legge esclusivamente le release pubblicate.
const githubRepository = 'idroriparto/idroriparto';

/// Cadenza del controllo automatico. Un controllo manuale la ignora.
const updateCheckInterval = Duration(days: 7);

final _latestReleaseUri = Uri(
  scheme: 'https',
  host: 'api.github.com',
  path: '/repos/$githubRepository/releases/latest',
);

final _releasesPageUri = Uri(
  scheme: 'https',
  host: 'github.com',
  path: '/$githubRepository/releases',
);

typedef CurrentVersionReader = Future<String> Function();

/// Piattaforma utile a scegliere il CTA corretto senza introdurre dipendenze
/// condizionali a `dart:io` (l'app supporta anche il web).
enum UpdatePlatform { android, ios, linux, web, other }

UpdatePlatform get currentUpdatePlatform {
  if (kIsWeb) return UpdatePlatform.web;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => UpdatePlatform.android,
    TargetPlatform.iOS => UpdatePlatform.ios,
    TargetPlatform.linux => UpdatePlatform.linux,
    _ => UpdatePlatform.other,
  };
}

/// Esito di una richiesta di aggiornamento.
enum UpdateCheckStatus {
  updateAvailable,
  upToDate,
  noRelease,
  skippedDisabled,
  skippedNotDue,
  failed,
}

class UpdateCheckResult {
  const UpdateCheckResult._(this.status, {this.release, this.message});

  const UpdateCheckResult.updateAvailable(GitHubRelease release)
    : this._(UpdateCheckStatus.updateAvailable, release: release);

  const UpdateCheckResult.upToDate(GitHubRelease release)
    : this._(UpdateCheckStatus.upToDate, release: release);

  const UpdateCheckResult.noRelease() : this._(UpdateCheckStatus.noRelease);

  const UpdateCheckResult.skippedDisabled()
    : this._(UpdateCheckStatus.skippedDisabled);

  const UpdateCheckResult.skippedNotDue()
    : this._(UpdateCheckStatus.skippedNotDue);

  const UpdateCheckResult.failed([String? message])
    : this._(UpdateCheckStatus.failed, message: message);

  final UpdateCheckStatus status;
  final GitHubRelease? release;
  final String? message;

  bool get hasUpdate => status == UpdateCheckStatus.updateAvailable;
  bool get isFailure => status == UpdateCheckStatus.failed;
  bool get wasChecked =>
      status == UpdateCheckStatus.updateAvailable ||
      status == UpdateCheckStatus.upToDate ||
      status == UpdateCheckStatus.noRelease ||
      status == UpdateCheckStatus.failed;
}

/// Informazioni della release GitHub necessarie all'interfaccia.
///
/// L'URL viene accettato soltanto se HTTPS e ospitato da GitHub: la risposta
/// dell'API non può quindi trasformare il pulsante di aggiornamento in un link
/// arbitrario.
class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.version,
    required this.name,
    required this.notes,
    required this.publishedAt,
    required this.releaseUri,
    required this.assets,
  });

  final String tagName;
  final AppVersion version;
  final String name;
  final String notes;
  final DateTime? publishedAt;
  final Uri releaseUri;
  final List<GitHubReleaseAsset> assets;

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final tagName = _string(json['tag_name']);
    final version = AppVersion.tryParse(tagName);
    if (version == null) {
      throw const FormatException(
        'La tag della release non è una versione SemVer.',
      );
    }

    final releaseUri = _trustedUri(json['html_url']) ?? _releasesPageUri;
    final rawAssets = json['assets'];
    final assets = rawAssets is List
        ? rawAssets
              .whereType<Map>()
              .map(
                (asset) => GitHubReleaseAsset.fromJson(
                  Map<String, dynamic>.from(asset),
                ),
              )
              .where((asset) => asset.downloadUri != null)
              .toList(growable: false)
        : const <GitHubReleaseAsset>[];

    return GitHubRelease(
      tagName: tagName,
      version: version,
      name: _string(json['name']).isEmpty ? tagName : _string(json['name']),
      notes: _string(json['body']),
      publishedAt: DateTime.tryParse(_string(json['published_at'])),
      releaseUri: releaseUri,
      assets: assets,
    );
  }

  Map<String, dynamic> toJson() => {
    'tagName': tagName,
    'name': name,
    'notes': notes,
    'publishedAt': publishedAt?.toIso8601String(),
    'releaseUri': releaseUri.toString(),
    'assets': assets.map((asset) => asset.toJson()).toList(),
  };

  factory GitHubRelease.fromStoredJson(Map<String, dynamic> json) {
    final tagName = _string(json['tagName']);
    final version = AppVersion.tryParse(tagName);
    if (version == null) {
      throw const FormatException('Release memorizzata non valida.');
    }
    final releaseUri = _trustedUri(json['releaseUri']) ?? _releasesPageUri;
    final rawAssets = json['assets'];
    final assets = rawAssets is List
        ? rawAssets
              .whereType<Map>()
              .map(
                (asset) => GitHubReleaseAsset.fromStoredJson(
                  Map<String, dynamic>.from(asset),
                ),
              )
              .where((asset) => asset.downloadUri != null)
              .toList(growable: false)
        : const <GitHubReleaseAsset>[];
    return GitHubRelease(
      tagName: tagName,
      version: version,
      name: _string(json['name']).isEmpty ? tagName : _string(json['name']),
      notes: _string(json['notes']),
      publishedAt: DateTime.tryParse(_string(json['publishedAt'])),
      releaseUri: releaseUri,
      assets: assets,
    );
  }

  GitHubReleaseAsset? apkAsset() {
    for (final asset in assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) return asset;
    }
    return null;
  }

  /// Android riceve il link diretto all'APK pubblicato. Per le altre
  /// piattaforme la pagina della release evita di proporre un pacchetto non
  /// adatto (ad es. .deb su Fedora) e spiega i passaggi disponibili.
  Uri actionUriFor(UpdatePlatform platform) {
    if (platform == UpdatePlatform.android) {
      return apkAsset()?.downloadUri ?? releaseUri;
    }
    return releaseUri;
  }

  String actionLabelFor(UpdatePlatform platform) {
    if (platform == UpdatePlatform.android && apkAsset() != null) {
      return 'Scarica APK';
    }
    return 'Apri la release';
  }

  String installationHintFor(UpdatePlatform platform) {
    return switch (platform) {
      UpdatePlatform.android =>
        apkAsset() != null
            ? 'Il download si aprirà nel browser. Android chiederà conferma prima dell’installazione.'
            : 'Apri la release per scaricare il pacchetto adatto al tuo dispositivo.',
      UpdatePlatform.linux =>
        'Nella pagina della release puoi scegliere il pacchetto .deb o .rpm per la tua distribuzione.',
      UpdatePlatform.ios =>
        'Le versioni iOS sono distribuite tramite App Store o TestFlight, quando disponibili.',
      UpdatePlatform.web =>
        'La versione web si aggiorna al successivo caricamento della pagina.',
      UpdatePlatform.other =>
        'Apri la pagina della release per scaricare il pacchetto disponibile.',
    };
  }
}

class GitHubReleaseAsset {
  const GitHubReleaseAsset({required this.name, required this.downloadUri});

  final String name;
  final Uri? downloadUri;

  factory GitHubReleaseAsset.fromJson(Map<String, dynamic> json) =>
      GitHubReleaseAsset(
        name: _string(json['name']),
        downloadUri: _trustedUri(json['browser_download_url']),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'downloadUri': downloadUri?.toString(),
  };

  factory GitHubReleaseAsset.fromStoredJson(Map<String, dynamic> json) =>
      GitHubReleaseAsset(
        name: _string(json['name']),
        downloadUri: _trustedUri(json['downloadUri']),
      );
}

/// Client di sola lettura per l'endpoint ufficiale GitHub `releases/latest`.
/// Il [client] e il lettore della versione sono iniettabili per mantenere la
/// logica verificabile senza rete o plugin di piattaforma nei test.
class UpdateService {
  UpdateService({
    http.Client? client,
    CurrentVersionReader? currentVersionReader,
    UpdatePlatform? platform,
    this.timeout = const Duration(seconds: 12),
  }) : _httpClient = client,
       _currentVersionReader = currentVersionReader ?? _readPackageVersion,
       platform = platform ?? currentUpdatePlatform;

  final http.Client? _httpClient;
  final CurrentVersionReader _currentVersionReader;
  final UpdatePlatform platform;
  final Duration timeout;

  Future<UpdateCheckResult> check() async {
    final ownClient = _httpClient == null ? http.Client() : null;
    final client = _httpClient ?? ownClient!;

    try {
      final currentRaw = await _currentVersionReader();
      final currentVersion = AppVersion.tryParse(currentRaw);
      if (currentVersion == null) {
        return const UpdateCheckResult.failed(
          'La versione installata non è leggibile.',
        );
      }

      final response = await client
          .get(
            _latestReleaseUri,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 404) {
        return const UpdateCheckResult.noRelease();
      }
      if (response.statusCode != 200) {
        return const UpdateCheckResult.failed(
          'GitHub non ha risposto correttamente.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Risposta GitHub non valida.');
      }
      final release = GitHubRelease.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (release.version.compareTo(currentVersion) > 0) {
        return UpdateCheckResult.updateAvailable(release);
      }
      return UpdateCheckResult.upToDate(release);
    } on TimeoutException {
      return const UpdateCheckResult.failed(
        'Il controllo aggiornamenti ha richiesto troppo tempo.',
      );
    } on FormatException {
      return const UpdateCheckResult.failed(
        'La risposta della release non è valida.',
      );
    } catch (_) {
      // Il controllo periodico non deve interrompere il flusso dell'app né
      // mostrare dettagli tecnici della rete all'utente.
      return const UpdateCheckResult.failed(
        'Impossibile contattare GitHub in questo momento.',
      );
    } finally {
      ownClient?.close();
    }
  }

  Future<bool> open(GitHubRelease release) async {
    try {
      return await launchUrl(
        release.actionUriFor(platform),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<String> _readPackageVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}

/// Comparatore SemVer minimale e senza dipendenze: accetta `v1.2.3`,
/// `1.2.3` e i normali suffissi prerelease/build.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
  });

  final int major;
  final int minor;
  final int patch;
  final String? preRelease;

  static final _pattern = RegExp(
    r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
    r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
  );

  static AppVersion? tryParse(String raw) {
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    final preRelease = match.group(4);
    // SemVer non consente zeri iniziali negli identificatori prerelease
    // puramente numerici (es. `1.0.0-01`).
    if (preRelease != null &&
        preRelease
            .split('.')
            .any(
              (part) =>
                  part.length > 1 &&
                  part.startsWith('0') &&
                  int.tryParse(part) != null,
            )) {
      return null;
    }
    return AppVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      preRelease: preRelease,
    );
  }

  @override
  int compareTo(AppVersion other) {
    var comparison = major.compareTo(other.major);
    if (comparison != 0) return comparison;
    comparison = minor.compareTo(other.minor);
    if (comparison != 0) return comparison;
    comparison = patch.compareTo(other.patch);
    if (comparison != 0) return comparison;

    if (preRelease == null && other.preRelease == null) return 0;
    if (preRelease == null) return 1;
    if (other.preRelease == null) return -1;
    return _comparePreRelease(preRelease!, other.preRelease!);
  }

  static int _comparePreRelease(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    final length = aParts.length < bParts.length
        ? aParts.length
        : bParts.length;
    for (var index = 0; index < length; index++) {
      final aPart = aParts[index];
      final bPart = bParts[index];
      if (aPart == bPart) continue;

      final aNumber = int.tryParse(aPart);
      final bNumber = int.tryParse(bPart);
      if (aNumber != null && bNumber != null) return aNumber.compareTo(bNumber);
      if (aNumber != null) return -1;
      if (bNumber != null) return 1;
      return aPart.compareTo(bPart);
    }
    return aParts.length.compareTo(bParts.length);
  }

  @override
  String toString() {
    final suffix = preRelease == null ? '' : '-$preRelease';
    return '$major.$minor.$patch$suffix';
  }
}

String _string(Object? value) => value is String ? value.trim() : '';

Uri? _trustedUri(Object? raw) {
  final value = _string(raw);
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https') return null;
  final host = uri.host.toLowerCase();
  if (host == 'github.com' || host.endsWith('.github.com')) return uri;
  return null;
}
