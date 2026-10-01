import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../providers/history_provider.dart';
import '../providers/storage_provider.dart';
import '../services/sheets_sync_service.dart';
import '../theme/app_colors.dart';
import '../utils/french_date.dart';

/// Bouton "Envoyer vers Google Sheets" + icône de réglage du lien.
///
/// Avec [session] (écran bilan), envoie cette série. Sans (accueil), propose
/// d'abord de choisir une série terminée de l'historique.
class SheetsSendButton extends ConsumerWidget {
  final Session? session;

  const SheetsSendButton({super.key, this.session});

  /// Dialogue pour coller/modifier l'URL du Web App Apps Script. Retourne
  /// l'URL enregistrée, ou null si l'utilisateur annule.
  Future<String?> _configureUrl(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);
    final controller = TextEditingController(text: storage.sheetsWebhookUrl ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lien Google Sheets'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Colle ici l\'URL du Web App Apps Script (se termine par /exec). '
              'Voir google_apps_script/Code.gs dans le dépôt pour l\'installer sur ton Sheets.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'https://script.google.com/macros/s/.../exec'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(SheetsSyncService.normalizeUrl(controller.text)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (saved != null) {
      await storage.setSheetsWebhookUrl(saved);
    }
    return saved;
  }

  /// Liste des séries terminées de l'historique (plus récente en premier).
  Future<Session?> _pickSession(BuildContext context, WidgetRef ref) async {
    final sessions = ref.read(historyProvider).where((s) => s.isComplete).toList();
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune série terminée dans l\'historique pour l\'instant.')),
      );
      return null;
    }
    return showDialog<Session>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Quelle série envoyer ?'),
        children: [
          SizedBox(
            width: 400,
            height: 360,
            child: ListView(
              children: sessions
                  .map(
                    (s) => ListTile(
                      title: Text(
                        s.student.className.isEmpty ? s.student.name : '${s.student.name} · ${s.student.className}',
                      ),
                      subtitle: Text(formatShortFrenchDate(s.date)),
                      onTap: () => Navigator.of(dialogContext).pop(s),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);
    var url = storage.sheetsWebhookUrl;
    if (url == null || url.isEmpty) {
      url = await _configureUrl(context, ref);
      if (url == null || url.isEmpty) return;
    }
    if (!context.mounted) return;
    final toSend = session ?? await _pickSession(context, ref);
    if (toSend == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Envoi en cours...')));
    try {
      await SheetsSyncService.send(session: toSend, webhookUrl: url);
      messenger.showSnackBar(const SnackBar(content: Text('Série envoyée sur Google Sheets.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _send(context, ref),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Envoyer vers Google Sheets'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _configureUrl(context, ref),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configurer le lien Google Sheets',
        ),
      ],
    );
  }
}
