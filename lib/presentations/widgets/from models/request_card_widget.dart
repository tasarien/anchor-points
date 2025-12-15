import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class RequestCard extends StatelessWidget {
  final RequestModel request;

  const RequestCard({super.key, required this.request});

  IconData _typeIcon(String type) {
    return type == 'audio'
        ? FontAwesomeIcons.microphone
        : FontAwesomeIcons.pencil;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String getText(text) {
      return AppLocalizations.of(context).translate(text);
    }

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
        spacing: 15,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WholeButton(
                static: true,
                icon: _typeIcon(request.type),
                text: request.type,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: request.getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  getText(request.getStatusLabel()),
                  style: TextStyle(
                    color: request.getStatusColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            children: [
              Text("You have requested "),
              Text(request.companionUsername ?? "a companion"),
              Text(" to prepare "),
              Text(request.type == 'text' ? 'text' : 'audio'),
              Text(" for this Anchor Point."),
            ],
          ),

          // Info rows
          if (request.companionId != null)
            _infoRow(
              context: context,
              icon: FontAwesomeIcons.user,
              label: "Companion",
              value: request.companionUsername!,
            ),

          if (request.invitationCode != null)
            _infoRow(
              context: context,
              icon: FontAwesomeIcons.key,
              label: "Invitation Code",
              value: request.invitationCode!,
            ),

          _infoRow(
            context: context,
            icon: FontAwesomeIcons.clock,
            label: "Created",
            value: DateFormat('yyyy-MM-dd – HH:mm').format(request.createdAt),
          ),

          if (request.completedAt != null)
            _infoRow(
              context: context,
              icon: FontAwesomeIcons.check,
              label: "Completed",
              value: DateFormat('yyyy-MM-dd').format(request.completedAt!),
            ),
          // Message
          if (request.message != null)
            Column(
              children: [
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.message),
                    Text("Your message for invited person: "),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.secondary),
                    ),
                    child: Text(
                      request.message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          FaIcon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
