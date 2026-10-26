import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brasis/data.dart';
import 'package:brasis/widgets.dart';
import 'package:brasis/pages.dart';

Journey sampleJourney({int done = 0}) {
  final missions = List.generate(
    15,
    (i) => <String, dynamic>{
      'id': i + 1,
      'region_order': i ~/ 3 + 1,
      'step_order': i % 3 + 1,
      'title': 'Parada cultural ${i + 1}',
      'category': 'Música',
      'difficulty': 'Fácil',
      'points': 80,
      'icon': 'music',
    },
  );
  return Journey(
    {'nickname': 'Marinho', 'points': done * 80},
    missions,
    List.generate(
      done,
      (i) => <String, dynamic>{'mission_id': i + 1, 'status': 'completed'},
    ),
    [],
    [],
    [],
  );
}

void main() {
  test(
    'A jornada libera regiões em sequência, e nunca antes das três paradas',
    () {
      final start = sampleJourney();
      expect(start.regionOpen(1), isTrue);
      expect(start.regionOpen(2), isFalse);
      expect(start.canPlay(start.missions[0]), isTrue);
      expect(start.canPlay(start.missions[1]), isFalse);
      final northDone = sampleJourney(done: 3);
      expect(northDone.regionDone(1), isTrue);
      expect(northDone.regionOpen(2), isTrue);
      expect(northDone.regionOpen(3), isFalse);
      expect(northDone.nextMission?['id'], 4);
      expect(northDone.visited, 1);
      expect(sampleJourney(done: 15).nextMission, isNull);
      expect(sampleJourney(done: 15).visited, 5);
    },
  );
  testWidgets(
    'Parada bloqueada mostra um cadeado e continua permitindo espiar',
    (tester) async {
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissionCard(
              mission: sampleJourney().missions.first,
              status: 'available',
              locked: true,
              onTap: () => opened = true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('Libere a parada anterior'), findsOneWidget);
      await tester.tap(find.text('Parada cultural 1'));
      expect(opened, isTrue);
    },
  );
  testWidgets('Carimbo só aparece conquistado após completar a região', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PassportStamp(
            region: regions.first,
            unlocked: false,
            completed: 2,
            total: 3,
          ),
        ),
      ),
    );
    expect(find.text('2/3 paradas'), findsOneWidget);
    expect(find.text('EU DESCOBRI!'), findsNothing);
  });
  testWidgets('Home cultural cabe em celular estreito e com texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: HomeContent(
              data: sampleJourney(),
              current: regions.first,
              onRegion: (_) {},
              onContinue: () {},
              onPassport: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Bora viajar, Marinho?'), findsOneWidget);
  });
}
