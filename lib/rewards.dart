import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data.dart';
import 'widgets.dart';

BrasisRecord? equippedStyle(Journey data) => data.rewards
    .where((r) => r['achievement_id'] == data.profile['equipped_reward'])
    .firstOrNull;

class RewardAvatar extends StatelessWidget {
  final Journey data;
  const RewardAvatar({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final style = equippedStyle(data);
    final color = style == null ? forest : Color((style['color'] as num).toInt());
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: color, width: 4)),
        child: CircleAvatar(radius: 42, backgroundColor: cream,
          child: style == null
            ? const Icon(Icons.face_rounded, size: 60, color: forest)
            : Text(style['emoji'] as String, style: const TextStyle(fontSize: 44))),
      ),
      if (style != null) ...[
        const SizedBox(height: 12),
        Text(style['profile_title'] as String, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      ],
    ]);
  }
}

class RewardsCollection extends StatefulWidget {
  final Journey data;
  final Future<void> Function() reload;
  const RewardsCollection({super.key, required this.data, required this.reload});
  @override
  State<RewardsCollection> createState() => _RewardsCollectionState();
}

class _RewardsCollectionState extends State<RewardsCollection> {
  bool busy = false;
  Future<void> equip(String? id) async {
    setState(() => busy = true);
    try {
      await Supabase.instance.client.rpc('equip_cultural_reward',
        params: {'p_reward_id': id});
      await widget.reload();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visual do perfil atualizado!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openSource(String source) async {
    try {
      if (!await launchUrl(Uri.parse(source), mode: LaunchMode.externalApplication)) {
        throw StateError('Não foi possível abrir a fonte.');
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a fonte. Tente novamente.')));
    }
  }

  void showCard(BrasisRecord reward) {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text('${reward['emoji']} ${reward['card_title']}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CURIOSIDADE EXTRA · COLECIONÁVEL',
            style: TextStyle(color: forest, fontSize: 10, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Text(reward['card_body'] as String, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 16),
          Text('Desbloqueado por: ${reward['name']}', style: const TextStyle(fontSize: 12)),
          TextButton.icon(onPressed: () => openSource(reward['source_url'] as String),
            icon: const Icon(Icons.open_in_new_rounded), label: const Text('Ler no Iphan')),
        ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Guardar na coleção'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Minha bagagem de prêmios',
        'Cada conquista libera um visual com avatar, moldura e título, além de uma curiosidade extra.'),
      Text('${data.rewards.length}/${data.achievements.length} conjuntos liberados',
        style: const TextStyle(color: forest, fontWeight: FontWeight.w800)),
      if (data.rewards.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 14),
        child: Text('Sua primeira missão já rende uma recompensa. Bora embarcar!',
          style: TextStyle(color: muted))),
      const SizedBox(height: 12),
      ...data.achievements.map((a) {
        final reward = data.rewards.where((r) => r['achievement_id'] == a['id']).firstOrNull;
        final unlocked = reward != null;
        final equipped = unlocked && data.profile['equipped_reward'] == a['id'];
        final color = reward == null ? muted : Color((reward['color'] as num).toInt());
        return Container(
          margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: unlocked ? cream : const Color(0xFFF0F0E9),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: equipped ? color : const Color(0xFFE0DFD0), width: equipped ? 2 : 1)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(reward?['emoji'] as String? ?? '🔒', style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(child: Text(a['name'] as String,
                style: TextStyle(fontSize: 17, color: color, fontWeight: FontWeight.w900))),
              if (equipped) const Icon(Icons.check_circle_rounded, color: forest),
            ]),
            const SizedBox(height: 10),
            Text(reward != null ? reward['profile_title'] as String : a['description'] as String,
              style: const TextStyle(color: ink, height: 1.5)),
            const SizedBox(height: 12),
            if (reward != null) Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: busy || equipped ? null : () => equip(a['id'] as String),
                icon: const Icon(Icons.palette_rounded),
                label: Text(equipped ? 'Equipado' : busy ? 'Salvando...' : 'Usar no perfil')),
              OutlinedButton.icon(onPressed: () => showCard(reward),
                icon: const Icon(Icons.style_rounded), label: const Text('Abrir curiosidade')),
            ]) else const Text('🔒 Visual + card surpresa',
              style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          ]),
        );
      }),
      if (data.profile['equipped_reward'] != null)
        TextButton(onPressed: busy ? null : () => equip(null), child: const Text('Voltar ao visual original')),
    ]);
  }
}
