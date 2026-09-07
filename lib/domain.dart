enum Species { dog, cat }

enum MatchStatus { active, unmatched, blocked }

class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.description,
    this.distanceKm = 0,
    this.score = 0,
    this.reasons = const [],
    this.ownerName = 'You',
  });
  final String id, ownerId, name, breed, description, ownerName;
  final Species species;
  final int age, score;
  final double distanceKm;
  final List<String> reasons;
}

class DiscoveryFilter {
  const DiscoveryFilter({this.species, this.distanceKm = 10});
  final Species? species;
  final double distanceKm;
}

class ChatMessage {
  const ChatMessage(this.id, this.text);
  final String id, text;
}

class PetMatch {
  PetMatch({
    required this.id,
    required this.ownPetId,
    required this.pet,
    this.status = MatchStatus.active,
    List<ChatMessage> messages = const [],
  }) : messages = List.unmodifiable(messages);
  final String id, ownPetId;
  final Pet pet;
  final MatchStatus status;
  final List<ChatMessage> messages;
  PetMatch copy({MatchStatus? status, List<ChatMessage>? messages}) => PetMatch(
    id: id,
    ownPetId: ownPetId,
    pet: pet,
    status: status ?? this.status,
    messages: messages ?? this.messages,
  );
}

class MatchingSnapshot {
  MatchingSnapshot({
    required List<Pet> ownPets,
    required List<Pet> candidates,
    required List<PetMatch> matches,
  }) : ownPets = List.unmodifiable(ownPets),
       candidates = List.unmodifiable(candidates),
       matches = List.unmodifiable(matches);
  final List<Pet> ownPets, candidates;
  final List<PetMatch> matches;
}

class DemoFailure implements Exception {
  const DemoFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A domain boundary, not a production authorization contract.
abstract interface class MatchingRepository {
  Future<MatchingSnapshot> load(String ownPetId, DiscoveryFilter filter);
  Future<bool> swipe(String ownPetId, String candidateId, {required bool like});
  Future<void> send(
    String ownPetId,
    String matchId,
    String text,
    String messageId,
  );
  Future<void> close(String ownPetId, String matchId, {required bool block});
  Future<void> reset();
}
