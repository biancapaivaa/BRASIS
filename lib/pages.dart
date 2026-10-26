import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'widgets.dart';
import 'rewards.dart';

class JourneyView extends StatefulWidget {
  final Widget Function(BuildContext, Journey, Future<void> Function()) builder;
  const JourneyView({super.key, required this.builder});
  @override
  State<JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends State<JourneyView> {
  late Future<Journey> future;
  @override
  void initState() {
    super.initState();
    future = BrasisRepository(Supabase.instance.client).load();
  }

  Future<void> reload() async {
    final next = BrasisRepository(Supabase.instance.client).load();
    setState(() => future = next);
    try {
      await next;
    } catch (_) {
      /* O FutureBuilder mostra a tentativa de recuperação. */
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Journey>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(color: forest));
      }
      if (snapshot.hasError) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 52, color: clay),
                const SizedBox(height: 16),
                const Text(
                  'Uma pausa no caminho.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  friendlyError(snapshot.error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                GameButton(
                  label: 'Tentar de novo',
                  onPressed: reload,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: reload,
        color: forest,
        child: widget.builder(context, snapshot.data!, reload),
      );
    },
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => JourneyView(
    key: ValueKey(Supabase.instance.client.auth.currentUser!.id),
    builder: (context, data, reload) {
      final current = data.currentRegion;
      return HomeContent(
        data: data,
        onRegion: (order) => context.go('/region/$order'),
        onContinue: () => context.go(
          data.nextMission == null
              ? '/achievements'
              : '/region/${current.order}',
        ),
        onPassport: () => context.go('/achievements'),
        current: current,
      );
    },
  );
}

// Sem acesso direto à sessão: facilita testes e inspeção visual do mesmo layout.
class HomeContent extends StatelessWidget {
  final Journey data;
  final RegionInfo current;
  final void Function(int) onRegion;
  final VoidCallback onContinue, onPassport;
  const HomeContent({
    super.key,
    required this.data,
    required this.current,
    required this.onRegion,
    required this.onContinue,
    required this.onPassport,
  });
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEU DIÁRIO DE DESCOBERTAS',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bora viajar, ${data.profile['nickname']}?',
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: ink,
                    letterSpacing: -.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Sticker('${data.points} XP', icon: Icons.bolt_rounded),
        ],
      ),
      const SizedBox(height: 22),
      Container(
        decoration: BoxDecoration(
          color: current.light,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: current.color.withValues(alpha: .16),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Sticker(
                    data.nextMission == null
                        ? 'JORNADA COMPLETA'
                        : 'CAPÍTULO 0${current.order}',
                    color: current.color,
                    foreground: cream,
                    icon: Icons.explore_rounded,
                  ),
                  Text(
                    '✦ ${current.name}',
                    style: TextStyle(
                      color: current.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            RegionalArt(region: current.order, height: 200),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.nextMission == null
                        ? 'Você descobriu\nmuitos Brasis!'
                        : current.headline,
                    style: TextStyle(
                      color: current.color,
                      fontSize: 31,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.nextMission == null
                        ? 'Cinco regiões carimbadas. Seu passaporte está cheio de histórias!'
                        : current.description,
                    style: TextStyle(
                      color: current.color,
                      height: 1.55,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 21),
                  GameButton(
                    label: data.nextMission == null
                        ? 'Ver meu passaporte'
                        : data.completed == 0
                        ? 'Começar minha viagem'
                        : 'Continuar a aventura',
                    onPressed: onContinue,
                    icon: Icons.east_rounded,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: data.inRegion(current.order).isEmpty
                                ? 0
                                : data.completedIn(current.order) /
                                      data.inRegion(current.order).length,
                            color: current.color,
                            backgroundColor: Colors.white.withValues(
                              alpha: .65,
                            ),
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${data.completedIn(current.order)}/${data.inRegion(current.order).length} paradas',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: current.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      SectionTitle(
        'Seu roteiro pelos Brasis',
        'Uma parada de cada vez. Uma história de cada lugar.',
        trailing: TextButton(
          onPressed: onPassport,
          child: const Icon(Icons.menu_book_rounded, color: forest),
        ),
      ),
      if (data.missions.isEmpty)
        const Text(
          'As paradas ainda não chegaram. Confira se executou o SQL cultural.',
        ),
      ...regions.expand((r) {
        final open = data.regionOpen(r.order);
        final done = data.regionDone(r.order);
        return [
          if (r.order > 1) const TrailConnector(),
          _RegionTile(
            region: r,
            open: open,
            done: done,
            count: data.completedIn(r.order),
            total: data.inRegion(r.order).length,
            onTap: () => onRegion(r.order),
          ),
        ];
      }),
      const SizedBox(height: 25),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_rounded, color: clay),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'As culturas atravessam fronteiras. Cada parada é uma janela para conhecer pessoas, não um resumo de toda a região.',
                style: TextStyle(fontSize: 12, height: 1.6, color: forest),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RegionTile extends StatelessWidget {
  final RegionInfo region;
  final bool open, done;
  final int count, total;
  final VoidCallback onTap;
  const _RegionTile({
    required this.region,
    required this.open,
    required this.done,
    required this.count,
    required this.total,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: open ? Colors.white : const Color(0xFFF0F0E7),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(
        color: done ? region.color : const Color(0xFFE0E4D4),
        width: done ? 2 : 1.5,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Transform.rotate(
              angle: region.order.isEven ? .07 : -.07,
              child: Container(
                width: 64,
                height: 65,
                decoration: BoxDecoration(
                  color: open ? region.light : const Color(0xFFE0E4D8),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Center(
                  child: open
                      ? Text(
                          region.sticker,
                          style: TextStyle(
                            color: region.color,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : const Icon(Icons.lock_rounded, color: muted, size: 27),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAPÍTULO 0${region.order}',
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    region.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                      color: open ? ink : muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done
                        ? 'Carimbo conquistado!'
                        : open
                        ? '$count/$total paradas · vamos nessa!'
                        : 'Conclua a região anterior',
                    style: TextStyle(
                      fontSize: 11,
                      color: done ? region.color : muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              done
                  ? Icons.verified_rounded
                  : open
                  ? Icons.arrow_forward_rounded
                  : Icons.lock_outline_rounded,
              color: open ? region.color : muted,
              size: 23,
            ),
          ],
        ),
      ),
    ),
  );
}

class RegionPage extends StatelessWidget {
  final int order;
  const RegionPage({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    if (order < 1 || order > 5) {
      return const Center(child: Text('Região não encontrada.'));
    }
    final r = regions[order - 1];
    return JourneyView(
      builder: (context, data, reload) {
        final open = data.regionOpen(order);
        final missions = data.inRegion(order);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(22),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Meu roteiro'),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: r.light,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  RegionalArt(region: order, height: 190),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Sticker(
                          'CAPÍTULO 0$order · ${r.tag}',
                          color: r.color,
                          foreground: cream,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          r.name,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: r.color,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          r.description,
                          style: TextStyle(color: r.color, height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!open) ...[
              const Sticker(
                'O PRÓXIMO DESTINO ESTÁ GUARDADO',
                color: cream,
                icon: Icons.lock_rounded,
              ),
              const SizedBox(height: 12),
              const Text(
                'Você pode espiar as paradas. Para jogar, complete todas as missões da região anterior.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 18),
            ],
            SectionTitle(
              'Três paradas. Muitas histórias.',
              '${data.completedIn(order)}/${missions.length} missões concluídas · complete para ganhar seu carimbo.',
            ),
            if (missions.isEmpty)
              const Text(
                'Ainda não há missões. Confira a configuração do banco.',
              ),
            ...missions.map(
              (m) => MissionCard(
                mission: m,
                status: data.status(m['id'] as int),
                locked: !data.canPlay(m),
                onTap: () => context.go('/mission/${m['id']}'),
              ),
            ),
            if (data.regionDone(order)) ...[
              const SizedBox(height: 15),
              GameButton(
                label: order < 5
                    ? 'Próxima parada: ${regions[order].name}'
                    : 'Meu passaporte completo!',
                onPressed: () => context.go(
                  order < 5 ? '/region/${order + 1}' : '/achievements',
                ),
                icon: Icons.flight_takeoff_rounded,
              ),
            ],
          ],
        );
      },
    );
  }
}

class MissionPage extends StatefulWidget {
  final int? id;
  const MissionPage({super.key, required this.id});
  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  final note = TextEditingController();
  int? selected;
  bool busy = false;
  String? feedback;
  bool loadedNote = false;
  @override
  void didUpdateWidget(covariant MissionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      note.clear();
      selected = null;
      feedback = null;
      loadedNote = false;
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> action(
    Journey data,
    BrasisRecord mission,
    Future<void> Function() reload,
  ) async {
    final complete = data.status(widget.id!) == 'in_progress';
    if (complete && (selected == null || note.text.trim().length < 8)) {
      setState(
        () => feedback =
            'Escolha uma resposta e escreva ao menos 8 caracteres no diário.',
      );
      return;
    }
    setState(() {
      busy = true;
      feedback = null;
    });
    try {
      final result = await BrasisRepository(
        Supabase.instance.client,
      ).act(widget.id!, complete: complete, answer: selected, note: note.text);
      if (!mounted) return;
      if (complete && result['correct'] == false) {
        setState(
          () => feedback = 'Quase! Volte à descoberta e tente outra resposta. Você pode tentar de novo, sem perder pontos.',
        );
        return;
      }
      if (complete) {
        final region = regions[(mission['region_order'] as int) - 1];
        final regionFinished = mission['step_order'] == 3;
        final badges = (result['achievements'] as List?) ?? [];
        await showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    regionFinished ? '✦  ✺  ✦' : '✦  ★  ✦',
                    style: const TextStyle(color: clay, fontSize: 38),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    regionFinished
                        ? '${region.name}\nno seu passaporte!'
                        : 'Mais uma história\nna bagagem!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Sticker('+${result['awarded']} XP', icon: Icons.bolt_rounded),
                  const SizedBox(height: 16),
                  if (regionFinished)
                    PassportStamp(
                      region: region,
                      unlocked: true,
                      completed: 3,
                      total: 3,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    badges.isNotEmpty
                        ? '${badges.length} nova(s) conquista(s)! Visuais de perfil e cards extras liberados em Conquistas.'
                        : 'Sua descoberta foi salva no diário.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  GameButton(
                    label: 'Continuar a viagem',
                    onPressed: () => ctx.pop(),
                  ),
                ],
              ),
            ),
          ),
        );
        if (mounted) {
          context.go('/region/${mission['region_order']}');
        }
      } else {
        await reload();
      }
    } catch (e) {
      if (mounted) setState(() => feedback = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => JourneyView(
    builder: (context, data, reload) {
      final m = data.missions.where((m) => m['id'] == widget.id).firstOrNull;
      if (m == null) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Esta parada não existe.'),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Voltar ao roteiro'),
            ),
          ],
        );
      }
      final r = regions[(m['region_order'] as int) - 1];
      final status = data.status(widget.id!);
      final done = status == 'completed';
      final locked = !data.canPlay(m);
      if (!loadedNote) {
        note.text =
            (data.progress
                    .where((p) => p['mission_id'] == widget.id)
                    .firstOrNull?['note']
                as String?) ??
            '';
        loadedNote = true;
      }
      final options = (m['answer_options'] as List).cast<String>();
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/region/${r.order}'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text('Voltar para ${r.name}'),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: r.light,
              borderRadius: BorderRadius.circular(26),
            ),
            child: RegionalArt(region: r.order, height: 160),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Sticker(
                m['category'] as String,
                color: r.light,
                foreground: r.color,
              ),
              Sticker('+${m['points']} XP', icon: Icons.bolt_rounded),
              Sticker(m['difficulty'] as String, color: cream),
            ],
          ),
          const SizedBox(height: 17),
          SectionTitle(
            m['title'] as String,
            '${r.name} · Parada ${m['step_order']}/3 · ${locked ? 'Ainda bloqueada' : statusLabel(status)}',
          ),
          if (!done && !locked && status == 'available') ...[
            GameButton(
              label: 'Embarcar nesta missão',
              onPressed: busy ? null : () => action(data, m, reload),
              busy: busy,
              icon: Icons.flight_takeoff_rounded,
            ),
            const SizedBox(height: 20),
          ],
          if (locked) ...[
            const Sticker(
              'COMPLETE A PARADA ANTERIOR PARA JOGAR',
              color: cream,
              icon: Icons.lock_rounded,
            ),
            const SizedBox(height: 20),
          ],
          const _StepHeading('01', 'A descoberta', Icons.auto_stories_rounded),
          const SizedBox(height: 12),
          Text(
            m['lesson'] as String,
            style: const TextStyle(color: ink, fontSize: 16, height: 1.75),
          ),
          const SizedBox(height: 25),
          const _StepHeading(
            '02',
            'Sua vez de explorar',
            Icons.edit_note_rounded,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (m['instructions'] as List).join('\n'),
              style: const TextStyle(color: forest, height: 1.65, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: note,
            enabled: !done && !locked && status == 'in_progress' && !busy,
            maxLength: 600,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: done ? 'Sua descoberta salva' : 'Meu diário de viagem',
              hintText: 'Escreva sua resposta à atividade aqui...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          const _StepHeading('03', 'Bateu a curiosidade?', Icons.quiz_rounded),
          const SizedBox(height: 12),
          Text(
            m['quiz_question'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: ink,
            ),
          ),
          const SizedBox(height: 14),
          if (done)
            const Sticker(
              'DESAFIO CONCLUÍDO E PONTOS REGISTRADOS',
              color: Color(0xFFDDECCB),
              foreground: forest,
              icon: Icons.verified_rounded,
            )
          else
            ...options.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: selected == e.key ? r.light : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                    side: BorderSide(
                      color: selected == e.key
                          ? r.color
                          : const Color(0xFFE0E4D7),
                      width: selected == e.key ? 2 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: locked || busy || status != 'in_progress'
                        ? null
                        : () => setState(() {
                            selected = e.key;
                            feedback = null;
                          }),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: selected == e.key
                                ? r.color
                                : cream,
                            child: Text(
                              String.fromCharCode(65 + e.key),
                              style: TextStyle(
                                color: selected == e.key ? cream : ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (selected == e.key)
                            Icon(
                              Icons.check_circle_rounded,
                              color: r.color,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 15),
          if (feedback != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4D4),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(
                feedback!,
                style: const TextStyle(color: Color(0xFF8B3826), height: 1.5),
              ),
            ),
            const SizedBox(height: 18),
          ],
          GameButton(
            label: done
                ? 'Carimbada no seu diário!'
                : locked
                ? 'Complete a parada anterior'
                : status == 'in_progress'
                ? 'Conferir e ganhar meu XP'
                : 'Embarcar nesta missão',
            onPressed: done || locked || busy
                ? null
                : () => action(data, m, reload),
            busy: busy,
            icon: done ? Icons.verified_rounded : Icons.flag_rounded,
          ),
          const SizedBox(height: 18),
          const Text(
            'FONTE PARA EXPLORAR MAIS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: muted,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            m['source_url'] as String,
            style: const TextStyle(color: river, fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 15),
          const Text(
            'A viagem é virtual. Você não precisa se deslocar, gastar dinheiro ou consumir alimentos para jogar.',
            style: TextStyle(fontSize: 11, color: muted, height: 1.5),
          ),
        ],
      );
    },
  );
}

class _StepHeading extends StatelessWidget {
  final String number, title;
  final IconData icon;
  const _StepHeading(this.number, this.title, this.icon);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: forest,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: cream,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
      ),
      Icon(icon, color: clay),
    ],
  );
}

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});
  @override
  Widget build(BuildContext context) => JourneyView(
    builder: (context, data, reload) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        const Sticker(
          'COLEÇÃO DE BOAS HISTÓRIAS',
          color: cream,
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 16),
        const SectionTitle(
          'Meu passaporte',
          'Cada região completa vira um carimbo. Cada descoberta vira bagagem.',
        ),
        _PassportCollection(data: data),
        const SizedBox(height: 24),
        RewardsCollection(data: data, reload: reload),
        const SizedBox(height: 28),
        SectionTitle(
          'Conquistas da viagem',
          '${data.badgeCount} de ${data.achievements.length} desbloqueadas',
        ),
        if (data.achievements.isEmpty)
          const Text('As conquistas estão sendo preparadas.'),
        ...data.achievements.map(
          (a) => AchievementBadge(
            achievement: a,
            unlocked: data.hasBadge(a['id'] as String),
          ),
        ),
      ],
    ),
  );
}

class _PassportCollection extends StatelessWidget {
  final Journey data;
  const _PassportCollection({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cream,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFE6D8B0), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.public_rounded, color: forest),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${data.profile['nickname']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: forest,
                ),
              ),
            ),
            Text(
              '${data.visited}/5',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: forest,
              ),
            ),
          ],
        ),
        const Divider(height: 30, color: Color(0xFFDACDAB)),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth > 440 ? 3 : 2;
            return Wrap(
              spacing: 14,
              runSpacing: 17,
              children: regions
                  .map(
                    (r) => SizedBox(
                      width: (c.maxWidth - 14 * (columns - 1)) / columns,
                      child: PassportStamp(
                        region: r,
                        unlocked: data.regionDone(r.order),
                        completed: data.completedIn(r.order),
                        total: data.inRegion(r.order).length,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'UMA JORNADA DE HISTÓRIAS E CULTURAS',
          style: TextStyle(
            fontSize: 8,
            color: forest,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    ),
  );
}

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});
  @override
  Widget build(BuildContext context) => JourneyView(
    builder: (context, data, reload) {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final me = data.ranking.where((r) => r['user_id'] == uid).firstOrNull;
      final top = data.ranking
          .where((r) => (r['position'] as num) <= 3)
          .toList();
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(22),
        children: [
          const Sticker('VIAJANTES EM DESTAQUE', icon: Icons.bolt_rounded),
          const SizedBox(height: 17),
          const SectionTitle(
            'Quem tem história\npra contar?',
            'Conheça os viajantes com mais descobertas na bagagem.',
          ),
          if (top.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: forest,
                borderRadius: BorderRadius.circular(27),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: sun, size: 45),
                  const SizedBox(height: 14),
                  ...top.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: r['position'] == 1
                                ? sun
                                : r['position'] == 2
                                ? const Color(0xFFD8E0DD)
                                : const Color(0xFFDFA780),
                            child: Text(
                              '${r['position']}',
                              style: const TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${r['nickname']}',
                              style: const TextStyle(
                                color: cream,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${r['points']} XP',
                            style: const TextStyle(
                              color: sun,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (me != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: sun,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.face_rounded, color: ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seu lugar na viagem: #${me['position']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                  ),
                  Text(
                    '${me['points']} XP',
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 25),
          const SectionTitle(
            'Todo mundo a bordo',
            'Top 100 · puxe a tela para atualizar',
          ),
          if (data.ranking.isEmpty)
            const Text('Ainda não há viajantes no ranking.'),
          ...data.ranking
              .where((r) => (r['position'] as num) <= 100)
              .map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: r['user_id'] == uid ? cream : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE3E6D9)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          '#${r['position']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: forest,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${r['nickname']}${r['user_id'] == uid ? ' (você)' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${r['points']} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: forest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
          const Text(
            'Em caso de empate, o cadastro mais antigo fica à frente.',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      );
    },
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool busy = false;
  Future<void> logout() async {
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => JourneyView(
    builder: (context, data, reload) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        const SectionTitle(
          'Quem vai nessa viagem?',
          'Seu perfil de descobertas.',
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Column(
            children: [
              RewardAvatar(data: data),
              const SizedBox(height: 16),
              Text(
                '${data.profile['nickname']}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Supabase.instance.client.auth.currentUser?.email ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Sticker(
                'VIAJANTE NÍVEL ${data.level}',
                color: forest,
                foreground: cream,
                icon: Icons.explore_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ProgressCard(
          points: data.points,
          completed: data.completed,
          level: data.level,
          progress: data.levelProgress,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ProfileStat(
                '${data.visited}/5',
                'regiões carimbadas',
                Icons.public_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileStat(
                '${data.badgeCount}',
                'conquistas',
                Icons.workspace_premium_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        GameButton(
          label: 'Abrir meu passaporte',
          onPressed: () => context.go('/achievements'),
          icon: Icons.menu_book_rounded,
        ),
        const SizedBox(height: 22),
        RewardsCollection(data: data, reload: reload),
        const SizedBox(height: 22),
        const SectionTitle(
          'Meu diário',
          'Releia suas descobertas nas missões concluídas.',
        ),
        if (data.completed == 0)
          const Text(
            'Seu diário está em branco. A primeira história começa no Norte!',
            style: TextStyle(color: muted, height: 1.5),
          ),
        ...data.missions
            .where((m) => data.status(m['id'] as int) == 'completed')
            .map(
              (m) => MissionCard(
                mission: m,
                status: 'completed',
                onTap: () => context.go('/mission/${m['id']}'),
              ),
            ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: busy ? null : logout,
          icon: const Icon(Icons.logout_rounded),
          label: Text(busy ? 'Encerrando...' : 'Sair da conta'),
        ),
        const SizedBox(height: 22),
        const Text(
          'BRASIS\nUma jornada de histórias e culturas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: forest,
            height: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _ProfileStat(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE0E5D7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: clay),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
