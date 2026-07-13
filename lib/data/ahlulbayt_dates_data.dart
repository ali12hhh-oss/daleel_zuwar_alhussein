import '../models/models.dart';

/// أحداث ولادات ووفيات/استشهادات أهل البيت عليهم السلام، بحسب مصادر شيعية
/// معتمدة (بحار الأنوار للمجلسي، إعلام الورى للطبرسي، كشف الغمة للإربلي،
/// مصباح المتهجد للطوسي، الكافي للكليني، مفاتيح الجنان للشيخ عباس القمي).
///
/// حيثما وردت أكثر من رواية شيعية لتاريخ الحدث نفسه، تم ذكر كل الروايات
/// المعروفة مع إسناد كل رواية إلى قائلها/ناقلها، وتحديد الرواية الأشهر
/// (isMostFamous) المعتمدة في أغلب التقاويم الشيعية المعاصرة. حيث لا تتوفر
/// لدينا تفاصيل إسناد دقيقة لروايات إضافية، اكتُفي بذكر الرواية المشهورة
/// فقط مع الإشارة إلى مصدرها العام؛ يُنصح بمراجعة مفاتيح الجنان أو موسوعات
/// التراجم الشيعية المتخصصة لاستقصاء كل الروايات قبل النشر النهائي.
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

  // السيدة فاطمة الزهراء عليها السلام
  AhlulBaytEvent(
    personName: 'السيدة فاطمة الزهراء عليها السلام',
    kind: EventKind.birth,
    narrations: [
      Narration(
        hijriDate: '20 جمادى الآخرة',
        attributedTo:
            'أكثر علماء الشيعة ومؤرخيهم: المجلسي، الطبرسي، الكليني، الإربلي، النيسابوري، الشيخ الصدوق، ابن شهرآشوب',
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
        attributedTo:
            'الشيخ المفيد، الشيخ الطوسي، السيد ابن طاووس، الشيخ الكفعمي — وصرّح العلامة المجلسي بأنه القول المشهور',
        isMostFamous: true,
        note: 'رواية الخمسة والتسعين يوماً',
      ),
      Narration(
        hijriDate: '13 جمادى الأولى (بعد وفاة النبي بـ75 يوماً)',
        attributedTo:
            'الكليني في الكافي، الشيخ المفيد في الاختصاص، ابن شهرآشوب في المناقب — عن الإمام الصادق عليه السلام؛ ومن المتأخرين: المحقق النائيني والشيخ عبد الكريم الحائري والسيد صادق الروحاني',
        note: 'رواية الخمسة والسبعين يوماً',
      ),
      Narration(
        hijriDate: '8 ربيع الثاني (بعد وفاة النبي بـ40 يوماً)',
        attributedTo:
            'تُنسب عادة إلى الشيخ ابن شهرآشوب في المناقب (نسبة غير جازمة)، وذكر الشيخ خضر شلّال أنه مشهور سواد الإمامية',
        note: 'رواية الأربعين يوماً',
      ),
    ],
    description:
        'استشهدت عليها السلام متأثرة بما جرى عليها بعد وفاة أبيها صلى الله عليه وآله، بحسب الروايات الشيعية. اختلفت الروايات في تحديد يوم استشهادها تحديداً، لذا وردت أكثر من رواية معتبرة كما هو مبيّن أعلاه.',
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
    description:
        'استشهد عليه السلام إثر ضربة سيف من عبد الرحمن بن ملجم وهو يصلي صلاة الفجر في مسجد الكوفة، بعد أن ضُرب ليلة 19 رمضان وبقي بين الحياة والموت يومين.',
    source: 'بحار الأنوار، إعلام الورى',
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
];
