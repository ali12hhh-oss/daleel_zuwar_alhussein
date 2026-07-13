import '../models/models.dart';

const List<AhlulBaytEvent> ahlulBaytEvents = [
  // النبي محمد صلى الله عليه وآله
  AhlulBaytEvent(
    personName: 'النبي محمد صلى الله عليه وآله',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '17 ربيع الأول',
        attributedTo: 'المشهور عند علماء الإمامية (مفاتيح الجنان)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد صلى الله عليه وآله في مكة المكرمة، عام الفيل.',
    source: 'إعلام الورى، بحار الأنوار',
  ),
  AhlulBaytEvent(
    personName: 'النبي محمد صلى الله عليه وآله',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '28 صفر',
        hijriYear: '11 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (مفاتيح الجنان)',
        isMostFamous: true,
      ),
    ],
    description: 'توفي صلى الله عليه وآله في المدينة المنورة؛ وتذكر بعض الروايات الشيعية أنه دُسّ له السمّ في خيبر قبل ذلك بأثر متأخر.',
    source: 'بحار الأنوار',
  ),

  // السيدة خديجة الكبرى عليها السلام
  AhlulBaytEvent(
    personName: 'السيدة خديجة بنت خويلد عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'شعبان (يوم غير محدد بدقة في المصادر الشيعية)',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام في مكة المكرمة، وهي أول زوجات النبي صلى الله عليه وآله وأم السيدة فاطمة الزهراء عليها السلام.',
    source: 'بحار الأنوار، إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'السيدة خديجة بنت خويلد عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 رمضان',
        hijriYear: '3 هـ قبل البعث',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: 'رمضان',
        attributedTo: 'رواية أخرى تذكرها بعض المصادر الشيعية',
        note: 'توفيت قبل البعث النبوي بثلاث سنين',
      ),
    ],
    description: 'توفيت عليها السلام في مكة المكرمة قبل الهجرة، وهي أول من آمن بالنبي صلى الله عليه وآله.',
    source: 'بحار الأنوار، الكافي',
  ),

  // أبو طالب عليه السلام
  AhlulBaytEvent(
    personName: 'أبو طالب بن عبد المطلب عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة في المصادر الشيعية',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في مكة المكرمة، وهو عم النبي صلى الله عليه وآله وأبو الإمام علي عليه السلام. كان سيد قريش وكافل النبي وحاميه.',
    source: 'إعلام الورى، بحار الأنوار',
  ),
  AhlulBaytEvent(
    personName: 'أبو طالب بن عبد المطلب عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'شعبان',
        hijriYear: '10 هـ قبل البعث',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'توفي عليه السلام في مكة المكرمة، وهو من المؤمنين بحسب الروايات الشيعية (توفي قبل نزول آية الإنذار العلني).',
    source: 'بحار الأنوار، الكافي',
  ),

  // أبو ذر الغفاري عليه السلام
  AhlulBaytEvent(
    personName: 'أبو ذر جندب بن جنادة الغفاري عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة في المصادر الشيعية',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في قبيلة غفار، وهو من أوائل من أسلم وأعلن إسلامه جهاراً.',
    source: 'بحار الأنوار، إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'أبو ذر جندب بن جنادة الغفاري عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'ذي الحجة أو ربيع الأول',
        hijriYear: '32 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: '31 هـ',
        attributedTo: 'رواية أخرى وردت في بعض المصادر الشيعية',
      ),
    ],
    description: 'توفي عليه السلام في الربذة منفياً بأمر عثمان بن عفان، وكان من أشد الناس ولاءً لأهل البيت عليهم السلام.',
    source: 'بحار الأنوار، الكافي',
  ),

  // سلمان المحمدي (الفارسي) عليه السلام
  AhlulBaytEvent(
    personName: 'سلمان الفارسي المحمدي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة في المصادر الشيعية',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في فارس (إيران)، ورحل طويلاً بحثاً عن الحق حتى وصل إلى النبي صلى الله عليه وآله. كان من أهل البيت بحسب الحديث الشريف.',
    source: 'بحار الأنوار، الكافي',
  ),
  AhlulBaytEvent(
    personName: 'سلمان الفارسي المحمدي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'ذي القعدة',
        hijriYear: '35 أو 36 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'توفي عليه السلام في المدائن (العراق)، وهو من أصحاب النبي صلى الله عليه وآله المقربين جداً.',
    source: 'بحار الأنوار، الكافي',
  ),

  // سعيد بن جبير عليه السلام
  AhlulBaytEvent(
    personName: 'سعيد بن جبير بن هشام الأسدي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة في المصادر الشيعية',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في الكوفة، وهو تابعي جليل ومن أصحاب الإمام علي والإمام الباقر عليهما السلام.',
    source: 'بحار الأنوار، إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'سعيد بن جبير بن هشام الأسدي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '19 رمضان',
        hijriYear: '95 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام على يد الحجاج بن يوسف الثقفي، وهو من أبرز علماء التابعين ومن أشد الناس ولاءً لأهل البيت.',
    source: 'بحار الأنوار، الكافي',
  ),

  // السيدة فاطمة الزهراء عليها السلام
  AhlulBaytEvent(
    personName: 'السيدة فاطمة الزهراء عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '20 جمادى الآخرة',
        attributedTo: 'أكثر علماء الشيعة ومؤرخيهم: المجلسي، الطبرسي، الكليني، الإربلي، النيسابوري، الشيخ الصدوق، ابن شهرآشوب',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: 'بعد المبعث النبوي بعامين (بدون تحديد يوم دقيق)',
        attributedTo: 'الشيخ المفيد في حدائق الرياض (نقله عنه الكفعمي في مصباح المتهجد والعدد القوية)',
      ),
    ],
    description: 'ولدت عليها السلام في مكة المكرمة بنت رسول الله صلى الله عليه وآله.',
    source: 'كشف الغمة، بحار الأنوار، موقع المعرفة',
  ),
  AhlulBaytEvent(
    personName: 'السيدة فاطمة الزهراء عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '3 جمادى الآخرة (بعد وفاة النبي بـ95 يوماً)',
        attributedTo: 'الشيخ المفيد، الشيخ الطوسي، السيد ابن طاووس، الشيخ الكفعمي — وصرّح العلامة المجلسي بأنه القول المشهور',
        isMostFamous: true,
        note: 'رواية الخمسة والتسعين يوماً',
      ),
      Narration(
        hijriDate: '13 جمادى الأولى (بعد وفاة النبي بـ75 يوماً)',
        attributedTo: 'الكليني في الكافي، الشيخ المفيد في الاختصاص، ابن شهرآشوب في المناقب — عن الإمام الصادق عليه السلام؛ ومن المتأخرين: المحقق النائيني والشيخ عبد الكريم الحائري والسيد صادق الروحاني',
        note: 'رواية الخمسة والسبعين يوماً',
      ),
      Narration(
        hijriDate: '8 ربيع الثاني (بعد وفاة النبي بـ40 يوماً)',
        attributedTo: 'تُنسب عادة إلى الشيخ ابن شهرآشوب في المناقب (نسبة غير جازمة)، وذكر الشيخ خضر شلّال أنه مشهور سواد الإمامية',
        note: 'رواية الأربعين يوماً',
      ),
    ],
    description: 'استشهدت عليها السلام متأثرة بما جرى عليها بعد وفاة أبيها صلى الله عليه وآله، بحسب الروايات الشيعية. اختلفت الروايات في تحديد يوم استشهادها تحديداً، لذا وردت أكثر من رواية معتبرة كما هو مبيّن أعلاه.',
    source: 'دلائل الإمامة، بحار الأنوار، شبكة رافد',
  ),

  // الإمام علي عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام علي بن أبي طالب عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '13 رجب',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى، بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام داخل الكعبة المشرفة بحسب الرواية الشيعية المشهورة.',
    source: 'إعلام الورى، بحار الأنوار',
  ),
  AhlulBaytEvent(
    personName: 'الإمام علي بن أبي طالب عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '21 رمضان',
        hijriYear: '40 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار، إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام إثر ضربة سيف من عبد الرحمن بن ملجم وهو يصلي صلاة الفجر في مسجد الكوفة، بعد أن ضُرب ليلة 19 رمضان وبقي بين الحياة والموت يومين.',
    source: 'بحار الأنوار، إعلام الورى',
  ),

  // أم البنين عليها السلام
  AhlulBaytEvent(
    personName: 'أم البنين فاطمة بنت حزام الكلابية عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة في المصادر الشيعية',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام، وهي زوجة الإمام علي عليه السلام وأم العباس وجعفر وعثمان وعبد الله (شهداء كربلاء).',
    source: 'بحار الأنوار، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'أم البنين فاطمة بنت حزام الكلابية عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '13 جمادى الآخرة',
        hijriYear: '64 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: 'جمادى الآخرة',
        attributedTo: 'رواية أخرى وردت في بعض المصادر الشيعية',
      ),
    ],
    description: 'توفيت عليها السلام في الكوفة، وهي من أعظم النساء في التاريخ الإسلامي وأم الشهداء الأربعة في كربلاء.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),

  // الإمام الحسن عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام الحسن بن علي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '15 رمضان',
        hijriYear: '3 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة، وهو أول أبناء الإمام علي والسيدة فاطمة عليهما السلام.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام الحسن بن علي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '28 صفر',
        hijriYear: '50 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار، إعلام الورى)',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: '7 صفر',
        attributedTo: 'رواية أخرى وردت في بعض المصادر المتأخرة',
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في المدينة المنورة على يد زوجته جعدة بتحريض من معاوية بن أبي سفيان، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار، إعلام الورى',
  ),

  // الإمام الحسين عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام الحسين بن علي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '3 شعبان',
        hijriYear: '4 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام الحسين بن علي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في معركة كربلاء مع أهل بيته وأصحابه.',
    source: 'اللهوف، بحار الأنوار',
  ),

  // علي الأكبر عليه السلام
  AhlulBaytEvent(
    personName: 'علي الأكبر بن الحسين عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '11 شعبان',
        hijriYear: '33 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة، وهو أكبر أبناء الإمام الحسين عليه السلام وأشبه الناس بالنبي صلى الله عليه وآله.',
    source: 'مقتل المقرم، اللهوف',
  ),
  AhlulBaytEvent(
    personName: 'علي الأكبر بن الحسين عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو يقاتل بشجاعة نادرة، وكان أول من استشهد من بني هاشم بعد القاسم.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // القاسم بن الحسن عليه السلام
  AhlulBaytEvent(
    personName: 'القاسم بن الحسن بن علي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'شعبان',
        hijriYear: '47 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة، وهو ابن الإمام الحسن المجتبى عليه السلام.',
    source: 'مقتل المقرم، اللهوف',
  ),
  AhlulBaytEvent(
    personName: 'القاسم بن الحسن بن علي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو غلام شاب، وقد طلب من عمه الإمام الحسين عليه السلام الإذن بالجهاد.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // عبد الله بن الحسن (الأكبر) عليه السلام
  AhlulBaytEvent(
    personName: 'عبد الله بن الحسن المجتبى عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة، وهو ابن الإمام الحسن المجتبى عليه السلام وشقيق القاسم.',
    source: 'مقتل المقرم، اللهوف',
  ),
  AhlulBaytEvent(
    personName: 'عبد الله بن الحسن المجتبى عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو يدافع عن عمه الإمام الحسين عليه السلام، وقد قُتل وهو يحمي أخاه القاسم.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // السيدة فاطمة الصغرى عليها السلام
  AhlulBaytEvent(
    personName: 'السيدة فاطمة الصغرى بنت الحسين عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام في المدينة المنورة، وهي ابنة الإمام الحسين عليه السلام وأخت السيدة سكينة.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'السيدة فاطمة الصغرى بنت الحسين عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'بعد عاشوراء',
        hijriYear: '61 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'توفيت عليها السلام بعد أحداث كربلاء، وهي من سبايا كربلاء.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),

  // أم كلثوم بنت علي عليها السلام
  AhlulBaytEvent(
    personName: 'أم كلثوم بنت علي عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام في المدينة المنورة، وهي ابنة الإمام علي والسيدة فاطمة الزهراء عليهما السلام وأخت الإمام الحسن والحسين.',
    source: 'بحار الأنوار، إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'أم كلثوم بنت علي عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'بعد عاشوراء',
        hijriYear: '61 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'توفيت عليها السلام بعد أحداث كربلاء، وهي من سبايا كربلاء ومن خطب في الكوفة.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),

  // رقية بنت علي عليها السلام
  AhlulBaytEvent(
    personName: 'رقية بنت علي عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام في المدينة المنورة، وهي ابنة الإمام علي والسيدة فاطمة الزهراء عليهما السلام.',
    source: 'بحار الأنوار، إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'رقية بنت علي عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'بعد عاشوراء',
        hijriYear: '61 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'توفيت عليها السلام بعد أحداث كربلاء في الشام بحسب بعض الروايات الشيعية.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),

  // سكينة بنت الحسين عليها السلام
  AhlulBaytEvent(
    personName: 'سكينة بنت الحسين عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '20 رجب',
        hijriYear: '56 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام في المدينة المنورة، وهي ابنة الإمام الحسين عليه السلام ومن أشهر شخصيات كربلاء.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'سكينة بنت الحسين عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '5 ربيع الأول',
        hijriYear: '117 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'توفيت عليها السلام في المدينة المنورة بعد عودتها من الشام، وهي من أشهر خطباء كربلاء.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),

  // فاطمة بنت الحسين عليها السلام
  AhlulBaytEvent(
    personName: 'فاطمة بنت الحسين عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'شعبان',
        hijriYear: '57 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام في المدينة المنورة، وهي ابنة الإمام الحسين عليه السلام وزوجة الحسن المثنى.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'فاطمة بنت الحسين عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'بعد عاشوراء',
        hijriYear: '61 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'توفيت عليها السلام بعد أحداث كربلاء، وهي من سبايا كربلاء.',
    source: 'بحار الأنوار، مقتل المقرم',
  ),

  // الإمام زين العابدين عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام علي بن الحسين زين العابدين عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '5 شعبان',
        hijriYear: '38 هـ',
        attributedTo: 'الرواية الأشهر في المصادر المعاصرة (إعلام الورى)',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: '15 جمادى الأولى',
        hijriYear: '36 هـ',
        attributedTo: 'رواية أخرى وردت في بعض كتب التراجم',
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى، مركز الإشعاع الإسلامي',
  ),
  AhlulBaytEvent(
    personName: 'الإمام علي بن الحسين زين العابدين عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '25 محرم',
        hijriYear: '95 هـ',
        attributedTo: 'الرواية الأشهر والمعتمدة في التقاويم الشيعية المعاصرة',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: '18 محرم',
        hijriYear: '95 هـ',
        attributedTo: 'رواية أخرى ذكرها بعض المؤرخين',
      ),
      Narration(
        hijriDate: '12 محرم',
        hijriYear: '94 أو 95 هـ',
        attributedTo: 'رواية ثالثة، والسنة عُرفت بـ"سنة الفقهاء" لكثرة وفاة العلماء فيها',
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في المدينة المنورة بأمر الوليد بن عبد الملك، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار، شبكة المعارف الإسلامية',
  ),

  // الإمام الباقر عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام محمد بن علي الباقر عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '1 رجب',
        hijriYear: '57 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام محمد بن علي الباقر عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '7 ذو الحجة',
        hijriYear: '114 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في المدينة المنورة بأمر هشام بن عبد الملك، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار',
  ),

  // الإمام الصادق عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام جعفر بن محمد الصادق عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '17 ربيع الأول',
        hijriYear: '83 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام جعفر بن محمد الصادق عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '25 شوال',
        hijriYear: '148 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في المدينة المنورة بأمر المنصور الدوانيقي، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار',
  ),

  // الإمام الكاظم عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام موسى بن جعفر الكاظم عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '7 صفر',
        hijriYear: '128 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في منطقة الأبواء قرب المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام موسى بن جعفر الكاظم عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '25 رجب',
        hijriYear: '183 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في سجن هارون الرشيد ببغداد على يد السندي بن شاهك، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار',
  ),

  // الإمام الرضا عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام علي بن موسى الرضا عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '11 ذو القعدة',
        hijriYear: '148 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام علي بن موسى الرضا عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'آخر يوم من صفر (29 صفر)',
        hijriYear: '203 هـ',
        attributedTo: 'الرواية الأشهر والمعتمدة في أغلب التقاويم الشيعية المعاصرة',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: '17 صفر',
        attributedTo: 'رواية أخرى وردت في بعض المصادر',
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في مدينة طوس (مشهد المقدسة حالياً) بأمر المأمون العباسي، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار',
  ),

  // الإمام الجواد عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام محمد بن علي الجواد عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '10 رجب',
        hijriYear: '195 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام محمد بن علي الجواد عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'آخر يوم من ذي القعدة (29 ذو القعدة)',
        hijriYear: '220 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في بغداد على يد زوجته أم الفضل بتحريض من المعتصم العباسي، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار',
  ),

  // الإمام الهادي عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام علي بن محمد الهادي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '15 ذو الحجة',
        hijriYear: '212 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (إعلام الورى)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام علي بن محمد الهادي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '3 رجب',
        hijriYear: '254 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في مدينة سامراء بأمر المعتز العباسي، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار',
  ),

  // الإمام العسكري عليه السلام
  AhlulBaytEvent(
    personName: 'الإمام الحسن بن علي العسكري عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '8 ربيع الثاني',
        hijriYear: '232 هـ',
        attributedTo: 'الرواية الأشهر في المصادر المعاصرة',
        isMostFamous: true,
      ),
      Narration(
        hijriDate: '4 ربيع الثاني',
        hijriYear: '232 هـ',
        attributedTo: 'رواية أخرى وردت في بعض كتب التراجم',
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة.',
    source: 'إعلام الورى',
  ),
  AhlulBaytEvent(
    personName: 'الإمام الحسن بن علي العسكري عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '8 ربيع الأول',
        hijriYear: '260 هـ',
        attributedTo: 'المشهور عند علماء الإمامية (بحار الأنوار)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام مسموماً في مدينة سامراء بأمر المعتمد العباسي، بحسب الروايات الشيعية.',
    source: 'بحار الأنوار',
  ),

  // الإمام المهدي عجل الله فرجه
  AhlulBaytEvent(
    personName: 'الإمام محمد بن الحسن المهدي عجل الله فرجه',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '15 شعبان',
        hijriYear: '255 هـ',
        attributedTo: 'إجماع المصادر الشيعية (بحار الأنوار، كمال الدين للشيخ الصدوق)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في مدينة سامراء؛ وهو حيّ باقٍ في غيبة بحسب العقيدة الشيعية، ولم يستشهد.',
    source: 'بحار الأنوار، كمال الدين',
  ),

  // السيدة زينب عليها السلام
  AhlulBaytEvent(
    personName: 'السيدة زينب بنت علي عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '5 جمادى الأولى',
        hijriYear: '5 أو 6 هـ',
        attributedTo: 'رواية شائعة في كتب التراجم المعاصرة',
        isMostFamous: true,
      ),
    ],
    description: 'ولدت عليها السلام في المدينة المنورة. وردت روايات مختلفة في تحديد سنة ولادتها بدقة.',
    source: 'مصادر تراجم شيعية عامة',
  ),
  AhlulBaytEvent(
    personName: 'السيدة زينب بنت علي عليها السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '15 رجب',
        attributedTo: 'رواية شائعة يعتمدها من يقول بأن مرقدها في دمشق',
        isMostFamous: true,
      ),
    ],
    description: 'توفيت عليها السلام بعد عودتها من الشام؛ وهناك خلاف تاريخي بين علماء الشيعة أنفسهم حول مكان وفاتها ودفنها: فالمشهور عند كثيرين أن مرقدها في دمشق، بينما يذهب آخرون إلى أنه في مصر.',
    source: 'مصادر تراجم شيعية عامة',
  ),

  // أبو الفضل العباس عليه السلام
  AhlulBaytEvent(
    personName: 'أبو الفضل العباس بن علي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '4 شعبان',
        hijriYear: '26 هـ',
        attributedTo: 'رواية شائعة في كتب التراجم المعاصرة',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة، وهو نجل الإمام علي عليه السلام من أم البنين.',
    source: 'مصادر تراجم شيعية عامة',
  ),
  AhlulBaytEvent(
    personName: 'أبو الفضل العباس بن علي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو يحاول إحضار الماء لمخيم أخيه الإمام الحسين عليه السلام.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // مسلم بن عقيل عليه السلام
  AhlulBaytEvent(
    personName: 'مسلم بن عقيل بن أبي طالب عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة في المصادر الشيعية',
        attributedTo: 'المشهور عند علماء الإمامية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في المدينة المنورة، وهو ابن عم الإمام الحسين عليه السلام ورسوله إلى الكوفة.',
    source: 'اللهوف، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'مسلم بن عقيل بن أبي طالب عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '9 ذو الحجة (يوم عرفة)',
        hijriYear: '60 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في الكوفة على يد عبيد الله بن زياد بعد أن خذله أهل الكوفة، وهو أول شهداء كربلاء.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // حبيب بن مظاهر الأسدي عليه السلام
  AhlulBaytEvent(
    personName: 'حبيب بن مظاهر الأسدي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في الكوفة، وهو من أصحاب الإمام علي عليه السلام ومن أشجع فرسان كربلاء.',
    source: 'اللهوف، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'حبيب بن مظاهر الأسدي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو يقاتل إلى جوار الإمام الحسين عليه السلام.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // جون (مولى أبي ذر) عليه السلام
  AhlulBaytEvent(
    personName: 'جون مولى أبي ذر الغفاري عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام، وهو مولى أبي ذر الغفاري ومن أصحاب الإمام الحسين عليه السلام.',
    source: 'اللهوف، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'جون مولى أبي ذر الغفاري عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو يحمل الماء للأطفال العطاشى.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // حر بن يزيد الرياحي عليه السلام
  AhlulBaytEvent(
    personName: 'حر بن يزيد الرياحي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام، وهو قائد الفرسان في جيش عبيد الله بن زياد ثم انضم إلى الإمام الحسين عليه السلام.',
    source: 'اللهوف، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'حر بن يزيد الرياحي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو أول من استشهد من أصحاب الإمام الحسين عليه السلام في يوم عاشوراء.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // مسلم بن عوسجة عليه السلام
  AhlulBaytEvent(
    personName: 'مسلم بن عوسجة عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام، وهو من أصحاب الإمام علي عليه السلام ومن شهداء كربلاء.',
    source: 'اللهوف، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'مسلم بن عوسجة عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '10 محرم (يوم عاشوراء)',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في كربلاء وهو يقاتل بشجاعة إلى جوار الإمام الحسين عليه السلام.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // هاني بن عروة عليه السلام
  AhlulBaytEvent(
    personName: 'هاني بن عروة المرادي عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام في الكوفة، وهو صاحب دار هاني التي كانت مقر مسلم بن عقيل.',
    source: 'اللهوف، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'هاني بن عروة المرادي عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: '9 ذو الحجة (قبل عاشوراء)',
        hijriYear: '60 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام في الكوفة على يد عبيد الله بن زياد مع مسلم بن عقيل.',
    source: 'اللهوف، مقتل المقرم',
  ),

  // عبد الله بن يقطر عليه السلام
  AhlulBaytEvent(
    personName: 'عبد الله بن يقطر عليه السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: 'غير محدد بدقة',
        attributedTo: 'المشهور عند علماء الإمامية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'ولد عليه السلام، وهو خادم الإمام الحسين عليه السلام ومن أصحابه المخلصين.',
    source: 'اللهوف، مقتل المقرم',
  ),
  AhlulBaytEvent(
    personName: 'عبد الله بن يقطر عليه السلام',
    kind: EventKind.death,
    narrations: [
      Narration(
        hijriDate: 'قبل عاشوراء',
        hijriYear: '61 هـ',
        attributedTo: 'إجماع المصادر الشيعية (اللهوف، مقتل المقرم)',
        isMostFamous: true,
      ),
    ],
    description: 'استشهد عليه السلام قبل يوم عاشوراء وهو يحمل رسالة من الإمام الحسين عليه السلام.',
    source: 'اللهوف، مقتل المقرم',
  ),
];
