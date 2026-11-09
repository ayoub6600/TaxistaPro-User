const inviteBaseLink = 'https://taxista.aljidartech.com/i/';

/// What a rider sends to a friend: one link that knows who invited them, and the code just in case.
String inviteMessage(String code, {String? friendReward}) => '''🚕 جرب تاكسيستا لمشاويرك!

سعر واضح قبل ما تطلب، وسائق قريب منك تتابعه على الخريطة لين يوصلك.

🎁 سجّل من رابطي توا${friendReward != null ? ' وتاخذ $friendReward بعد أول مشوار' : ''}:
$inviteBaseLink$code

ولو طلب منك كود الدعوة: $code''';
