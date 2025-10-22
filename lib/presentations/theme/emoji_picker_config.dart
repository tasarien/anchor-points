import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Config emojiPickerConfig(BuildContext context) {
  ColorScheme colorScheme = Theme.of(context).colorScheme;
  return Config(
    skinToneConfig: SkinToneConfig(enabled: false),

    emojiViewConfig: EmojiViewConfig(
      columns: 7,
      emojiSizeMax: 32,
      verticalSpacing: 0,
      horizontalSpacing: 0,
      gridPadding: EdgeInsets.zero,
      recentsLimit: 28,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    ),
    searchViewConfig: SearchViewConfig(backgroundColor: colorScheme.surface),
    categoryViewConfig: CategoryViewConfig(
      initCategory: Category.OBJECTS,
      indicatorColor: colorScheme.onSurface,
      iconColor: colorScheme.secondary,
      iconColorSelected: colorScheme.onSurface,
      backspaceColor: colorScheme.tertiary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      recentTabBehavior: RecentTabBehavior.RECENT,
    ),

    checkPlatformCompatibility: true,
    emojiTextStyle: TextStyle(
      fontFamily: "Emoji",
      color: colorScheme.onSurface,
    ),
  );
}
