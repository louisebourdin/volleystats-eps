import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/serve.dart';
import '../models/serve_draft.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../models/student.dart';
import '../utils/id_generator.dart';
import '../widgets/court/court_geometry.dart';

class SessionState {
  final Session? session;
  final ServeDraft draft;
  /// true juste après l'enregistrement du 10e service (déclenche la
  /// navigation automatique vers l'écran de résultats).
  final bool justCompleted;
  /// true juste après avoir enregistré un service : affiche un écran de
  /// confirmation avec un bouton "Continuer" avant de passer au suivant.
  final bool awaitingContinue;

  const SessionState({
    this.session,
    this.draft = const ServeDraft(),
    this.justCompleted = false,
    this.awaitingContinue = false,
  });

  SessionState copyWith({Session? session, ServeDraft? draft, bool? justCompleted, bool? awaitingContinue}) =>
      SessionState(
        session: session ?? this.session,
        draft: draft ?? this.draft,
        justCompleted: justCompleted ?? this.justCompleted,
        awaitingContinue: awaitingContinue ?? this.awaitingContinue,
      );
}

/// Gère la série en cours : élève, services déjà enregistrés, et le
/// "brouillon" du service en cours de saisie. Reste disponible pendant toute
/// la navigation (Riverpod) tant que l'utilisateur ne démarre pas une
/// nouvelle série ou ne revient pas à l'accueil.
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  void startSession(Student student, {DateTime? date, List<String> targetZones = const []}) {
    state = SessionState(
      session: Session(
        id: newId(),
        student: student,
        date: date ?? DateTime.now(),
        serves: const [],
        targetZones: targetZones,
      ),
      draft: ServeDraft(serveTypeId: student.mainServeTypeId),
    );
  }

  /// Charge une série déjà complète (mode démonstration, ou relecture depuis
  /// l'historique) directement sur l'écran de résultats.
  void loadCompletedSession(Session session) {
    state = SessionState(session: session, draft: const ServeDraft(), justCompleted: false);
  }

  void setImpact(TapZoneResult result, double x, double y) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        result: result.result,
        zone: result.zone,
        positionX: x,
        positionY: y,
        direction: result.direction,
      ),
    );
  }

  void updateDraft(ServeDraft Function(ServeDraft current) updater) {
    state = state.copyWith(draft: updater(state.draft));
  }

  void resetDraft() {
    final defaultServeType = state.session?.student.mainServeTypeId ?? 'tennis';
    state = state.copyWith(draft: ServeDraft(serveTypeId: defaultServeType), justCompleted: false);
  }

  /// Enregistre le service courant, avance le compteur et remet le
  /// formulaire à zéro. Retourne false si le brouillon est incomplet.
  bool saveCurrentServe() {
    final session = state.session;
    final draft = state.draft;
    if (session == null || !draft.isRecordable) return false;

    final serve = Serve(
      id: newId(),
      sessionId: session.id,
      number: session.nextServeNumber,
      timestamp: DateTime.now(),
      result: draft.result!,
      zone: draft.zone,
      positionX: draft.positionX ?? 0.5,
      positionY: draft.positionY ?? 0.5,
      footFault: draft.footFault,
      serveTypeId: draft.serveTypeId,
      trajectory: draft.trajectory,
      direction: draft.direction ?? ServeDirection.centre,
      tossQuality: draft.tossQuality,
      contactQuality: draft.contactQuality,
      power: draft.power,
      intention: draft.intention,
    );

    final updatedSession = session.copyWith(serves: [...session.serves, serve]);
    state = SessionState(
      session: updatedSession,
      draft: ServeDraft(serveTypeId: draft.serveTypeId),
      justCompleted: updatedSession.isComplete,
      awaitingContinue: true,
    );
    return true;
  }

  /// Bouton "Continuer" (écran de confirmation) : referme la confirmation et
  /// laisse apparaître le formulaire du service suivant.
  void continueToNextServe() {
    state = state.copyWith(awaitingContinue: false);
  }

  /// Bouton "Retour" : ramène le dernier service enregistré dans le
  /// formulaire pour correction, sans jamais toucher aux précédents.
  void editPreviousServe() {
    final session = state.session;
    if (session == null || session.serves.isEmpty) return;
    final last = session.serves.last;
    final remaining = session.serves.sublist(0, session.serves.length - 1);
    state = SessionState(
      session: session.copyWith(serves: remaining),
      draft: ServeDraft(
        result: last.result,
        zone: last.zone,
        positionX: last.positionX,
        positionY: last.positionY,
        footFault: last.footFault,
        serveTypeId: last.serveTypeId,
        trajectory: last.trajectory,
        direction: last.direction,
        tossQuality: last.tossQuality,
        contactQuality: last.contactQuality,
        power: last.power,
        intention: last.intention,
      ),
    );
  }

  void clear() {
    state = const SessionState();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) => SessionNotifier());
