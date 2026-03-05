import 'package:flutter/material.dart';

/// Maps deal/coupon type to an icon for badge display.
/// Deal types: percentage, fixed, bogo, freebie, other, flash, member_only.
class DealTypeIcons {
  DealTypeIcons._();

  /// Icon for the given [dealType]. Use in badges instead of showing "Percentage off" etc. as text.
  static IconData iconFor(String? dealType) {
    switch (dealType) {
      case 'percentage':
        return Icons.percent_rounded;
      case 'fixed':
        return Icons.attach_money_rounded;
      case 'bogo':
        return Icons.card_giftcard_rounded;
      case 'freebie':
        return Icons.redeem_rounded;
      case 'flash':
        return Icons.bolt_rounded;
      case 'member_only':
        return Icons.lock_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }
}
