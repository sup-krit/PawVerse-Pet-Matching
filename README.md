# PawVerse Pet Matching — Flutter mobile demo

Native Flutter app for Android and iOS, with a web harness for development. The original HTML prototype below is preserved as a design and interaction reference.

## Run and verify

Validated with Flutter 3.47.2 / Dart 3.13.2. Install Flutter and the target platform toolchain, then run:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build web
```

`flutter run` uses an available device/emulator. Android needs an Android SDK; iOS requires macOS/Xcode. Neither native target was built or run in the Windows implementation environment. Web compilation and Flutter widget tests do not replace device testing.

## Try the local flows

- Discover as Milo: Like Poppy for a seeded mutual match, then open Matches and send a local text message.
- Like Mochi as Milo: this stays pending and does not create a conversation. Switch to Luna: her seeded reciprocal like is Mochi.
- Filters are per pet. Set Cats or widen distance to see different fictional candidates.
- In a conversation, use the safety menu to unmatch or block. Block hides all pets belonging to that owner across your own pets and stops new sends.
- My pets has Reset demo. All state also clears on process restart; messages are not delivered to real people.

No sign-in, backend, persistent storage, precise location, health documents, breeding policy, payments, uploads, or Health Care synchronization is implemented. Displayed compatibility percentages are deterministic fixtures, not a production scoring engine or health claim.

Architecture and scope: [ADR](docs/ADR-001-flutter-milestone.md), [milestone](docs/MILESTONE.md). `lib/domain.dart` defines the repository boundary; `demo_repository.dart` supplies in-memory behavior, `matching_view_model.dart` controls state, and `screens.dart` contains native views. Remote integration still needs explicit API and server authorization contracts.

Tests cover mutual consent, duplicate mutations, pet context, block/unmatch, filters, loading/error/retry, mobile chat and 320px large-text layout. Widget tests also write ignored review captures to `test-artifacts/` using SDK fonts when available.

---

## Original HTML prototype documentation
# PawVerse - Pet Matching

ต้นแบบเว็บแบบโต้ตอบสำหรับแพลตฟอร์มจับคู่สัตว์เลี้ยง ช่วยให้เจ้าของค้นหาเพื่อนที่เหมาะกับสัตว์เลี้ยงของตน นัดหมายทำกิจกรรมร่วมกัน (Playdate) และสื่อสารหลังจับคู่ โดยคำนึงถึงความเข้ากันได้ สุขภาพ และความปลอดภัย

โปรเจกต์นี้นำเสนอทั้งหน้าจอแอปภาษาไทยและคำอธิบายการทำงานของระบบในรูปแบบ **UI/UX & Function Atlas** เหมาะสำหรับสาธิตแนวคิดและใช้ประกอบการออกแบบหรือพัฒนาต่อ

## ฟีเจอร์ที่สาธิต

- จัดการโปรไฟล์สัตว์เลี้ยงหลายตัว และเลือกตัวที่ต้องการใช้ค้นหาเพื่อน
- ค้นหาและกรองสัตว์เลี้ยง พร้อมคะแนนความเข้ากันได้และคำอธิบาย
- กด Like / Pass จับคู่เมื่อทั้งสองฝ่ายสนใจ และทดลองแชตหลังจับคู่
- ขออนุญาตแชร์ข้อมูลสุขภาพ และส่งคำชวนนัดหมาย Playdate
- จำลองการยืนยันบัญชีและเอกสาร การประเมินสิทธิ์จับคู่เพื่อผสมพันธุ์ และแพ็กเกจ Premium
- บล็อก รายงาน ยกเลิกการจับคู่ และดูหน้าจอสำหรับผู้ดูแลระบบ
- ดูแผนภาพการทำงาน ตัวอย่างข้อมูล และแนวทาง API ควบคู่กับหน้าจอ

## วิธีเปิดใช้งาน

1. Clone repository หรือดาวน์โหลดผ่าน **Code → Download ZIP** แล้วแตกไฟล์
2. เปิดไฟล์ [`pawverse-uiux.html`](./pawverse-uiux.html) ด้วยเว็บเบราว์เซอร์
3. เลือกหน้าจอจากเมนูและทดลองกดปุ่มต่าง ๆ เพื่อสำรวจขั้นตอนการใช้งาน

ไม่ต้องติดตั้ง dependencies หรือรัน build และสามารถเปิดใช้งานแบบออฟไลน์ได้ บนจอใหญ่จะแสดงหน้าจอแอปคู่กับคำอธิบาย ส่วนมือถือสามารถสลับมุมมองได้

## เทคโนโลยีและขอบเขต

ใช้ **HTML, CSS, JavaScript และ SVG** รวมอยู่ในไฟล์เดียว โดยใช้ข้อมูลตัวอย่างในหน่วยความจำของเบราว์เซอร์ สถานะจะเริ่มใหม่เมื่อรีโหลดหน้า

ปัจจุบันเป็น **interactive prototype** ยังไม่เชื่อมต่อ backend, ฐานข้อมูล, ระบบ OTP, แชตจริง หรือการชำระเงินจริง ส่วน API และสถาปัตยกรรมที่แสดงเป็นแนวทางสำหรับการพัฒนาต่อ
