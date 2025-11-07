import 'package:action_slider/action_slider.dart';
import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/person_invitation.dart';
import 'package:anchor_point_app/data/models/user_profile.dart';
import 'package:anchor_point_app/presentations/widgets/drawers/companion_picker.dart';
import 'package:anchor_point_app/presentations/widgets/drawers/invite_person.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum CompanionType { you, companion, ai }

class CraftingSelection {
  final CompanionType textProvider;
  final CompanionType audioProvider;

  CraftingSelection({required this.textProvider, required this.audioProvider});
}

class CraftingScreen extends StatefulWidget {
  const CraftingScreen({Key? key}) : super(key: key);

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

  bool _hasTextPickedCompanionOrInvited() {
    return textCompanion != null || textInvitation != null;
  }

  bool _hasAudioPickedCompanionOrInvited() {
    return audioCompanion != null || audioInvitation != null;
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

    return Scaffold(
      appBar: AppBar(title: Text(getText('crafting_sheet_title'))),
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
                  SizedBox(height: 10),
                  if (textProvider == CompanionType.companion)
                    Row(
                      children: [
                        WholeButton(
                          onPressed: () async {
                            final UserProfile? result = await showModalBottomSheet(
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
                              if(result != null) {
                              textCompanion = result;
                              textInvitation = null;
                              }
                            });
                          },
                          wide: true,
                          icon: textCompanion != null
                              ? FontAwesomeIcons.person
                              : FontAwesomeIcons.magnifyingGlass,
                          text: textCompanion != null
                              ? textCompanion!.username!
                              : "Find companion",
                        ),
                        WholeButton(
                          onPressed: () async {
                            final PersonInvitation? result = await showModalBottomSheet(
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
                              if(result != null) {
                              textCompanion = null;
                              textInvitation = result;
                              }

                            });
                          },
                          wide: true,
                          icon: textInvitation != null
                              ? FontAwesomeIcons.envelope
                              : FontAwesomeIcons.envelopeCircleCheck,
                          text: textInvitation != null
                              ? textInvitation!.name!
                              : "Invite a friend",
                        ),
                      ],
                    ),
                  SizedBox(height: 10),
                  // Separate text message editor (when text companion is different or audio is not companion)
                  if (_needsTextEditor() && !_needsCombinedEditor())
                    _MessageEditor(
                      controller: _textMessageController,
                      title: 'Message for text writing',
                      subtitle: textCompanion != null
                          ? 'Request ${textCompanion!.username} to write the text'
                          : textInvitation != null ? 'Invite ${textInvitation!.name} to write the text' : 'Select a companion first, or invite someone new',
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
                  SizedBox(height: 10),
                  if (audioProvider == CompanionType.companion)
                    Row(
                      children: [
                        WholeButton(
                          onPressed: () async {
                            final UserProfile? result = await showModalBottomSheet(
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
                              if(result != null) {
                              audioCompanion = result;
                              audioInvitation = null;
                              }
                            });
                          },
                          wide: true,
                          icon: audioCompanion != null
                              ? FontAwesomeIcons.person
                              : FontAwesomeIcons.magnifyingGlass,
                          text: audioCompanion != null
                              ? audioCompanion!.username!
                              : "Find companion",
                        ),
                        WholeButton(
                          onPressed: () async {
                            final PersonInvitation? result = await showModalBottomSheet(
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
                              if(result != null) {
                              audioCompanion = null;
                              audioInvitation = result;
                              }

                            });
                          },
                          wide: true,
                          icon: audioInvitation != null
                              ? FontAwesomeIcons.envelope
                              : FontAwesomeIcons.envelopeCircleCheck,
                          text: audioInvitation != null
                              ? audioInvitation!.name!
                              : "Invite a friend",
                        ),
                      ],
                    ),
                  SizedBox(height: 10),
                  // Separate audio message editor (when audio companion is different or text is not companion)
                  if (_needsAudioEditor() && !_needsCombinedEditor())
                    _MessageEditor(
                      controller: _audioMessageController,
                      title: 'Message for audio recording',
                      subtitle: audioCompanion != null
                          ? 'Request ${audioCompanion!.username} to record the audio'
                          : audioInvitation != null ? 'Invite ${audioInvitation!.name} to record the audio'
                          : 'Select a companion first, or invite someone new',
                      icon: FontAwesomeIcons.envelope,
                      combined: false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Combined message editor (when both companions are the same)
            if (_needsCombinedEditor())
              _MessageEditor(
                controller: _combinedMessageController,
                title: 'Message to ${textCompanion != null ? textCompanion!.username : textInvitation!.name}',
                subtitle:
                
                    'This message will request both text and audio from ${textCompanion != null ? textCompanion!.username : textInvitation!.name}',
                icon: FontAwesomeIcons.envelope,
                combined: true,
              ),

            // AI Configuration Section (when any provider is AI)
            if (_hasAnyAIProvider())
              _AIConfigurationCard(
                textProvider: textProvider,
                audioProvider: audioProvider,
              ),

            const SizedBox(height: 32),

            // Summary Card with Continue Button
            _SummaryCard(
              textProvider: textProvider,
              audioProvider: audioProvider,
              textCompanion: textCompanion,
              audioCompanion: audioCompanion,
              textMessageController: _textMessageController,
              audioMessageController: _audioMessageController,
              combinedMessageController: _combinedMessageController,
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
              hintText: 'Enter your message...',
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
                      'AI Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'AI will generate content automatically',
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
              label: 'AI Text Generation',
              description: 'Text will be generated automatically',
            ),
          if (textProvider == CompanionType.ai &&
              audioProvider == CompanionType.ai)
            const SizedBox(height: 12),
          if (audioProvider == CompanionType.ai)
            _AIFeatureRow(
              icon: FontAwesomeIcons.microphone,
              label: 'AI Voice Synthesis',
              description: 'Audio will be synthesized automatically',
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
  final CompanionType textProvider;
  final CompanionType audioProvider;
  final VoidCallback onContinue;
  final UserProfile? textCompanion;
  final UserProfile? audioCompanion;
  final TextEditingController textMessageController;
  final TextEditingController audioMessageController;
  final TextEditingController combinedMessageController;

  const _SummaryCard({
    required this.textProvider,
    required this.audioProvider,
    required this.onContinue,
    this.textCompanion,
    this.audioCompanion,
    required this.textMessageController,
    required this.audioMessageController,
    required this.combinedMessageController,
  });

  String _getProviderLabel(BuildContext context, CompanionType type) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    switch (type) {
      case CompanionType.you:
        return getText('crafting_option_you');
      case CompanionType.companion:
        return getText('crafting_option_companion');
      case CompanionType.ai:
        return getText('crafting_option_ai');
    }
  }

  IconData _getProviderIcon(CompanionType type) {
    switch (type) {
      case CompanionType.you:
        return FontAwesomeIcons.user;
      case CompanionType.companion:
        return FontAwesomeIcons.userGroup;
      case CompanionType.ai:
        return FontAwesomeIcons.wind;
    }
  }

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
    else if (textProvider == CompanionType.ai &&
        audioProvider == CompanionType.ai) {
      return getText('crafting_summary_ai_ai');
    }

    return getText('crafting_summary_balanced');
  }

  bool _isSameCompanion() {
    return textProvider == CompanionType.companion &&
        audioProvider == CompanionType.companion &&
        textCompanion != null &&
        audioCompanion != null &&
        textCompanion!.id == audioCompanion!.id;
  }

  Future<void> sendRequest() async {
    // Add your API call here with the message controllers
    // You can access:
    // - combinedMessageController.text (when same companion for both)
    // - textMessageController.text (for text companion message)
    // - audioMessageController.text (for audio companion message)
  }

  void _checkRequestValidity(
    ActionSliderController controller,
    BuildContext context,
  ) async {
    final getText = (String key) => AppLocalizations.of(context).translate(key);

    // Check for missing text companion
    if (textProvider == CompanionType.companion && textCompanion == null) {
      controller.failure();
      await Future.delayed(Durations.long4);
      controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText('please_select_text_companion')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check for missing audio companion
    if (audioProvider == CompanionType.companion && audioCompanion == null) {
      controller.failure();
      await Future.delayed(Durations.long4);
      controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText('please_select_audio_companion')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check for empty message when companion is selected
    if (_isSameCompanion() && combinedMessageController.text.trim().isEmpty) {
      controller.failure();
      await Future.delayed(Durations.long4);
      controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a message for ${textCompanion!.username}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (textProvider == CompanionType.companion &&
        !_isSameCompanion() &&
        textMessageController.text.trim().isEmpty) {
      controller.failure();
      await Future.delayed(Durations.long4);
      controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a message for text companion'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (audioProvider == CompanionType.companion &&
        !_isSameCompanion() &&
        audioMessageController.text.trim().isEmpty) {
      controller.failure();
      await Future.delayed(Durations.long4);
      controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a message for audio companion'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If valid → success message
    try {
      await sendRequest();
      controller.success();
      await Future.delayed(Durations.long4);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getText('request_sent_successfully')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      controller.failure();
      await Future.delayed(Durations.long4);
      controller.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.lightbulb,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                getText('crafting_summary_title'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryItem(
                icon: FontAwesomeIcons.pencil,
                label: getText('crafting_writing_title'),
                provider: _getProviderLabel(context, textProvider),
                providerIcon: _getProviderIcon(textProvider),
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 30,
                color: colorScheme.outline.withOpacity(0.3),
              ),
              const SizedBox(width: 16),
              _SummaryItem(
                icon: FontAwesomeIcons.microphone,
                label: getText('crafting_recording_title'),
                provider: _getProviderLabel(context, audioProvider),
                providerIcon: _getProviderIcon(audioProvider),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getSummaryMessage(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ActionSlider.standard(
              child: Text(getText("make_request")),
              loadingIcon: CircularProgressIndicator(),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              toggleColor: colorScheme.tertiary,
              icon: FaIcon(
                FontAwesomeIcons.seedling,
                color: colorScheme.onSurface,
                size: 25,
              ),
              successIcon: FaIcon(FontAwesomeIcons.check),
              failureIcon: FaIcon(FontAwesomeIcons.xmark),
              action: (controller) async {
                controller.loading();
                await Future.delayed(Duration(seconds: 1));
                _checkRequestValidity(controller, context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String provider;
  final IconData providerIcon;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.provider,
    required this.providerIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Row(
        children: [
          FaIcon(icon, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                Row(
                  children: [
                    FaIcon(
                      providerIcon,
                      size: 12,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        provider,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
