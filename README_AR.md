<div dir="rtl">

# Turnable Page: تقليب صفحات واقعي في Flutter

[English](README.md) · [التوثيق الكامل](https://saeedahmed725.github.io/turnable_page/) · [pub.dev](https://pub.dev/packages/turnable_page)

باكدج Flutter بتعمل **تأثير تقليب صفحات ثلاثي الأبعاد** واقعي للكتب والمجلات والكتالوجات **وملفات PDF**. كل صفحة Widget عادي في Flutter وبتفضل تفاعلية بالكامل، فتقدر تعمل بيها كتب إلكترونية، وقارئ مصحف أو مانجا، وعارض PDF بتقليب الصفحات.

## المميزات

- **انحناء ورق واقعي**: الورقة بتتني، ولها ضهر أبيض، والظلال بتظهر على الثنية وعند كعب الكتاب وعلى الصفحة اللي تحتها.
- **صفحات تفاعلية**: الزراير والـ text fields والـ scroll views جوه الصفحة بتشتغل عادي، والزراير اللي في الكرنر بتفضل قابلة للضغط.
- **صفحة واحدة أو صفحتين أو `auto`**: صفحة واحدة على الموبايل، وصفحتين جنب بعض على التابلت والديسكتوب.
- **كتب PDF** بـ `TurnablePdf`، من asset أو رابط أو ملف. اللينكات جوه الـ PDF بتشتغل، والنص بيفضل واضح وإنت عامل zoom.
- **كتب صور** بـ `TurnableImages` للكوميكس والمانجا والكتالوجات وألبومات الصور، والصفحات الجاية بتتحمّل قبل ما توصلها.
- **غلاف مقوّى**: الغلاف (أو كل الصفحات) بيلف كلوح جامد بدل ما يتني.
- **سُمك الكتاب من الجنب**: خطوط رفيعة جنب الصفحات بتوضح فاضل قد إيه. في وضع الصفحتين، الجنب الشمال بيتخن وإنت بتقرا والجنب اليمين بيخس. في وضع الصفحة الواحدة بيظهر بس سُمك الصفحات الباقية، على الحرف الخارجي للصفحة.
- **شريط تنقّل** (`PageScrubber`) تروح بيه لأي صفحة، وممكن تظهر معاه معاينة للصفحة، وكل جزء فيه قابل للتخصيص.
- **تلميح الكرنر**: الكرنر بيتني شوية لما الماوس يقرب منه، أو مرة واحدة أول ما الكتاب يفتح.
- **تقليب تلقائي** للعروض والشاشات.
- **صوت واهتزاز**: اهتزاز خفيف مع كل قلبة، و`onPageTurn` علشان تشغّل صوت تقليب بنفسك.
- **الكيبورد والماوس وقارئ الشاشة**: الأسهم وPage Up/Down وHome/End وعجلة الماوس بيقلّبوا الصفحات، وقارئ الشاشة بيقول "صفحة 3 من 10".
- **الوضع الداكن**: الظلال بتتظبط على الورق الغامق، وفيه ورق لامع اختياري للمجلات.
- **تقليل الحركة**: التقليب بيبقى أقصر لو النظام طالب حركة أقل.
- **كتب من اليمين للشمال** للعربي والعبري والفارسي والأردو، والتقليب معكوس.
- **Controller**: الصفحة الجاية أو اللي قبلها، أو انتقال بأنيميشن أو من غيره لأي صفحة، مع الاستماع للأحداث.
- **كتب كبيرة**: بيتبني بس الصفحات القريبة من الصفحة الحالية.

## التثبيت

```yaml
dependencies:
  turnable_page: ^2.2.0
```

```dart
import 'package:turnable_page/turnable_page.dart';
```

## بداية سريعة

</div>

```dart
TurnablePage(
  pageCount: 10,
  pageViewMode: PageViewMode.auto,
  textDirection: TextDirection.rtl, // كتاب عربي: الصفحة الأولى على اليمين
  builder: (context, pageIndex, constraints) {
    return ColoredBox(
      color: Colors.white,
      child: Center(child: Text('صفحة ${pageIndex + 1}')),
    );
  },
)
```

<div dir="rtl">

اسحب الصفحة أو اضغط عليها علشان تقلبها. الكتاب بياخد مقاسه من الـ parent وبيحافظ على `aspectRatio`.

## التحكم بالـ Controller

</div>

```dart
final controller = PageFlipController();

await controller.nextPage();      // بأنيميشن
await controller.animateToPage(7);
controller.jumpToPage(3);         // فورًا

controller.startAutoPlay(interval: const Duration(seconds: 4), loop: true);
controller.stopAutoPlay();
```

<div dir="rtl">

الـ controller نوعه `ChangeNotifier`، فـ `ListenableBuilder` بيعمل rebuild مع كل تغيير في الصفحة.

## شريط التنقّل

</div>

```dart
Column(children: [
  Expanded(child: TurnablePage(controller: controller, ...)),
  PageScrubber(
    controller: controller,
    activeColor: Colors.brown,
    previewBuilder: (context, i) => Image.asset('thumbs/$i.jpg'), // اختياري
  ),
])
```

<div dir="rtl">

تقدر تغيّر المقاسات والألوان والـ thumb والعنوان والمعاينة. وفي الكتب العربية الشريط بيمشي من اليمين للشمال.

## كتاب حقيقي

</div>

```dart
FlipSettings(
  hardCover: true,      // غلاف مقوّى
  showPageEdges: true,  // سُمك الكتاب من الجنب
  paperGloss: 0.6,      // ورق لامع زي المجلات
  peekOnOpen: true,     // الكرنر بيتني مرة أول ما الكتاب يفتح
  hapticFeedback: true, // اهتزاز خفيف مع كل قلبة
)
```

<div dir="rtl">

## كتب الصور وملفات PDF

</div>

```dart
TurnableImages.network(urls, pageViewMode: PageViewMode.auto);

// شغّل محرك الـ PDF مرة واحدة قبل runApp:
await TurnablePdf.initPDFLoaders();
TurnablePdf.asset('assets/book.pdf', onLinkTap: (link) { /* افتح الرابط */ });
```

<div dir="rtl">

## الصفحات التفاعلية

لما تضغط على جزء فاضي من الصفحة بتتقلب، والكرنرات محجوزة للتقليب. الزراير واللينكات والـ text fields بتفضل شغالة حتى لو في الكرنر. ولو صفحاتك فيها أماكن ضغط كتير (زي الآيات)، اقفل التقليب بالضغط بـ `FlipSettings(flipOnTap: false)`.

## التوثيق

[موقع التوثيق](https://saeedahmed725.github.io/turnable_page/) فيه شرح كامل لكل الإعدادات وأمثلة وملعب تجربة مباشر.

## الترخيص

Turnable Page Proprietary License (TPPL) v1.1. مسموح تستخدم الباكدج من غير تعديل في أي تطبيق، حتى التطبيقات التجارية. التعديل أو النسخ أو إعادة التوزيع أو البيع للباكدج نفسها محتاج إذن مكتوب. التفاصيل في [LICENSE](LICENSE).

</div>
