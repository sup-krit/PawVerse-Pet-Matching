import 'package:flutter/material.dart';

import 'domain.dart';
import 'matching_view_model.dart';

const pine = Color(0xff214f43);
const soft = Color(0xffeef2e8);

class MatchingHome extends StatefulWidget {
  const MatchingHome({super.key, required this.model});
  final MatchingViewModel model;
  @override
  State<MatchingHome> createState() => _MatchingHomeState();
}

class _MatchingHomeState extends State<MatchingHome> {
  int tab = 0;
  MatchingViewModel get model => widget.model;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: pine),
            SizedBox(width: 10),
            Text('PawVerse', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            label: 'My pets',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Local demo · fictional profiles · resets on restart',
                    style: TextStyle(fontSize: 12, color: Color(0xff617169)),
                  ),
                ),
                if (model.snapshot != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Material(
                      color: soft,
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        key: const Key('pet-switch'),
                        leading: PetAvatar(pet: model.activePet!),
                        title: Text('Discovering as ${model.activePet!.name}'),
                        subtitle: const Text('Friend & playdate'),
                        trailing: const Icon(Icons.expand_more),
                        onTap: model.busy ? null : () => _switchPet(context),
                      ),
                    ),
                  ),
                if (model.busy) const LinearProgressIndicator(),
                Expanded(
                  child: model.loading && model.snapshot == null
                      ? const Center(child: CircularProgressIndicator())
                      : model.error != null
                      ? EmptyPanel(
                          icon: Icons.cloud_off_outlined,
                          title: 'Something went wrong',
                          detail: model.error!,
                          action: 'Retry',
                          onAction: model.load,
                        )
                      : model.snapshot == null
                      ? const SizedBox.shrink()
                      : switch (tab) {
                          0 => _discover(context),
                          1 => _matches(context),
                          _ => _pets(context),
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> _switchPet(BuildContext context) async {
    final pets = model.snapshot!.ownPets;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const ListTile(
              title: Text(
                'Who is meeting new friends?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final pet in pets)
              ListTile(
                leading: PetAvatar(pet: pet),
                title: Text(pet.name),
                subtitle: Text(pet.breed),
                trailing: pet.id == model.activePetId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, pet.id),
              ),
          ],
        ),
      ),
    );
    if (selected != null) await model.selectPet(selected);
  }

  Widget _discover(BuildContext context) {
    final candidates = model.snapshot!.candidates;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A friend for every paw.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Small introductions. Happy connections.',
                    style: TextStyle(color: Color(0xff617169)),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Discovery filters',
              onPressed: model.busy ? null : () => _filters(context),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '${model.filter.species?.name ?? 'All pets'} · within ${model.filter.distanceKm.round()} km · approximate distances',
            style: const TextStyle(fontSize: 12, color: Color(0xff617169)),
          ),
        ),
        if (model.loading) const LinearProgressIndicator(),
        if (candidates.isEmpty)
          EmptyPanel(
            icon: Icons.travel_explore,
            title: 'A little quiet here',
            detail: 'Try a wider distance or another pet. Passed and liked profiles stay out of this pet’s discovery.',
            action: 'Adjust filters',
            onAction: () => _filters(context),
          )
        else ...[
          PetCard(
            pet: candidates.first,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => PetDetail(pet: candidates.first),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: model.busy || model.loading
                      ? null
                      : () => _swipe(candidates.first, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Pass'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('like-button'),
                  onPressed: model.busy || model.loading
                      ? null
                      : () => _swipe(candidates.first, true),
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text('Like'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'A chat opens only when both pets like each other.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xff617169)),
          ),
        ],
      ],
    );
  }

  Future<void> _swipe(Pet pet, bool like) async {
    final matched = await model.swipe(pet, like: like);
    if (!mounted || matched == null) return;
    if (matched) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.favorite, color: pine, size: 40),
          title: const Text('A new connection!'),
          content: Text(
            '${model.activePet!.name} and ${pet.name} both liked each other. Say hello in Matches.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep exploring'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => tab = 1);
              },
              child: const Text('Go to matches'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            like
                ? 'Like saved. Chat stays closed until they like you back.'
                : '${pet.name} passed for this pet.',
          ),
        ),
      );
    }
  }

  Future<void> _filters(BuildContext context) async {
    var species = model.filter.species;
    var distance = model.filter.distanceKm;
    final result = await showModalBottomSheet<DiscoveryFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A little closer to your kind',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                const Text('Species'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final choice in <Species?>[
                      null,
                      Species.dog,
                      Species.cat,
                    ])
                      ChoiceChip(
                        label: Text(
                          choice == null
                              ? 'All pets'
                              : choice == Species.dog
                              ? 'Dogs'
                              : 'Cats',
                        ),
                        selected: choice == species,
                        onSelected: (_) => update(() => species = choice),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Distance: ${distance.round()} km'),
                Slider(
                  value: distance,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${distance.round()} km',
                  onChanged: (value) => update(() => distance = value),
                ),
                const Text(
                  'Demo range only. We show approximate distance, never an address.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => update(() {
                        species = null;
                        distance = 10;
                      }),
                      child: const Text('Reset filters'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        DiscoveryFilter(species: species, distanceKm: distance),
                      ),
                      child: const Text('Apply filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) await model.applyFilter(result);
  }

  Widget _matches(BuildContext context) {
    final matches = model.snapshot!.matches
        .where((m) => m.status == MatchStatus.active)
        .toList();
    if (matches.isEmpty)
      return const EmptyPanel(
        icon: Icons.favorite_border,
        title: 'Good friendships start with a hello',
        detail: 'Like a profile in Discover. Mutual likes appear here, only for your selected pet.',
      );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'New friends',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text('Connections for ${model.activePet!.name}'),
        const SizedBox(height: 16),
        for (final match in matches)
          Card(
            elevation: 0,
            color: soft,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: PetAvatar(pet: match.pet),
              title: Text(match.pet.name),
              subtitle: Text(
                match.messages.isEmpty
                    ? 'You both liked each other. Say hello.'
                    : match.messages.last.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ConversationScreen(model: model, original: match),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pets(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Your little universe',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text('Each pet has their own likes, filters and conversations.'),
      const SizedBox(height: 20),
      for (final pet in model.snapshot!.ownPets)
        Card(
          elevation: 0,
          color: soft,
          child: ListTile(
            leading: PetAvatar(pet: pet),
            title: Text(pet.name),
            subtitle: Text('${pet.breed} · ${pet.age} years'),
            trailing: pet.id == model.activePetId
                ? const Icon(Icons.check_circle, color: pine)
                : null,
            onTap: () async {
              await model.selectPet(pet.id);
              if (mounted) setState(() => tab = 0);
            },
          ),
        ),
      const SizedBox(height: 24),
      const Text(
        'About this demo',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'All profiles and compatibility scores are fictional. Messages stay in memory until the app restarts. Nothing is sent to another owner or to PawVerse Health Care.',
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: model.busy
            ? null
            : () async {
                final reset = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Start fresh?'),
                    content: const Text(
                      'Clear all demo likes, matches, messages, blocks and filters.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep exploring'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset demo'),
                      ),
                    ],
                  ),
                );
                if (reset == true) await model.reset();
              },
        icon: const Icon(Icons.restart_alt),
        label: const Text('Reset demo'),
      ),
    ],
  );
}

class PetAvatar extends StatelessWidget {
  const PetAvatar({super.key, required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: const Color(0xffdceda0),
    child: Icon(
      pet.species == Species.dog ? Icons.pets : Icons.cruelty_free,
      color: pine,
    ),
  );
}

class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.pet, required this.onTap});
  final Pet pet;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xffe0e5db)),
    ),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 155,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: PetIllustration(isCat: pet.species == Species.cat),
                ),
                const Positioned(
                  top: 14,
                  left: 14,
                  child: Chip(label: Text('Open to friendship')),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet.name}, ${pet.age}',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${pet.breed} · about ${pet.distanceKm.round()} km away'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${pet.score}%',
                      style: const TextStyle(
                        fontSize: 25,
                        color: pine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('demo compatibility'),
                  ],
                ),
                for (final reason in pet.reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $reason'),
                  ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text('With ${pet.ownerName} · View profile'),
                    ),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Original local vector illustration, no network photos or permissions.
class PetIllustration extends CustomPainter {
  PetIllustration({required this.isCat});
  final bool isCat;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(isCat ? 0xffe5e9de : 0xffefe2ca),
    );
    canvas.drawCircle(
      Offset(size.width * .78, 40),
      60,
      Paint()..color = const Color(0xfff8f2df),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height + 12),
        width: 260,
        height: 135,
      ),
      Paint()..color = const Color(0xffb7c59e),
    );
    final center = Offset(size.width / 2, size.height * .52);
    final fur = Paint()..color = Color(isCat ? 0xff9baba5 : 0xffba8152);
    if (isCat) {
      for (final side in [-1, 1]) {
        final ear = Path()
          ..moveTo(center.dx + side * 22, center.dy - 37)
          ..lineTo(center.dx + side * 57, center.dy - 72)
          ..lineTo(center.dx + side * 62, center.dy - 3)
          ..close();
        canvas.drawPath(ear, fur);
      }
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(-55, 8),
          width: 42,
          height: 105,
        ),
        fur,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(55, 8),
          width: 42,
          height: 105,
        ),
        fur,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 119, height: 116),
      Paint()..color = Color(isCat ? 0xffbac7bf : 0xffd9a773),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 23),
        width: 63,
        height: 43,
      ),
      Paint()..color = const Color(0xfff7ead4),
    );
    final ink = Paint()..color = const Color(0xff233b33);
    for (final side in [-1, 1]) {
      canvas.drawCircle(center + Offset(side * 23, -6), 5, ink);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 15),
        width: 15,
        height: 10,
      ),
      ink,
    );
    final smile = Path()
      ..moveTo(center.dx, center.dy + 20)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 37,
        center.dx + 14,
        center.dy + 29,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = pine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + const Offset(0, 61),
          width: 75,
          height: 11,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = pine,
    );
    canvas.drawCircle(
      center + const Offset(0, 71),
      7,
      Paint()..color = const Color(0xffdceda0),
    );
  }

  @override
  bool shouldRepaint(PetIllustration oldDelegate) => oldDelegate.isCat != isCat;
}

class PetDetail extends StatelessWidget {
  const PetDetail({super.key, required this.pet});
  final Pet pet;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Meet ${pet.name}')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 230,
              child: CustomPaint(
                painter: PetIllustration(isCat: pet.species == Species.cat),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            pet.name,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text(
            '${pet.breed} · ${pet.age} years · about ${pet.distanceKm.round()} km away',
          ),
          const SizedBox(height: 16),
          Text(pet.description),
          const SizedBox(height: 24),
          Text(
            'Why you might get along · ${pet.score}%',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          for (final reason in pet.reasons)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, color: pine),
              title: Text(reason),
            ),
          const Text(
            'Compatibility is a demo fixture, not a guarantee of safe interaction.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Health & trust',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unverified demo profile. No health documents are available or shared. Introduce pets carefully and discuss their needs with the owner.',
          ),
        ],
      ),
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title, detail;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: pine),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(detail, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.model,
    required this.original,
  });
  final MatchingViewModel model;
  final PetMatch original;
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final composer = TextEditingController();
  final scroll = ScrollController();
  @override
  void dispose() {
    composer.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final model = widget.model;
      final match =
          model.snapshot?.matches
              .where((m) => m.id == widget.original.id)
              .firstOrNull ??
          widget.original;
      final closed =
          match.status != MatchStatus.active ||
          model.activePetId != match.ownPetId;
      return Scaffold(
        appBar: AppBar(
          title: Text(match.pet.name),
          actions: [
            PopupMenuButton<bool>(
              tooltip: 'Conversation safety',
              enabled: !model.busy && !closed,
              onSelected: (block) => _close(match, block),
              itemBuilder: (_) => const [
                PopupMenuItem(value: false, child: Text('Unmatch')),
                PopupMenuItem(value: true, child: Text('Block owner')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Local demo conversation · messages are not delivered',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (model.error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        model.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Expanded(
                    child: match.messages.isEmpty
                        ? const EmptyPanel(
                            icon: Icons.waving_hand_outlined,
                            title: 'A simple hello goes a long way',
                            detail: 'You both liked each other. Ask about a favourite walking spot or play style.',
                          )
                        : ListView.builder(
                            controller: scroll,
                            padding: const EdgeInsets.all(20),
                            itemCount: match.messages.length,
                            itemBuilder: (context, index) => Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  bottom: 12,
                                  left: 32,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: pine,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  match.messages[index].text,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (closed)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Conversation closed. New messages are disabled.',
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('message-input'),
                              controller: composer,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 1000,
                              enabled: !model.busy,
                              decoration: const InputDecoration(
                                hintText: 'Say hello…',
                                labelText: 'Message',
                                counterText: '',
                              ),
                              onSubmitted: (_) => _send(match),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Send message',
                            onPressed: model.busy ? null : () => _send(match),
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  Future<void> _send(PetMatch match) async {
    if (await widget.model.send(match, composer.text) && mounted) {
      composer.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients)
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
      });
    }
  }

  Future<void> _close(PetMatch match, bool block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? 'Block this owner?' : 'End this connection?'),
        content: Text(
          block
              ? 'Their pets disappear from discovery for all your pets, and your conversations close.'
              : 'This pet’s conversation closes. You cannot send more messages or rematch in this demo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(block ? 'Block owner' : 'Unmatch'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.model.close(match, block: block);
  }
}
