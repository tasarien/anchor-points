import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/anchor_point_model.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/presentations/screens/crafting_screen.dart';
import 'package:anchor_point_app/presentations/screens/recorder_screen.dart';
import 'package:anchor_point_app/presentations/screens/writing_screen.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/request_card_widget.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RequestListTile extends StatelessWidget {
  final RequestModel request;
  final AnchorPoint anchorPoint;
  final String? companionUsername;
  final String? inviteeName;
  final VoidCallback? onTap;

  const RequestListTile({
    Key? key,
    required this.request,
    required this.anchorPoint,
    this.companionUsername,
    this.inviteeName,
    this.onTap,
  }) : super(key: key);

  void handleTap(BuildContext context) async {
    switch (request.requestedFor) {
      case CompanionType.you:
        request.type == 'text'
            ? Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      WritingScreen(anchorPointId: anchorPoint.id),
                ),
              )
            : Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AudioRecorderScreen(anchorPointId: anchorPoint.id),
                ),
              );

        break;
      case CompanionType.companion:
        showRequestDialog(context);
      default:
        break;
    }
  }

  showRequestDialog(BuildContext context) async {
    debugPrint(request.companionUsername.toString());
    await request.getUserName();
    debugPrint(request.companionUsername.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Request details'),
          content: RequestCard(request: request),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  IconData _getTypeIcon() {
    return request.type == 'text'
        ? FontAwesomeIcons.pencil
        : FontAwesomeIcons.microphone;
  }

  IconData _getRequestedForIcon() {
    switch (request.requestedFor) {
      case CompanionType.you:
        return FontAwesomeIcons.user;
      case CompanionType.companion:
        return FontAwesomeIcons.userGroup;
      case CompanionType.ai:
        return FontAwesomeIcons.wind;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  String _getRequestedForLabel() {
    if (request.requestedFor == CompanionType.companion) {
      if (companionUsername != null) {
        return companionUsername!;
      } else if (inviteeName != null) {
        return '$inviteeName (invited)';
      }
      return 'Companion';
    }
    return request.requestedFor.name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = request.type == 'text'
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final onTypeColor = request.type == 'text'
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // Type Icon (Text/Audio)
        leading: WholeButton(
          icon: _getTypeIcon(),
          static: true,
          text: request.type == 'text'
              ? getText('text_request')
              : getText('audio_request'),
        ),

        // Request Details
        title: Row(
          children: [
            // Requested For Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: FaIcon(
                _getRequestedForIcon(),
                size: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            // Requested For Label
            Expanded(
              child: Text(
                _getRequestedForLabel(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: request.getStatusColor().withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: request.getStatusColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            getText(request.getStatusLabel()),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: request.getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),

        // Trailing Arrow
        trailing: FaIcon(
          FontAwesomeIcons.chevronRight,
          size: 16,
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: () => handleTap(context),
      ),
    );
  }
}
