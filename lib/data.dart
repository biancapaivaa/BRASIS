import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef BrasisRecord = Map<String, dynamic>;

class RegionInfo {
  final int order;
  final String name, tag, headline, description, sticker;
  final Color color, light;
  const RegionInfo(
    this.order,
    this.name,
    this.tag,
    this.headline,
    this.description,
    this.sticker,
    this.color,
    this.light,
  );
}

const regions = [
  RegionInfo(
    1,
    'Norte',
    'RITMOS & SABERES',
    'Bora começar\npelo Norte?',
    'Carimbó, cuias e sabores paraenses: sua primeira parada tem muita história para contar.',
    'NO',
    Color(0xFF245C45),
    Color(0xFFDDECCB),
  ),
  RegionInfo(
    2,
    'Nordeste',
    'VERSOS & CORES',
    'Tem história\nnesse gingado!',
    'Entre no passo do frevo, descubra o cordel e conheça o ofício das baianas de acarajé.',
    'NE',
    Color(0xFFBA4A32),
    Color(0xFFFFDABD),
  ),
  RegionInfo(
    3,
    'Centro-Oeste',
    'ENCONTROS & MEMÓRIAS',
    'No coração\ndos Brasis.',
    'A viola de cocho, as festas de Goiás e a arquitetura de Brasília esperam por você.',
    'CO',
    Color(0xFF916112),
    Color(0xFFF8E5A4),
  ),
  RegionInfo(
    4,
    'Sudeste',
    'BATUQUES & HISTÓRIAS',
    'Cada esquina,\numa descoberta.',
    'Percorra os caminhos do jongo, do samba e dos saberes dos queijos artesanais mineiros.',
    'SE',
    Color(0xFF287C9B),
    Color(0xFFD6EDF2),
  ),
  RegionInfo(
    5,
    'Sul',
    'RODAS & TRADIÇÕES',
    'A próxima roda\njá vai começar.',
    'Fandango caiçara, chimarrão e boi de mamão: descubra mais histórias do Sul.',
    'SU',
    Color(0xFF745293),
    Color(0xFFE9DFF4),
  ),
];

class Journey {
  final BrasisRecord profile;
  final List<BrasisRecord> missions, progress, achievements, unlocked, ranking;
  Journey(
    this.profile,
    this.missions,
    this.progress,
    this.achievements,
    this.unlocked,
    this.ranking,
  );
  int get points => (profile['points'] as num).toInt();
  int get completed =>
      missions.where((m) => status(m['id'] as int) == 'completed').length;
  int get level => points ~/ 300 + 1;
  double get levelProgress => (points % 300) / 300;
  List<BrasisRecord> inRegion(int order) =>
      missions.where((m) => m['region_order'] == order).toList();
  int completedIn(int order) =>
      inRegion(order)
          .where((m) => status(m['id'] as int) == 'completed')
          .length;
  bool regionDone(int order) =>
      inRegion(order).isNotEmpty &&
      completedIn(order) == inRegion(order).length;
  bool regionOpen(int order) =>
      order == 1 ||
      regions.where((r) => r.order < order).every((r) => regionDone(r.order));
  int get visited => regions.where((r) => regionDone(r.order)).length;
  RegionInfo get currentRegion => regions.firstWhere(
    (r) => !regionDone(r.order),
    orElse: () => regions.last,
  );
  BrasisRecord? get nextMission {
    final pending = inRegion(currentRegion.order)
      .where((m) => status(m['id'] as int) != 'completed')
      .toList()
    ..sort((a, b) => missionSequence(a).compareTo(missionSequence(b)));

    return pending.firstOrNull;
  }
  String status(int id) =>
      progress
          .where((r) => r['mission_id'] == id)
          .map((r) => r['status'] as String)
          .firstOrNull ??
      'available';
  bool canPlay(BrasisRecord mission) => missions
      .where((m) => missionSequence(m) < missionSequence(mission))
      .every((m) => status(m['id'] as int) == 'completed');
  bool hasBadge(String id) => unlocked.any((r) => r['achievement_id'] == id);
  int get badgeCount =>
      achievements.where((a) => hasBadge(a['id'] as String)).length;
}

int missionSequence(BrasisRecord m) =>
    (m['region_order'] as int) * 100 + (m['step_order'] as int);

class BrasisRepository {
  final SupabaseClient client;
  BrasisRepository(this.client);
  Future<Journey> load() async {
    final uid = client.auth.currentUser!.id;
    final results = await Future.wait<dynamic>([
      client.from('profiles').select().eq('id', uid).single(),
      client
          .from('missions')
          .select()
          .eq('active', true)
          .order('region_order')
          .order('step_order'),
      client.from('user_missions').select().eq('user_id', uid),
      client.from('achievements').select().eq('active', true).order('target'),
      client.from('user_achievements').select().eq('user_id', uid),
      client.rpc('leaderboard'),
    ]);
    List<BrasisRecord> rows(int i) => (results[i] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
    return Journey(
      Map<String, dynamic>.from(results[0] as Map),
      rows(1),
      rows(2),
      rows(3),
      rows(4),
      rows(5),
    );
  }

  Future<BrasisRecord> act(
    int id, {
    required bool complete,
    int? answer,
    String note = '',
  }) async => Map<String, dynamic>.from(
    await client.rpc(
      'mission_action',
      params: {
        'p_mission_id': id,
        'p_complete': complete,
        'p_answer': answer,
        'p_note': note,
      },
    ) as Map,
  );
}

String statusLabel(String status) => switch (status) {
  'completed' => 'Carimbada!',
  'in_progress' => 'Em andamento',
  _ => 'Pronta para jogar',
};
String friendlyError(Object error) {
  if (error is AuthException) {
    final text = error.message.toLowerCase();
    if (text.contains('invalid login')) return 'E-mail ou senha incorretos.';
    if (text.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (text.contains('already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (text.contains('rate limit') || text.contains('too many')) {
      return 'Muitas tentativas. Aguarde alguns minutos.';
    }
    if (text.contains('password')) {
      return 'Use uma senha forte, com pelo menos 8 caracteres.';
    }
    return 'Não foi possível entrar. Confira os dados e tente novamente.';
  }
  if (error is PostgrestException && error.code == 'P0001') {
    return error.message;
  }
  return 'Ops! A conexão deu uma pausa. Confira a internet e tente novamente. Se o erro continuar, confira se executou o SQL da versão cultural.';
}
