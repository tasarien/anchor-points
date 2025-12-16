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
  final RequestType requestType; // Specify which request to display
  final AnchorPoint anchorPoint;
  final String? companionUsername;
  final String? inviteeName;
  final VoidCallback? onTap;

  const RequestListTile({
    Key? key,
    required this.request,
    required this.requestType,
    required this.anchorPoint,
    this.companionUsername,
    this.inviteeName,
    this.onTap,
  }) : super(key: key);

  HalfRequestModel get _halfRequest => requestType == RequestType.text
      ? request.textRequest
      : request.audioRequest;

  void handleTap(BuildContext context) async {
    switch (_halfRequest.companionType) {
      case CompanionType.you:
        requestType == RequestType.text
            ? Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WritingScreen(
                    anchorPointId: anchorPoint.id,
                    request: request,
                  ),
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
        break;
      case CompanionType.ai:
        // Handle AI companion case if needed
        break;
      default:
        break;
    }
  }

  showRequestDialog(BuildContext context) async {
    debugPrint(_halfRequest.companionUsername.toString());
    await _halfRequest.getUserName();
    debugPrint(_halfRequest.companionUsername.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Request details'),
          content: RequestCard(request: request, requestType: requestType),
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

  IconData _getRequestedForIcon() {
    switch (_halfRequest.companionType) {
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
    if (_halfRequest.companionType == CompanionType.companion) {
      if (companionUsername != null) {
        return companionUsername!;
      } else if (inviteeName != null) {
        return '$inviteeName (invited)';
      }
      return 'Companion';
    }
    return _halfRequest.companionType.name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = requestType == RequestType.text
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final onTypeColor = requestType == RequestType.text
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
          icon: _halfRequest.typeIcon(),
          static: true,
          text: requestType == RequestType.text
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _halfRequest.getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _halfRequest.getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  getText(_halfRequest.getStatusLabel()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _halfRequest.getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
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
