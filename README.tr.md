# social_story_view

**🌍 Dil / Language:** **Türkçe** · [English](README.md)

Flutter için özelleştirilebilir, üretime hazır **Instagram / WhatsApp tarzı hikâye (story / durum) görüntüleyici** ve avatar çubuğu.

Görsel, video ve metin hikâyelerini; otomatik ilerleyen bölümlü ilerleme çubuklarını; dokunma ve kaydırma hareketlerini; kullanıcı bazlı gruplamayı; açık/koyu temayı; bağlantı (CTA) butonlarını ve zengin bir özelleştirme API'sini destekler. Herhangi bir state-management bağımlılığı dayatmaz.

[![pub package](https://img.shields.io/badge/pub-0.1.0-blue.svg)](https://pub.dev/packages/social_story_view)

---

## İçindekiler

1. [Özellikler](#özellikler)
2. [Kurulum](#kurulum)
3. [Platform ayarları](#platform-ayarları)
4. [Hızlı başlangıç](#hızlı-başlangıç)
5. [Temel kavramlar](#temel-kavramlar)
6. [Veri modelleri](#veri-modelleri)
7. [Avatar çubuğu](#avatar-çubuğu)
8. [Hikâye görüntüleyici](#hikâye-görüntüleyici)
9. [Programatik kontrol](#programatik-kontrol)
10. [Geri çağırmalar (callbacks)](#geri-çağırmalar-callbacks)
11. [Tema (açık & koyu)](#tema-açık--koyu)
12. [Özel katmanlar (overlay)](#özel-katmanlar-overlay)
13. [Yanıt çubuğu](#yanıt-çubuğu)
14. [Bağlantı / CTA butonu](#bağlantı--cta-butonu)
15. [İlerleme çubuğu stili](#ilerleme-çubuğu-stili)
16. [Geçiş animasyonları](#geçiş-animasyonları)
17. [Hareketler (gestures)](#hareketler-gestures)
18. [Performans & bellek](#performans--bellek)
19. [Tam API referansı](#tam-api-referansı)
20. [Örnek uygulama](#örnek-uygulama)
21. [Lisans](#lisans)

---

## Özellikler

- 📱 Görsel, video ve metin/gradyan hikâyeler için **tam ekran görüntüleyici**.
- 📊 **Bölümlü ilerleme çubuğu** — her hikâye için kendi kendine dolan bir çubuk.
- 👆 **Dokunma hareketleri** — sağ üçte bir → ileri, sol üçte bir → geri, basılı tut → duraklat.
- 👋 **Kaydırma hareketleri** — aşağı: kapat, yukarı: özel aksiyon, sağa/sola: kullanıcı değiştir.
- 🧊 **Küp ve diğer geçişler** (`none`, `slide`, `cube`, `fade`, `scale`, `zoom`).
- 👥 **Otomatik kullanıcı geçişi** — biten kullanıcıdan sonra sonrakine geçer; sonraki hikâye kaydırma tamamlanmadan başlamaz.
- ⏯️ **`StoryViewController`** ile programatik `pause` / `resume` / `next` / `previous` / `jumpTo` / `close`.
- 🎞️ **Video hikâyeler**: arabelleğe alma göstergesi, otomatik süre tespiti ve anında yeniden açılış için controller havuzu.
- ⚡ **Tembel ön yükleme** (precache) ve video controller'larının güvenli imhası.
- 🟣 **Avatar çubuğu**: görülen/görülmeyen gradyan halkaları ve "hikâyene ekle" butonu.
- 🌗 **Açık & koyu tema** — `StoryViewTheme` ile tüm arayüzü tek parametreyle değiştir.
- 🔗 **Bağlantı / CTA** butonları herhangi bir hikâyeye eklenebilir (`StoryLink`); tarayıcıda açılır veya sen yönetirsin.
- 💬 **Minimalist yanıt çubuğu**: hızlı emoji tepkileri, tam stillenebilir ve builder kancalarıyla değiştirilebilir.
- 🎨 **Yüksek özelleştirme** — header / footer / overlay / loading / error builder'ları, gölge (scrim) renkleri, ilerleme stili.
- 🌍 **RTL uyumlu**, duyarlı, null-safe ve Dart 3 hazır.

---

## Kurulum

`pubspec.yaml` dosyana ekle:

```yaml
dependencies:
  social_story_view: ^0.1.0
```

Ardından çalıştır:

```bash
flutter pub get
```

**Asgari gereksinimler:** Flutter 3.19+, Dart 3.4+.

---

## Platform ayarları

Bu paket [`video_player`](https://pub.dev/packages/video_player),
[`cached_network_image`](https://pub.dev/packages/cached_network_image) ve
[`url_launcher`](https://pub.dev/packages/url_launcher) paketlerine bağımlıdır.

- **iOS** — HTTP üzerinden video/görsele izin vermek için `ios/Runner/Info.plist`
  dosyasına uygun `NSAppTransportSecurity` anahtarlarını ekle (HTTPS doğrudan çalışır).
- **Android** — internet izni varsayılan olarak dahildir; HTTP medya için
  `AndroidManifest.xml` içinde `android:usesCleartextTraffic="true"` ayarla.

---

## Hızlı başlangıç

```dart
import 'package:flutter/material.dart';
import 'package:social_story_view/social_story_view.dart';

final users = <StoryUser>[
  StoryUser(
    id: 'u1',
    username: 'alice',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    stories: [
      StoryItem.image(id: '1', url: 'https://picsum.photos/seed/1/1080/1920'),
      StoryItem.text(id: '2', text: 'Merhaba hikâyeler! ✨'),
      StoryItem.video(id: '3', url: 'https://.../clip.mp4'),
    ],
  ),
  // ...diğer kullanıcılar
];

// Görüntüleyiciyi belirli bir kullanıcıda aç:
showStoryView(context, users: users, initialUserIndex: 0);
```

---

## Temel kavramlar

Paket birkaç yapı taşından oluşur:

| Parça | Nedir |
| --- | --- |
| **`StoryUser`** | Bir kişi ve onun sıralı `StoryItem` listesi. |
| **`StoryItem`** | Tek bir hikâye: görsel, video veya metin/gradyan. |
| **`StoryView`** / **`showStoryView`** | Kullanıcı listesini oynatan tam ekran görüntüleyici. |
| **`StoryAvatarBar`** | Durum halkalı yatay avatar satırı. |
| **`StoryViewController`** | Oynatmayı programatik yönetmek için opsiyonel tutamaç. |
| **`StoryViewTheme`** | Tüm görüntüleyiciyi temalandıran stil paketi (açık/koyu). |

Yaygın durum için `showStoryView(...)` kullan (modal route açar); tam kontrol
gerektiğinde `StoryView(...)`'i kendi route'unun içine doğrudan göm.

---

## Veri modelleri

### StoryItem

Üç fabrika kurucu her hikâye türünü kapsar:

```dart
// Görsel hikâye (süre, görüntüleyicideki imageDuration'a göre varsayılır)
StoryItem.image(id: 'a', url: '...', duration: Duration(seconds: 8));

// Video hikâye (süre dosyadan otomatik algılanır)
StoryItem.video(id: 'b', url: '...');

// Metin / gradyan hikâye
StoryItem.text(
  id: 'c',
  text: 'Selam 👋',
  gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
);
```

Her `StoryItem` ayrıca şunları kabul eder:

- `isViewed` — hikâyenin görülüp görülmediği (halka rengini belirler).
- `metadata` — overlay builder'ında okuyabileceğin serbest biçimli bir
  `Map<String, dynamic>` (örn. kampanya başlığı, tarih aralığı, metin).
- `detailPhotoUrl` — bağlantılı ayrı bir detay sayfası için kullanılabilecek
  opsiyonel görsel URL'si.
- `link` — opsiyonel bir [`StoryLink`](#bağlantı--cta-butonu) CTA'sı.

`StoryItem`; `copyWith`, `toJson` / `fromJson` destekler.

### StoryUser

```dart
StoryUser(
  id: 'u1',
  username: 'alice',
  avatarUrl: '...',
  stories: [...],
  isCurrentUser: false, // avatar çubuğunda "+" ekle rozetini gösterir
);
```

Yardımcılar: `firstUnseenIndex`, `markStoryViewed`, `hasUnseen`,
`isFullyViewed`, ayrıca `copyWith`, `toJson` / `fromJson`.

---

## Avatar çubuğu

```dart
StoryAvatarBar(
  users: users,
  onAvatarTap: (user, index) => showStoryView(
    context,
    users: users,
    initialUserIndex: index,
  ),
  onAddTap: () => print('Hikâyene ekle'),
  style: const StoryAvatarStyle(
    radius: 32,
    ringThickness: 2.5,
    ringGap: 3,
    seenColor: Color(0xFFBDBDBD),
    unseenGradient: LinearGradient(
      colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976)],
    ),
    showLabel: true,
    currentUserLabel: 'Hikâyen',
  ),
);
```

- Görülmemiş hikâyesi olan kullanıcılar **gradyan halka** alır; tamamı görülenler
  düz `seenColor` halkası alır.
- `isCurrentUser: true` olan kullanıcıda **"+" ekle rozeti** görünür; dokunmak
  `onAddTap`'i tetikler.

---

## Hikâye görüntüleyici

`StoryView` tam ekran oynatıcıdır. `users` dışındaki her parametre opsiyoneldir:

```dart
StoryView(
  users: users,
  controller: controller,            // opsiyonel programatik kontrol
  initialUserIndex: 0,
  initialStoryIndex: null,           // null → ilk görülmemiş hikâye
  transition: StoryTransition.cube,
  imageDuration: const Duration(seconds: 10),
  contentFit: BoxFit.contain,
  muted: false,
  theme: StoryViewTheme.dark(),      // açık/koyu tema
  swipeDownToDismiss: true,
  headerConfig: const StoryHeaderConfig(),
  // ...builder'lar & callback'ler (aşağıda)
);
```

Yaygın "modal olarak aç" durumu için, saydam bir route iten ve kapanışta pop
eden yardımcı fonksiyonu kullan:

```dart
showStoryView(context, users: users, initialUserIndex: index);
```

`showStoryView`, `StoryView` ile **aynı parametreleri** kabul eder.

---

## Programatik kontrol

```dart
final controller = StoryViewController();

StoryView(users: users, controller: controller);

controller.pause();
controller.resume();
controller.next();
controller.previous();
controller.jumpTo(userIndex: 2, storyIndex: 1);
controller.close();

// Sahibi sensen unutma:
controller.dispose();
```

Duraklatma **bağımsız nedenleri** destekler (`StoryPauseReason.hold`,
`buffering`, `lifecycle`, `manual`); oynatma yalnızca **tüm** nedenler
temizlendiğinde devam eder. Bu sayede klavye için duraklatma ile arabelleğe
alma için duraklatma birbiriyle çakışmaz.

---

## Geri çağırmalar (callbacks)

```dart
StoryView(
  users: users,
  onStoryShow: (user, item, index) {},     // hikâye görünür oldu
  onStoryComplete: (user, item, index) {},  // hikâye tamamen oynandı
  onAllStoriesComplete: (user) {},          // kullanıcı tüm hikâyeleri bitirdi
  onSwipeUp: (user, item) {},               // yukarı kaydırma aksiyonu
  onLinkTap: (user, item, link) {},         // bir StoryLink'e dokunuldu
  onClose: () {},                           // görüntüleyici kapatıldı
);
```

`onLinkTap` verilmezse, bir `StoryLink`'e dokunmak `url`'ini tarayıcıda otomatik
açar (ve açılış sırasında duraklatıp devam ettirir).

---

## Tema (açık & koyu)

`StoryViewTheme`; tüm alt stilleri (ilerleme çubuğu, header, yanıt çubuğu,
avatarlar) ve arka plan ile üst/alt okunabilirlik gölgelerini (scrim) tek bir
nesnede toplar; böylece **tüm** görüntüleyiciyi tek değerle değiştirebilirsin.

```dart
// Hazır ön ayarlar:
StoryView(users: users, theme: StoryViewTheme.dark());   // varsayılan
StoryView(users: users, theme: StoryViewTheme.light());
```

`copyWith` ile dışarıdan herhangi bir alanı değiştir:

```dart
StoryView(
  users: users,
  theme: StoryViewTheme.light().copyWith(
    backgroundColor: Colors.grey.shade100,
    topScrimColor: const Color(0x33FFFFFF),
  ),
);
```

`StoryViewTheme` alanları:

| Alan | Amaç |
| --- | --- |
| `brightness` | `Brightness.light` / `dark` — kendi katmanlarında buna göre dallan. |
| `backgroundColor` | Medyanın arkasındaki renk (letterbox alanı). |
| `progressStyle` | Bölümlü ilerleme çubuğu stili. |
| `headerStyle` | Varsayılan header'ın renk/tipografisi. |
| `replyBarStyle` | Varsayılan yanıt çubuğu stili. |
| `avatarStyle` | Avatar çubuğu / avatar stili. |
| `topScrimColor` | Üst gradyan gölge (ilerleme çubuğu + header arkası). |
| `bottomScrimColor` | Alt gradyan gölge (footer + bağlantı arkası). |

> **Öncelik:** `StoryView` üzerindeki açıkça verilen `progressStyle`,
> `backgroundColor` ve `headerStyle` parametreleri, sağlandığında temayı ezer.
> Temadan miras almak için bunları `null` bırak.

Her alt stilin kendi `.light()` ön ayarı da vardır:
`StoryProgressStyle.light()`, `StoryHeaderStyle.light()`,
`StoryReplyBarStyle.light()`.

---

## Özel katmanlar (overlay)

Arayüzün herhangi bir parçasını bir builder ile değiştir. Üç yerleşim yuvası var:

```dart
StoryView(
  users: users,

  // Üst çubuk (avatar, ad, zaman, kapat). DefaultStoryHeader'ı değiştirir.
  headerBuilder: (context, user, item, index) => MyHeader(user: user),

  // Alt çubuk (yanıt girişi, tepkiler; bağlantı butonu bunun üstünde durur).
  footerBuilder: (context, user, item, index) => StoryReplyBar(
    onSubmitted: (text) => print('Yanıt: $text'),
  ),

  // Tüm medya alanının üzerine çizilir — başlık / kampanya metni için ideal.
  overlayBuilder: (context, user, item, index) {
    final meta = item.metadata;
    if (meta?['title'] == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(meta!['title'] as String),
    );
  },

  // Medya yüklenirken / hata durumunda gösterilir.
  loadingBuilder: (context, user, item) => const CircularProgressIndicator(),
  errorBuilder: (context, user, item, error) => const Icon(Icons.error),
);
```

Varsayılan header'ı tutarsan, hangi öğeleri göstereceğini `StoryHeaderConfig`,
renk/tipografisini `StoryHeaderStyle` ile yönet:

```dart
StoryView(
  users: users,
  headerConfig: const StoryHeaderConfig(
    showAvatar: true,
    showUsername: true,
    showTimestamp: true,
    showCloseButton: true,
  ),
  headerStyle: const StoryHeaderStyle(/* renkler, fontlar, gölge */),
);
```

> **İpucu:** `overlayBuilder` içindeki etkileşimli çocuklar kendi gesture
> detector'larıyla sarılmalıdır; aksi halde dokunuşlar navigasyon katmanına geçer.

---

## Yanıt çubuğu

`StoryReplyBar`; yuvarlatılmış bir giriş ve hızlı emoji tepkileri olan
minimalist, hazır bir footer'dır. Yazarken hikâyeyi duraklatmak için
`onFocusChanged` kullan:

```dart
footerBuilder: (context, user, item, index) {
  // Kendi hikâyene yanıt vermeyi engelle:
  if (user.isCurrentUser) return const SizedBox.shrink();

  return StoryReplyBar(
    hintText: '${user.username} kullanıcısına yanıt ver...',
    reactions: const ['❤️', '😮', '😂', '👏', '🔥'],
    onFocusChanged: (focused) =>
        focused ? controller.pause() : controller.resume(),
    onReaction: (emoji) => print('$emoji tepki verildi'),
    onSubmitted: (text) => print('Yanıt: $text'),
    style: const StoryReplyBarStyle(/* dolgu, kenarlık, metin renkleri... */),
  );
}
```

Parçaları `enableReply` / `enableReactions` ile aç/kapat; bölümleri builder
kancalarıyla tamamen değiştir:

- `inputBuilder` — tüm giriş hapı + gönder butonunu değiştirir.
- `sendButtonBuilder` — yalnızca sondaki gönder öğesini değiştirir.
- `reactionBuilder` — tek bir tepki emoji widget'ını değiştirir.

`StoryReplyBarStyle` (veya `StoryReplyBarStyle.light()`) ile doğrudan stillendir.

---

## Bağlantı / CTA butonu

`StoryItem.link` ile herhangi bir hikâyeye dokunulabilir bir buton ekle:

```dart
StoryItem.image(
  id: 'promo',
  url: '...',
  link: const StoryLink(
    url: 'https://flutter.dev',
    label: 'Detayları incele',
    icon: Icons.link,
    alignment: Alignment.bottomCenter,
  ),
);
```

Buton, `link.alignment` konumunda bir hap olarak çizilir. Alta hizalı bağlantılar
yanıt çubuğunun **üstünde** durur; böylece asla girişin arkasında kalmaz.
Dokunuşları `onLinkTap` ile kendin yönet veya paketin URL'yi tarayıcıda otomatik
açmasına izin ver.

---

## İlerleme çubuğu stili

```dart
StoryView(
  users: users,
  progressStyle: const StoryProgressStyle(
    color: Colors.white,                       // dolmuş kısım
    backgroundColor: Color(0x55FFFFFF),         // kalan iz
    height: 2.5,
    spacing: 4,
    borderRadius: BorderRadius.all(Radius.circular(8)),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  ),
);
```

Açık zemin üstünde koyu varyant için `StoryProgressStyle.light()` kullan.

---

## Geçiş animasyonları

Kullanıcılar arası geçişi `StoryTransition` ile seç:

| Değer | Etki |
| --- | --- |
| `none` | Anında sayfa değişimi. |
| `slide` | Standart yatay kaydırma. |
| `cube` | 3B küp dönüşü (Instagram gibi). |
| `fade` | Çapraz solma. |
| `scale` | Ölçekleyerek giriş/çıkış. |
| `zoom` | İçinden yakınlaşma. |

```dart
StoryView(users: users, transition: StoryTransition.cube);
```

---

## Hareketler (gestures)

| Hareket | Aksiyon |
| --- | --- |
| Sağ üçte bire dokun | Sonraki hikâye |
| Sol üçte bire dokun | Önceki hikâye |
| Basılı tut | Duraklat (bırakınca devam) |
| Yatay kaydır | Sonraki / önceki **kullanıcı** |
| Aşağı kaydır | Görüntüleyiciyi kapat |
| Yukarı kaydır | `onSwipeUp` callback'i |

Dokunma bölgeleri RTL düzenlerde otomatik aynalanır. Sonraki kullanıcının
hikâyesi yalnızca kaydırma **yerleştikten sonra** başlar, asla hareket
ortasında değil.

---

## Performans & bellek

- Her video, anında yeniden açılış için yeniden kullanılan ve gerekmediğinde imha
  edilen bir **havuzdan** `VideoPlayerController` alır.
- Yalnızca **yerleşmiş** kullanıcının sayfası oynar; ekran dışı sayfalar duraklar.
- Mevcut ve sonraki kullanıcının ilk görseli, takılmayı önlemek için **ön yüklenir**.
- İlerleme, tam yeniden oluşturmayı önleyen hafif bir `ValueNotifier` ile sürülür.
- Arabelleğe alma duraklatmaları ayrı izlenir; böylece arabelleğe alan bir video
  asla kilitlenmez (deadlock olmaz).

---

## Tam API referansı

### Dışa aktarılan tipler

- **Widget'lar:** `StoryView`, `showStoryView`, `StoryAvatarBar`, `StoryAvatar`,
  `StoryProgressBar`, `StoryReplyBar`, `StoryLinkButton`, `DefaultStoryHeader`.
- **Modeller:** `StoryUser`, `StoryItem`, `StoryLink`, `StoryMediaType`,
  `StoryTransition`, `StoryProgressStyle`, `StoryViewTheme`, `StoryHeaderStyle`,
  `StoryHeaderConfig`, `StoryReplyBarStyle`, `StoryAvatarStyle`.
- **Controller:** `StoryViewController`, `StoryPauseReason`.
- **Callback'ler:** `StoryHeaderBuilder`, `StoryFooterBuilder`,
  `StoryOverlayBuilder`, `StoryLoadingBuilder`, `StoryErrorBuilder`,
  `OnStoryShow`, `OnStoryComplete`, `OnAllStoriesComplete`, `OnStorySwipeUp`,
  `OnStoryLinkTap`, `OnViewerClose`.
- **Yardımcılar:** `StoryMediaCache`, `StoryVideoControllerPool`.

---

## Örnek uygulama

Tam çalışan bir demo (avatar çubuğu + görsel, video ve metin hikâyeleri içeren
görüntüleyici, açık/koyu geçiş düğmesi, özel yanıt footer'ı, bağlantı CTA'sı,
kampanya overlay'i ve görülme durumu takibi) [`example/`](example/lib/main.dart)
içinde:

```bash
cd example
flutter run
```

---

## Lisans

MIT — bkz. [LICENSE](LICENSE).
