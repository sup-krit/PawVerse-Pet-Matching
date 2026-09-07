import 'domain.dart';

class DemoMatchingRepository implements MatchingRepository {
  DemoMatchingRepository({this.delay = const Duration(milliseconds: 200)});
  final Duration delay;
  static const ownPets = [
    Pet(
      id: 'pet-milo',
      ownerId: 'demo-owner',
      name: 'Milo',
      species: Species.dog,
      breed: 'Golden retriever',
      age: 3,
      description: 'Gentle walks and new friends.',
    ),
    Pet(
      id: 'pet-luna',
      ownerId: 'demo-owner',
      name: 'Luna',
      species: Species.cat,
      breed: 'British shorthair',
      age: 2,
      description: 'Quiet company, curious afternoons.',
    ),
  ];
  static const publicPets = [
    Pet(
      id: 'poppy',
      ownerId: 'owner-june',
      ownerName: 'June',
      name: 'Poppy',
      species: Species.dog,
      breed: 'Cocker spaniel',
      age: 2,
      distanceKm: 2,
      score: 94,
      reasons: ['Both enjoy gentle play', 'Similar energy levels'],
      description: 'A little sunshine with floppy ears. Loves slow park walks and a good game of fetch.',
    ),
    Pet(
      id: 'mochi',
      ownerId: 'owner-fern',
      ownerName: 'Fern',
      name: 'Mochi',
      species: Species.cat,
      breed: 'Ragdoll',
      age: 2,
      distanceKm: 4,
      score: 88,
      reasons: ['Calm, patient play style', 'Both looking for a friend'],
      description: 'A quiet companion who prefers sunny windows and a gentle introduction.',
    ),
    Pet(
      id: 'teddy',
      ownerId: 'owner-june',
      ownerName: 'June',
      name: 'Teddy',
      species: Species.dog,
      breed: 'Poodle',
      age: 4,
      distanceKm: 7,
      score: 82,
      reasons: ['Enjoys outdoor time', 'Nearby for a short walk'],
      description: 'Always ready for the next little adventure. A friendly walking buddy.',
    ),
    Pet(
      id: 'olive',
      ownerId: 'owner-nan',
      ownerName: 'Nan',
      name: 'Olive',
      species: Species.cat,
      breed: 'Domestic shorthair',
      age: 3,
      distanceKm: 12,
      score: 79,
      reasons: ['A relaxed temperament', 'Shared interest in companionship'],
      description: 'Independent, curious, and happiest with a little space to settle in.',
    ),
  ];
  final Set<String> _acted = {}, _blockedOwners = {};
  final Map<String, PetMatch> _matches = {};
  String _pair(String own, String other) => '$own:$other';
  void _requireOwn(String id) {
    if (!ownPets.any((p) => p.id == id)) {
      throw const DemoFailure('Choose one of your pets first.');
    }
  }

  PetMatch _requireMatch(String own, String id) {
    _requireOwn(own);
    final match = _matches[id];
    if (match == null || match.ownPetId != own) {
      throw const DemoFailure('This conversation belongs to another pet.');
    }
    return match;
  }

  @override
  Future<MatchingSnapshot> load(String ownPetId, DiscoveryFilter filter) async {
    _requireOwn(ownPetId);
    await Future<void>.delayed(delay);
    return MatchingSnapshot(
      ownPets: ownPets,
      candidates: publicPets
          .where(
            (p) =>
                !_blockedOwners.contains(p.ownerId) &&
                !_acted.contains(_pair(ownPetId, p.id)) &&
                (filter.species == null || filter.species == p.species) &&
                p.distanceKm <= filter.distanceKm,
          )
          .toList(),
      matches: _matches.values.where((m) => m.ownPetId == ownPetId).toList(),
    );
  }

  @override
  Future<bool> swipe(
    String ownPetId,
    String candidateId, {
    required bool like,
  }) async {
    _requireOwn(ownPetId);
    final candidates = publicPets.where((p) => p.id == candidateId);
    if (candidates.isEmpty ||
        _blockedOwners.contains(candidates.first.ownerId)) {
      throw const DemoFailure('This profile is no longer available.');
    }
    final key = _pair(ownPetId, candidateId);
    if (_acted.contains(key))
      return _matches[key]?.status == MatchStatus.active;
    _acted.add(key);
    final reciprocal =
        (ownPetId == 'pet-milo' && candidateId == 'poppy') ||
        (ownPetId == 'pet-luna' && candidateId == 'mochi');
    if (like && reciprocal) {
      _matches[key] = PetMatch(
        id: key,
        ownPetId: ownPetId,
        pet: candidates.first,
      );
      return true;
    }
    return false;
  }

  @override
  Future<void> send(
    String ownPetId,
    String matchId,
    String text,
    String messageId,
  ) async {
    final match = _requireMatch(ownPetId, matchId);
    if (match.status != MatchStatus.active ||
        _blockedOwners.contains(match.pet.ownerId)) {
      throw const DemoFailure('This conversation is closed.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) {
      throw const DemoFailure('Write a message of 1–1,000 characters.');
    }
    final existing = match.messages.where((m) => m.id == messageId);
    if (existing.isNotEmpty) {
      if (existing.first.text != trimmed)
        throw const DemoFailure('Message retry changed.');
      return;
    }
    _matches[matchId] = match.copy(
      messages: [...match.messages, ChatMessage(messageId, trimmed)],
    );
  }

  @override
  Future<void> close(
    String ownPetId,
    String matchId, {
    required bool block,
  }) async {
    final match = _requireMatch(ownPetId, matchId);
    if (block) {
      _blockedOwners.add(match.pet.ownerId);
      for (final entry in _matches.entries.toList()) {
        if (entry.value.pet.ownerId == match.pet.ownerId) {
          _matches[entry.key] = entry.value.copy(status: MatchStatus.blocked);
        }
      }
    } else if (match.status == MatchStatus.active) {
      _matches[matchId] = match.copy(status: MatchStatus.unmatched);
    }
  }

  @override
  Future<void> reset() async {
    _acted.clear();
    _blockedOwners.clear();
    _matches.clear();
  }
}
