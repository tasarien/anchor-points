import 'package:anchor_point_app/presentations/theme/emoji_picker_config.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

Future<String?> openEmojiPicker(BuildContext context) async {
  final selectedEmoji = await showModalBottomSheet<Emoji>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      return SizedBox(
        height: 300,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            Navigator.pop(context, emoji);
          },
          config: emojiPickerConfig(context),
        ),
      );
    },
  );

  return selectedEmoji?.emoji;
}
