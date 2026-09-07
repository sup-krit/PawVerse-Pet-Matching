import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawverse_matching/domain.dart';
import 'package:pawverse_matching/demo_repository.dart';
import 'package:pawverse_matching/matching_view_model.dart';

class FailingRepository extends DemoMatchingRepository {
  FailingRepository() : super(delay: Duration.zero);
  bool fail = true;
  final gate = Completer<void>();
  @override
  Future<MatchingSnapshot> load(String id, DiscoveryFilter filter) async {
    await gate.future;
    if (fail) throw const DemoFailure('Test outage');
    return super.load(id, filter);
  }
}

void main() {
  late DemoMatchingRepository repo;
  setUp(() => repo = DemoMatchingRepository(delay: Duration.zero));
  test(
    'pending like does not open a match; reciprocal retry creates exactly one',
    () async {
      expect(await repo.swipe('pet-milo', 'mochi', like: true), false);
      expect(
        (await repo.load('pet-milo', const DiscoveryFilter())).matches,
        isEmpty,
      );
      await Future.wait([
        repo.swipe('pet-milo', 'poppy', like: true),
        repo.swipe('pet-milo', 'poppy', like: true),
      ]);
      expect(
        (await repo.load('pet-milo', const DiscoveryFilter())).matches,
        hasLength(1),
      );
    },
  );
  test(
    'pass never creates match and pets keep separate swipe contexts',
    () async {
      await repo.swipe('pet-milo', 'poppy', like: false);
      final milo = await repo.load('pet-milo', const DiscoveryFilter());
      final luna = await repo.load('pet-luna', const DiscoveryFilter());
      expect(milo.matches, isEmpty);
      expect(milo.candidates.any((p) => p.id == 'poppy'), false);
      expect(luna.candidates.any((p) => p.id == 'poppy'), true);
      await repo.swipe('pet-luna', 'mochi', like: true);
      expect(
        (await repo.load('pet-milo', const DiscoveryFilter())).matches,
        isEmpty,
      );
    },
  );
  test('species and radius filter use public distance only', () async {
    final cats = await repo.load(
      'pet-milo',
      const DiscoveryFilter(species: Species.cat, distanceKm: 5),
    );
    expect(cats.candidates.map((p) => p.id), ['mochi']);
    expect(
      (await repo.load(
        'pet-milo',
        const DiscoveryFilter(distanceKm: 1),
      )).candidates,
      isEmpty,
    );
  });
  test('message retries dedupe and cross pet membership is rejected', () async {
    await repo.swipe('pet-milo', 'poppy', like: true);
    await repo.send('pet-milo', 'pet-milo:poppy', 'Hello', 'm1');
    await repo.send('pet-milo', 'pet-milo:poppy', 'Hello', 'm1');
    expect(
      (await repo.load(
        'pet-milo',
        const DiscoveryFilter(),
      )).matches.single.messages,
      hasLength(1),
    );
    await expectLater(
      repo.send('pet-luna', 'pet-milo:poppy', 'Hello', 'm2'),
      throwsA(isA<DemoFailure>()),
    );
    await expectLater(
      repo.send('pet-milo', 'pet-milo:poppy', 'Changed', 'm1'),
      throwsA(isA<DemoFailure>()),
    );
    await expectLater(
      repo.send('pet-milo', 'absent', 'No match', 'm1'),
      throwsA(isA<DemoFailure>()),
    );
  });
  test('block closes sends and hides all pets owned by counterpart across contexts', () async {
    await repo.swipe('pet-milo', 'poppy', like: true);
    await repo.close('pet-milo', 'pet-milo:poppy', block: true);
    await expectLater(
      repo.send('pet-milo', 'pet-milo:poppy', 'Hello', 'm1'),
      throwsA(isA<DemoFailure>()),
    );
    for (final own in ['pet-milo', 'pet-luna']) {
      expect(
        (await repo.load(
          own,
          const DiscoveryFilter(),
        )).candidates.any((p) => p.ownerId == 'owner-june'),
        false,
      );
    }
    await expectLater(
      repo.swipe('pet-luna', 'teddy', like: true),
      throwsA(isA<DemoFailure>()),
    );
  });
  test(
    'unmatch rejects future sends and rematch; reset restores discovery',
    () async {
      await repo.swipe('pet-milo', 'poppy', like: true);
      await repo.close('pet-milo', 'pet-milo:poppy', block: false);
      expect(await repo.swipe('pet-milo', 'poppy', like: true), false);
      await expectLater(
        repo.send('pet-milo', 'pet-milo:poppy', 'Hi', 'm1'),
        throwsA(isA<DemoFailure>()),
      );
      await repo.reset();
      expect(
        (await repo.load('pet-milo', const DiscoveryFilter())).matches,
        isEmpty,
      );
      expect(
        (await repo.load(
          'pet-milo',
          const DiscoveryFilter(),
        )).candidates.first.id,
        'poppy',
      );
    },
  );
  test(
    'view model exposes loading, error and retry success with fake repository',
    () async {
      final fake = FailingRepository();
      final model = MatchingViewModel(fake);
      final loading = model.load();
      expect(model.loading, true);
      fake.gate.complete();
      await loading;
      expect(model.loading, false);
      expect(model.error, isNotNull);
      fake.fail = false;
      await model.load();
      expect(model.error, isNull);
      expect(model.snapshot!.candidates, isNotEmpty);
      model.dispose();
    },
  );
  test(
    'view model pet switch scopes filters and blocks double submissions',
    () async {
      final model = MatchingViewModel(repo);
      await model.load();
      await model.applyFilter(
        const DiscoveryFilter(species: Species.dog, distanceKm: 3),
      );
      final candidate = model.snapshot!.candidates.first;
      await Future.wait([
        model.swipe(candidate, like: true),
        model.swipe(candidate, like: true),
      ]);
      expect(model.snapshot!.matches, hasLength(1));
      await model.selectPet('pet-luna');
      expect(model.snapshot!.matches, isEmpty);
      expect(model.filter.species, isNull);
      await model.selectPet('pet-milo');
      expect(model.filter.species, Species.dog);
      expect(model.snapshot!.matches, hasLength(1));
      model.dispose();
    },
  );
}
