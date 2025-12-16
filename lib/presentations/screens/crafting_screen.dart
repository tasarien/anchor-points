import 'package:action_slider/action_slider.dart'; // Assuming this is used somewhere not shown or can be removed
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/core/utils/anchor_point_icons.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/person_invitation.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/data/sources/request_source.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
// import 'package:anchor_point_app/data/sources/request_source.dart'; // Unused in this snippet
import 'package:anchor_point_app/presentations/widgets/drawers/companion_picker.dart';
import 'package:anchor_point_app/presentations/widgets/drawers/invite_person.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Unused in this snippet

enum CompanionType { you, companion, ai }

class CraftingSelection {
  final CompanionType textProvider;
  final CompanionType audioProvider;

  CraftingSelection({required this.textProvider, required this.audioProvider});
}

class CraftingScreen extends StatefulWidget {
  final AnchorPoint anchorPoint;
  const CraftingScreen({Key? key, required this.anchorPoint}) : super(key: key);

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends State<CraftingScreen> {
  CompanionType textProvider = CompanionType.companion;
  CompanionType audioProvider = CompanionType.companion;

  UserProfile? textCompanion;
  UserProfile? audioCompanion;

  PersonInvitation? textInvitation;
  PersonInvitation? audioInvitation;

  // Text controllers for messages
  final TextEditingController _textMessageController = TextEditingController();
  final TextEditingController _audioMessageController = TextEditingController();
  final TextEditingController _combinedMessageController =
      TextEditingController();

  @override
  void dispose() {
    _textMessageController.dispose();
    _audioMessageController.dispose();
    _combinedMessageController.dispose();
    super.dispose();
  }

  bool _needsTextEditor() {
    return textProvider == CompanionType.companion;
  }

  bool _needsAudioEditor() {
    return audioProvider == CompanionType.companion;
  }

  bool _needsCombinedEditor() {
    bool hasSameCompanionPicked() {
      if (textCompanion != null && audioCompanion != null) {
        return textCompanion!.id == audioCompanion!.id;
      }
      if (textInvitation != null && audioInvitation != null) {
        return textInvitation!.id! == audioInvitation!.id!;
      }
      return false;
    }

    bool hasTextAndAudioCompanionType() {
      return textProvider == CompanionType.companion &&
          audioProvider == CompanionType.companion;
    }

    return hasTextAndAudioCompanionType() && hasSameCompanionPicked();
  }

  bool _hasAnyAIProvider() {
    return textProvider == CompanionType.ai ||
        audioProvider == CompanionType.ai;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    DataProvider appData = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 20,
          children: [
            IconButton(
              onPressed: () async {
                Navigator.pop(context);
                await Future.delayed(Duration(milliseconds: 300));
                appData.changeTabVisibility(true);
              },
              icon: FaIcon(FontAwesomeIcons.chevronLeft, size: 18),
            ),
            Text(getText("crafting_screen_title")),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getText('crafting_sheet_subtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Text Writing Section
            _SectionCard(
              icon: FontAwesomeIcons.pencil,
              title: getText('crafting_writing_title'),
              subtitle: getText('crafting_writing_subtitle'),
              child: Column(
                spacing: 20,
                children: [
                  _ToggleSelector(
                    options: [
                      _ToggleOption(
                        value: CompanionType.ai,
                        label: getText('crafting_option_ai'),
                        icon: FontAwesomeIcons.wind,
                      ),
                      _ToggleOption(
                        value: CompanionType.you,
                        label: getText('crafting_option_you'),
                        icon: FontAwesomeIcons.user,
                      ),
                      _ToggleOption(
                        value: CompanionType.companion,
                        label: getText('crafting_option_companion'),
                        icon: FontAwesomeIcons.userGroup,
                      ),
                    ],
                    selected: textProvider,
                    onChanged: (value) {
                      setState(() {
                        textProvider = value;
                      });
                    },
                  ),
                  if (textProvider == CompanionType.companion)
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        WholeButton(
                          onPressed: () async {
                            final UserProfile? result =
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => PickCompanionBottomSheet(),
                                );
                            setState(() {
                              if (result != null) {
                                textCompanion = result;
                                textInvitation = null;
                              }
                            });
                          },
                          icon: textCompanion != null
                              ? FontAwesomeIcons.person
                              : FontAwesomeIcons.magnifyingGlass,
                          text: textCompanion != null
                              ? textCompanion!.username!
                              : getText('find_companion_button'),
                          wide: textCompanion != null,
                        ),
                        WholeButton(
                          onPressed: () async {
                            final PersonInvitation? result =
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => InvitePersonBottomSheet(),
                                );
                            setState(() {
                              if (result != null) {
                                textCompanion = null;
                                textInvitation = result;
                              }
                            });
                          },
                          icon: textInvitation != null
                              ? FontAwesomeIcons.envelope
                              : FontAwesomeIcons.envelopeCircleCheck,
                          text: textInvitation != null
                              ? textInvitation!.name!
                              : getText('invite_friend_button'),
                          wide: textInvitation != null,
                        ),
                      ],
                    ),
                  // Separate text message editor
                  if (_needsTextEditor() && !_needsCombinedEditor())
                    _MessageEditor(
                      controller: _textMessageController,
                      title: getText('message_editor_text_title'),
                      subtitle: textCompanion != null
                          ? getText(
                              'request_user_write_text',
                            ).replaceFirst('{name}', textCompanion!.username!)
                          : textInvitation != null
                          ? getText(
                              'invite_user_write_text',
                            ).replaceFirst('{name}', textInvitation!.name!)
                          : getText('select_companion_warning'),
                      icon: FontAwesomeIcons.envelopeOpenText,
                      combined: false,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Audio Recording Section
            _SectionCard(
              icon: FontAwesomeIcons.microphone,
              title: getText('crafting_recording_title'),
              subtitle: getText('crafting_recording_subtitle'),
              child: Column(
                spacing: 20,
                children: [
                  _ToggleSelector(
                    options: [
                      _ToggleOption(
                        value: CompanionType.ai,
                        label: getText('crafting_option_ai_voice'),
                        icon: FontAwesomeIcons.wind,
                      ),
                      _ToggleOption(
                        value: CompanionType.you,
                        label: getText('crafting_option_you'),
                        icon: FontAwesomeIcons.user,
                      ),
                      _ToggleOption(
                        value: CompanionType.companion,
                        label: getText('crafting_option_companion'),
                        icon: FontAwesomeIcons.userGroup,
                      ),
                    ],
                    selected: audioProvider,
                    onChanged: (value) {
                      setState(() {
                        audioProvider = value;
                      });
                    },
                  ),
                  if (audioProvider == CompanionType.companion)
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        WholeButton(
                          onPressed: () async {
                            final UserProfile? result =
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => PickCompanionBottomSheet(),
                                );
                            setState(() {
                              if (result != null) {
                                audioCompanion = result;
                                audioInvitation = null;
                              }
                            });
                          },
                          icon: audioCompanion != null
                              ? FontAwesomeIcons.person
                              : FontAwesomeIcons.magnifyingGlass,
                          text: audioCompanion != null
                              ? audioCompanion!.username!
                              : getText('find_companion_button'),
                          wide: audioCompanion != null,
                        ),
                        WholeButton(
                          onPressed: () async {
                            final PersonInvitation? result =
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => InvitePersonBottomSheet(),
                                );
                            setState(() {
                              if (result != null) {
                                audioCompanion = null;
                                audioInvitation = result;
                              }
                            });
                          },
                          icon: audioInvitation != null
                              ? FontAwesomeIcons.envelope
                              : FontAwesomeIcons.envelopeCircleCheck,
                          text: audioInvitation != null
                              ? audioInvitation!.name!
                              : getText('invite_friend_button'),
                          wide: audioInvitation != null,
                        ),
                      ],
                    ),
                  // Separate audio message editor
                  if (_needsAudioEditor() && !_needsCombinedEditor())
                    _MessageEditor(
                      controller: _audioMessageController,
                      title: getText('message_editor_audio_title'),
                      subtitle: audioCompanion != null
                          ? getText(
                              'request_user_record_audio',
                            ).replaceFirst('{name}', audioCompanion!.username!)
                          : audioInvitation != null
                          ? getText(
                              'invite_user_record_audio',
                            ).replaceFirst('{name}', audioInvitation!.name!)
                          : getText('select_companion_warning'),
                      icon: FontAwesomeIcons.envelope,
                      combined: false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Combined message editor
            if (_needsCombinedEditor())
              _MessageEditor(
                controller: _combinedMessageController,
                title: getText('message_to_user').replaceFirst(
                  '{name}',
                  textCompanion != null
                      ? textCompanion!.username!
                      : textInvitation!.name!,
                ),
                subtitle: getText('request_both_text_audio').replaceFirst(
                  '{name}',
                  textCompanion != null
                      ? textCompanion!.username!
                      : textInvitation!.name!,
                ),
                icon: FontAwesomeIcons.envelope,
                combined: true,
              ),

            // AI Configuration Section
            if (_hasAnyAIProvider())
              _AIConfigurationCard(
                textProvider: textProvider,
                audioProvider: audioProvider,
              ),

            const SizedBox(height: 32),

            // Summary Card
            _SummaryCard(
              anchorPoint: widget.anchorPoint,
              textProvider: textProvider,
              audioProvider: audioProvider,
              textCompanion: textCompanion,
              audioCompanion: audioCompanion,
              textInvitation: textInvitation,
              audioInvitation: audioInvitation,
              textMessageController: _textMessageController,
              audioMessageController: _audioMessageController,
              combinedMessageController: _combinedMessageController,
              needCombinedText: _needsCombinedEditor(),
              onContinue: () {
                Navigator.of(context).pop(
                  CraftingSelection(
                    textProvider: textProvider,
                    audioProvider: audioProvider,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------- UI Helper Widgets -----------------------------

class _MessageEditor extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool combined;

  const _MessageEditor({
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.combined,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(combined ? 20 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: combined
              ? colorScheme.outlineVariant.withOpacity(0.5)
              : Colors.transparent,
          width: combined ? 1 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  icon,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: getText('enter_message_hint'),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIConfigurationCard extends StatelessWidget {
  final CompanionType textProvider;
  final CompanionType audioProvider;

  const _AIConfigurationCard({
    required this.textProvider,
    required this.audioProvider,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  FontAwesomeIcons.wind,
                  size: 20,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getText('ai_configuration_title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      getText('ai_configuration_subtitle'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (textProvider == CompanionType.ai)
            _AIFeatureRow(
              icon: FontAwesomeIcons.pencil,
              label: getText('ai_text_generation_label'),
              description: getText('ai_text_generation_desc'),
            ),
          if (textProvider == CompanionType.ai &&
              audioProvider == CompanionType.ai)
            const SizedBox(height: 12),
          if (audioProvider == CompanionType.ai)
            _AIFeatureRow(
              icon: FontAwesomeIcons.microphone,
              label: getText('ai_voice_synthesis_label'),
              description: getText('ai_voice_synthesis_desc'),
            ),
        ],
      ),
    );
  }
}

class _AIFeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _AIFeatureRow({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 16, color: colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  icon,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ToggleOption {
  final CompanionType value;
  final String label;
  final IconData icon;

  const _ToggleOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _ToggleSelector extends StatelessWidget {
  final List<_ToggleOption> options;
  final CompanionType selected;
  final ValueChanged<CompanionType> onChanged;

  const _ToggleSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      option.icon,
                      size: 24,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AnchorPoint anchorPoint;
  final CompanionType textProvider;
  final CompanionType audioProvider;
  final PersonInvitation? textInvitation;
  final PersonInvitation? audioInvitation;
  final VoidCallback onContinue;
  final UserProfile? textCompanion;
  final UserProfile? audioCompanion;
  final TextEditingController textMessageController;
  final TextEditingController audioMessageController;
  final TextEditingController combinedMessageController;
  final bool needCombinedText;

  const _SummaryCard({
    required this.anchorPoint,
    required this.textProvider,
    required this.audioProvider,
    required this.onContinue,
    this.audioInvitation,
    this.textInvitation,
    this.textCompanion,
    this.audioCompanion,
    required this.textMessageController,
    required this.audioMessageController,
    required this.combinedMessageController,
    required this.needCombinedText,
  });

  String _getSummaryMessage(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    // You write, you record
    if (textProvider == CompanionType.you &&
        audioProvider == CompanionType.you) {
      return getText('crafting_summary_you_you');
    }
    // You write, companion records
    else if (textProvider == CompanionType.you &&
        audioProvider == CompanionType.companion) {
      return getText('crafting_summary_you_companion');
    }
    // You write, AI records
    else if (textProvider == CompanionType.you &&
        audioProvider == CompanionType.ai) {
      return getText('crafting_summary_you_ai');
    }
    // Companion writes, you record
    else if (textProvider == CompanionType.companion &&
        audioProvider == CompanionType.you) {
      return getText('crafting_summary_companion_you');
    }
    // Companion writes, companion records
    else if (textProvider == CompanionType.companion &&
        audioProvider == CompanionType.companion) {
      return getText('crafting_summary_companion_companion');
    }
    // Companion writes, AI records
    else if (textProvider == CompanionType.companion &&
        audioProvider == CompanionType.ai) {
      return getText('crafting_summary_companion_ai');
    }
    // AI writes, you record
    else if (textProvider == CompanionType.ai &&
        audioProvider == CompanionType.you) {
      return getText('crafting_summary_ai_you');
    }
    // AI writes, companion records
    else if (textProvider == CompanionType.ai &&
        audioProvider == CompanionType.companion) {
      return getText('crafting_summary_ai_companion');
    }
    // AI writes, AI records
    else {
      return getText('crafting_summary_ai_ai');
    }
  }

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    DataProvider appData = context.watch<DataProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              getText('summary_title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _getSummaryMessage(context),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ActionSlider.standard(
              child: Text(getText("save_segments")),
              loadingIcon: CircularProgressIndicator(),
              toggleColor: colorScheme.tertiary,
              rolling: true,
              icon: FaIcon(
                AnchorPointIcons.anchor_point_step2,
                color: colorScheme.onSurface,
                size: 40,
              ),
              successIcon: FaIcon(FontAwesomeIcons.check),
              failureIcon: FaIcon(FontAwesomeIcons.xmark),
              action: (controller) async {
                controller.loading();

                String? textCompanionId = null;
                String? audioCompanionId;

                if (textProvider == CompanionType.companion &&
                    textCompanion != null) {
                  textCompanionId = textCompanion!.id;
                }

                HalfRequestModel textRequest = HalfRequestModel(
                  type: RequestType.text,
                  companionType: textProvider,
                  status: RequestStatus.pending,
                  createdAt: DateTime.now(),
                  message: textMessageController.text ?? null,
                  companionId: textCompanionId,
                  invitationCode: textInvitation != null
                      ? textInvitation!.token
                      : null,
                );

                if (audioProvider == CompanionType.companion &&
                    audioCompanion != null) {
                  audioCompanionId = audioCompanion!.id;
                }

                HalfRequestModel audioRequest = HalfRequestModel(
                  type: RequestType.audio,
                  companionType: audioProvider,
                  status: RequestStatus.created,
                  createdAt: DateTime.now(),
                  message: audioMessageController.text ?? null,
                  companionId: audioCompanionId,
                  invitationCode: audioInvitation != null
                      ? audioInvitation!.token
                      : null,
                );

                try {
                  SupabaseRequestSource().createRequest(
                    anchorPointId: anchorPoint.id,
                    textRequest: textRequest,
                    audioRequest: audioRequest,
                    requestBody: {},
                  );

                  controller.success();

                  await Future.delayed(Durations.extralong1);
                  appData.updateOnlyCurrentAnchorPoint();
                  Navigator.pop(context);
                  appData.changeTabVisibility(true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getText("succes_in_updating_prompts")),
                    ),
                  );
                } catch (e) {
                  controller.failure();
                  await Future.delayed(Durations.extralong1);

                  print(e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
