import 'package:flutter/foundation.dart';

import 'domain.dart';

class MatchingViewModel extends ChangeNotifier {
  MatchingViewModel(this.repository);
  final MatchingRepository repository;
  String activePetId = 'pet-milo';
  final Map<String, DiscoveryFilter> _filters = {};
  MatchingSnapshot? snapshot;
  bool loading = false, busy = false;
  String? error;
  int _generation = 0, _messageSequence = 0;
  bool _disposed = false;
  DiscoveryFilter get filter =>
      _filters[activePetId] ?? const DiscoveryFilter();
  Pet? get activePet =>
      snapshot?.ownPets.where((p) => p.id == activePetId).firstOrNull;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _emit();
    try {
      final result = await repository.load(activePetId, filter);
      if (generation == _generation && !_disposed) snapshot = result;
    } catch (_) {
      if (generation == _generation)
        error = 'Could not load your pets. Please try again.';
    } finally {
      if (generation == _generation) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> selectPet(String id) async {
    if (busy || id == activePetId) return;
    activePetId = id;
    snapshot = null;
    await load();
  }

  Future<void> applyFilter(DiscoveryFilter value) async {
    if (busy) return;
    _filters[activePetId] = value;
    await load();
  }

  Future<T?> _mutate<T>(Future<T> Function() action) async {
    if (busy || loading) return null;
    busy = true;
    error = null;
    _emit();
    try {
      final result = await action();
      await load();
      return result;
    } on DemoFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'That action could not be saved. Please try again.';
    } finally {
      busy = false;
      _emit();
    }
    return null;
  }

  Future<bool?> swipe(Pet pet, {required bool like}) =>
      _mutate(() => repository.swipe(activePetId, pet.id, like: like));
  Future<bool> send(PetMatch match, String text) async =>
      await _mutate(() async {
        await repository.send(
          match.ownPetId,
          match.id,
          text,
          'local-${++_messageSequence}',
        );
        return true;
      }) ??
      false;
  Future<void> close(PetMatch match, {required bool block}) async {
    await _mutate(
      () => repository.close(match.ownPetId, match.id, block: block),
    );
  }

  Future<void> reset() async {
    await _mutate(() async {
      await repository.reset();
      _filters.clear();
      activePetId = 'pet-milo';
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
