import '../../growth/my_gifts_page.dart';
import '../pulse/routines_page.dart';
import '../recurring/recurring_rides_page.dart';
import '../../community/favorites_page.dart';
import '../../community/rewards_page.dart';
import 'package:flutter/material.dart';
import 'package:taxista/pages/NavigatorPages/fav_address.dart';
import 'package:taxista/pages/NavigatorPages/makecomplaint.dart';
import 'package:taxista/pages/NavigatorPages/outstation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/editprofile.dart';
import '../NavigatorPages/history.dart';
import '../NavigatorPages/notification.dart';
import '../NavigatorPages/upcoming_scheduled_rides.dart';
import '../NavigatorPages/referral.dart';
import '../NavigatorPages/settings.dart';
import '../NavigatorPages/sos.dart';
import '../NavigatorPages/support.dart';
import '../NavigatorPages/walletpage.dart';
import '../onTripPage/map_page.dart';
import '../../navigation/guarded_navigation.dart';
import '../../contests/contests_pages.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({super.key});
  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  /// Opens a page from a menu item. The drawer is closed first, so coming back
  /// shows the map - not the same menu still open on top of it.
  Future<T?> _open<T>(Route<T> route) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) scaffold.closeDrawer();
    return guardedPush(context, route);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final rtl = languageDirection == 'rtl';
    String t(String key, String ar, String en) => rtl ? ar : (languages[choosenLanguage]?[key]?.toString() ?? en);
    return ValueListenableBuilder(
        valueListenable: valueNotifierHome.value,
        builder: (context, value, child) {
          final rides = _rideCampaign();
          final balance = walletBalance['wallet_balance'];
          final showWallet = userDetails['owner_id'] == null &&
              userDetails['show_wallet_feature_on_mobile_app'].toString() == '1';
          return SizedBox(
            width: media.width * 0.8,
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                height: media.height,
                width: media.width * 0.8,
                color: page,
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top + 12),
                    // the rider: photo, name, phone; a tap opens the profile
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Material(
                        color: theme,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final val = await _open(MaterialPageRoute(builder: (context) => const EditProfile()));
                            if (val == true) setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: .7), width: 2),
                                  image: DecorationImage(image: NetworkImage(userDetails['profile_picture'].toString()), fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${userDetails['name'] ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.25)),
                                  Text('${userDetails['mobile'] ?? ''}',
                                      textDirection: TextDirection.ltr,
                                      style: GoogleFonts.notoSans(color: Colors.white.withValues(alpha: .85), fontSize: 13, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                              Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: Colors.white),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    // two numbers at a glance (only what the app already knows)
                    if ((showWallet && balance != null) || rides != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: Row(children: [
                          if (showWallet && balance != null)
                            Expanded(
                              child: _StatChip(
                                icon: Icons.account_balance_wallet_outlined,
                                text: '$balance ${walletBalance['currency_symbol'] ?? ''}',
                                onTap: () => _open(MaterialPageRoute(builder: (context) => const WalletPage())),
                              ),
                            ),
                          if (showWallet && balance != null && rides != null) const SizedBox(width: 8),
                          if (rides != null)
                            Expanded(
                              child: _StatChip(
                                icon: Icons.emoji_events_outlined,
                                text: rtl ? '${rides.$1} / ${rides.$2} رحلة' : '${rides.$1} / ${rides.$2} rides',
                                onTap: () => _open(MaterialPageRoute(builder: (context) => const RewardsPage())),
                              ),
                            ),
                        ]),
                      ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 24),
                        children: [
                          _Section(rtl ? 'رحلاتي' : 'My rides'),
                          _DrawerItem(
                            image: 'assets/images/bookmark.png',
                            text: t('text_fav_address', 'عناويني المفضلة', 'Saved places'),
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const FavAddressPage())),
                          ),
                          _DrawerItem(
                            image: 'assets/images/booking.png',
                            text: t('text_enable_history', 'سجل الرحلات', 'Ride history'),
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const History())),
                          ),
                          _DrawerItem(
                            image: 'assets/images/booking.png',
                            text: t('text_upcoming_rides', 'الرحلات القادمة', 'Upcoming rides'),
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const UpcomingScheduledRidesPage())),
                          ),
                          if (userDetails['show_outstation_ride_feature'].toString() == '1')
                            _DrawerItem(
                              icon: Icons.luggage_outlined,
                              text: t('text_outstation', 'رحلات بين المدن', 'Between cities'),
                              onTap: () => _open(MaterialPageRoute(builder: (context) => const OutStationRides())),
                            ),
                          _DrawerItem(
                            icon: Icons.favorite_border_rounded,
                            text: rtl ? 'سواقيني' : 'My drivers',
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const FavoritesPage())),
                          ),
                          _DrawerItem(
                            icon: Icons.event_repeat_rounded,
                            text: rtl ? 'رحلاتي المتكررة' : 'Recurring rides',
                            tag: rtl ? 'جديد' : 'New',
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const RecurringRidesPage())),
                          ),
                          _DrawerItem(
                            icon: Icons.repeat_rounded,
                            text: rtl ? 'رحلاتي المعتادة' : 'Usual rides',
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const PulseRoutinesPage())),
                          ),
                          _Section(rtl ? 'فلوسي ومكافآتي' : 'Money & rewards'),
                          if (showWallet)
                            _DrawerItem(
                              image: 'assets/images/wallet (1).png',
                              text: t('text_enable_wallet', 'المحفظة', 'Wallet'),
                              onTap: () => _open(MaterialPageRoute(builder: (context) => const WalletPage())),
                            ),
                          _DrawerItem(
                            icon: Icons.emoji_events_outlined,
                            text: rtl ? 'مكافآتي' : 'My rewards',
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const RewardsPage())),
                          ),
                          _DrawerItem(
                            icon: Icons.campaign_rounded,
                            text: rtl ? 'منشورات تاكسيستا' : 'Taxista posts',
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const ContestsFeedPage())),
                          ),
                          _DrawerItem(
                            icon: Icons.redeem_rounded,
                            text: rtl ? 'الهدايا والكوبونات' : 'Gifts & coupons',
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const MyGiftsPage())),
                          ),
                          _DrawerItem(
                            image: 'assets/images/gift.png',
                            text: rtl ? 'ادعُ صديقًا' : (languages[choosenLanguage]?['text_referral']?.toString() ?? 'Invite a friend'),
                            onTap: () {
                              // as before: the referral page opens a moment after the menu item
                              Future.delayed(const Duration(microseconds: 500), () {
                                // ignore: use_build_context_synchronously
                                guardedPush(context, MaterialPageRoute(builder: (context) => const ReferralPage()));
                              });
                            },
                          ),
                          _Section(rtl ? 'المساعدة والأمان' : 'Help & safety'),
                          ValueListenableBuilder(
                            valueListenable: valueNotifierNotification.value,
                            builder: (context, value, child) => _DrawerItem(
                              icon: Icons.notifications_none_rounded,
                              text: t('text_notification', 'الإشعارات', 'Notifications'),
                              badge: '${userDetails['notifications_count'] ?? 0}',
                              onTap: () {
                                _open(MaterialPageRoute(builder: (context) => const NotificationPage()));
                                setState(() => userDetails['notifications_count'] = 0);
                              },
                            ),
                          ),
                          ValueListenableBuilder(
                            valueListenable: valueNotifierChat.value,
                            builder: (context, value, child) => _DrawerItem(
                              image: 'assets/images/chat (1).png',
                              text: t('text_support', 'دعم العملاء', 'Support'),
                              badge: unSeenChatCount,
                              onTap: () => _open(MaterialPageRoute(builder: (context) => const SupportPage())),
                            ),
                          ),
                          _DrawerItem(
                            image: 'assets/images/complaint.png',
                            text: t('text_make_complaints', 'تقديم شكوى', 'Make a complaint'),
                            onTap: () => _open(MaterialPageRoute(builder: (context) => const MakeComplaint())),
                          ),
                          _DrawerItem(
                            image: 'assets/images/phone.png',
                            text: t('text_sos', 'الطوارئ وجهات الثقة', 'Emergency (SOS)'),
                            onTap: () async {
                              final nav = await _open(MaterialPageRoute(builder: (context) => const Sos()));
                              if (nav == true) setState(() {});
                            },
                          ),
                          _Section(rtl ? 'التطبيق' : 'App'),
                          _DrawerItem(
                            image: 'assets/images/settings.png',
                            text: t('text_settings', 'الإعدادات', 'Settings'),
                            onTap: () async {
                              final nav = await _open(MaterialPageRoute(builder: (context) => const SettingsPage()));
                              if (nav == true) setState(() {});
                            },
                          ),
                          _DrawerItem(
                            image: 'assets/images/logout.png',
                            text: languages[choosenLanguage]?['text_sign_out']?.toString() ?? (rtl ? 'تسجيل الخروج' : 'Sign out'),
                            color: Colors.red,
                            onTap: () {
                              setState(() => logout = true);
                              valueNotifierHome.incrementNotifier();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  /// the running ride campaign as (done, target), from the same list the home card reads
  (int, int)? _rideCampaign() {
    for (final c in activePromotionCampaigns) {
      if (c['type'] == 'signup_bonus') continue;
      final target = (c['required_rides'] as num?)?.toInt() ?? 0;
      if (target > 0) return ((c['completed_rides'] as num?)?.toInt() ?? 0, target);
    }
    return null;
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 18, 14, 4),
        child: Text(title,
            style: GoogleFonts.cairo(color: theme, fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: .2)),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: theme.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 17, color: theme),
              const SizedBox(width: 6),
              Flexible(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: textColor, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      );
}

/// one menu line: the app's own image (or an icon), the name, and a count or «جديد» on the far side
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.text, required this.onTap, this.image, this.icon, this.badge, this.tag, this.color});
  final String text;
  final VoidCallback onTap;
  final String? image;
  final IconData? icon;
  final String? badge;
  final String? tag;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final count = int.tryParse(badge ?? '') ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: (color ?? theme).withValues(alpha: .07), borderRadius: BorderRadius.circular(11)),
            child: image != null
                ? Image.asset(image!, width: 22, height: 22, fit: BoxFit.contain)
                : Icon(icon, size: 20, color: color ?? theme),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(color: color ?? textColor, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          if (count > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xffE0243A), borderRadius: BorderRadius.circular(99)),
              child: Text('$count', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            )
          else if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: theme.withValues(alpha: .1), borderRadius: BorderRadius.circular(99)),
              child: Text(tag!, style: GoogleFonts.cairo(color: theme, fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
        ]),
      ),
    );
  }
}
