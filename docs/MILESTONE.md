# Flutter mobile milestone

The existing `pawverse-uiux.html` remains the prototype. Its pine #214f43,
paper #fcfbf6, lime #dceda0, rounded pet cards, visible active-pet selector,
explainable compatibility and safety actions inform this native Flutter app.
The desktop atlas, simulated phone frame and web navigation are not copied.

Screens: Discover (pet switch, species/distance filters, candidate detail,
pass/like), Matches (pet-scoped conversations, text send, unmatch/block), My pets
(two demo profiles and reset). Navigation uses a native NavigationBar, routes
and modal sheets. Layout scrolls and respects safe areas and text scaling.

PRD evidence: sections 3.1/4 require active-pet context and mutual consent;
5 describes filtering and explainable scoring; 7 requires chat safety;
11 requires one conversation per match; 19/20 require membership and closed
conversation checks. Deterministic compatibility values are demo fixtures,
not a medical assessment or a production ranking engine.

Local fixture behavior: Milo and Luna are the owner's pets. Poppy has a seeded
reciprocal like for Milo; Mochi has one for Luna. Other likes remain pending.
Block acts across both own pets for the candidate owner. Unmatch closes only
that pair and prevents rematching in this demo. No precise coordinates or
private health documents exist in demo models. Data resets on app restart or
explicit reset. There is no backend, authentication, persistence, cross-app
sync, breeding policy, payment, upload or notification service.

Architecture: immutable models, typed repository interface, in-memory repository,
constructor-injected ChangeNotifier view model and ListenableBuilder views.
Future remote integration still requires authorization and API contracts.

Validation: repository tests for context/consent/safety/idempotency, view-model
loading/error/retry tests, widget flow and narrow-screen checks, analyze and web
build. Android/iOS scaffolds are targets; Windows cannot validate an iOS build
and no Android SDK/device is available in this environment.

## Validation evidence (2026-09-07)

Flutter 3.47.2 / Dart 3.13.2: analyze passed and 11 tests passed. Tests exercise
pending vs mutual likes, duplicate match/message attempts, pass, cross-pet
membership, owner-level block, unmatch/rematch denial, reset, filters and fake
load failure/retry. Mobile widget flow covers like -> match -> chat -> block;
320px / 1.5x text checks filters without overflow.

Screenshot review caught CustomPainter artwork extending into card metadata.
Clipping the canvas to its bounds fixed the artifact; refreshed captures and
widget tests passed. Reduced discovery art height keeps Like/Pass visible at
390x844. PNGs are generated in ignored `test-artifacts/`, not committed.

A web build reported missing Cupertino font after removing unused generated
dependencies. Added `cupertino_icons` because Flutter adaptive Material controls
can use it on iOS. State management remains provider-free SDK ChangeNotifier.

Future remote message writes must retain a stable client message ID across
uncertain transport retries; the local demo currently generates an ID per send
attempt. Repository deduplication is tested but is not proof of remote delivery.
