import 'package:flutter/material.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import 'card_vault.dart';
import 'moamalat_api.dart';
import 'moamalat_env.dart';
import 'secure_clipboard.dart';

/// The only Rider-specific piece of the Moamalat module: it wires the shared
/// screens to this app's session, API root and colours.
MoamalatEnv buildMoamalatEnv({VoidCallback? onWalletChanged}) {
  final ownerId = (userDetails['id'] ?? userDetails['user_id'] ?? 'unknown').toString();
  return MoamalatEnv(
    api: HttpMoamalatApi(
      baseUrl: url,
      token: () => bearerToken.isEmpty ? '' : bearerToken[0].token.toString(),
    ),
    vault: CardVault(store: const SecureStorageSecretStore(), ownerId: ownerId),
    clipboard: SecureClipboard(),
    isRtl: languageDirection == 'rtl',
    onWalletChanged: onWalletChanged,
    accent: theme,
    background: page,
    surface: topBar,
    text: textColor,
    muted: greyText,
    border: borderLines,
  );
}
