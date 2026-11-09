const inviteAndroidLink = 'https://play.google.com/store/apps/details?id=com.ayoub.usertaxista';
const inviteIosLink = 'https://apps.apple.com/app/id6739538467';

/// What a rider sends to a friend with their code.
String inviteMessage(String code) => '''🚕 جرب تاكسيستا لمشاويرك!

سعر واضح قبل ما تطلب، وسائق قريب منك تتابعه على الخريطة لين يوصلك.

🎁 سجّل واكتب كود الدعوة متاعي: $code

حمّل التطبيق توا:
أندرويد: $inviteAndroidLink
آيفون: $inviteIosLink''';
