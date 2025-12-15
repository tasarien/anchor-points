import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/recorder_screen.dart';
import 'package:anchor_point_app/presentations/screens/writing_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequestListTileNotifications extends StatelessWidget {
  final RequestModel request;
  final VoidCallback? onView;
  final VoidCallback? onDelete;
  final bool showActions;

  const RequestListTileNotifications({
    Key? key,
    required this.request,
    this.onView,
    this.onDelete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appData = context.watch<DataProvider>();

    String getText(BuildContext context, String key) {
      return AppLocalizations.of(context).translate(key);
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              _buildHeaderRow(context, colorScheme),

              if (showActions) ...[
                request.message?.isNotEmpty ?? false
                    ? _buildMessageSection(context, colorScheme)
                    : _buildDescriptionBox(context, colorScheme),
                if (request.status == RequestStatus.completed && onView != null)
                  _buildViewButton(context, colorScheme),
                if (request.status == RequestStatus.declined &&
                    onDelete != null)
                  _buildDeleteButton(context, colorScheme),
                if (request.status == RequestStatus.pending)
                  _buildPendingActions(context, colorScheme, appData),
                if (request.status == RequestStatus.created)
                  _buildCreatedInfo(context, colorScheme),
                Divider(),
                _buildMetadataRow(context, colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Header Row - combines avatar, username, type button, and status
  Widget _buildHeaderRow(BuildContext context, ColorScheme colorScheme) {
    return Column(
      spacing: 10,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [WholeButton(icon: _getTypeIcon(), suggested: false)],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Text(
              getText(context, 'request_from'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            Text(
              request.companionUsername ?? "Someone",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ],
    );
  }

  String getText(BuildContext context, String key) {
    return AppLocalizations.of(context).translate(key);
  }

  Widget _buildStatusBadge(BuildContext context, ColorScheme colorScheme) {
    final statusColor = request.getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        getText(context, request.getStatusLabel()),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Description Box
  Widget _buildDescriptionBox(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.circleInfo,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getDescriptionText(context),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Created info box
  Widget _buildCreatedInfo(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(
            FontAwesomeIcons.circleInfo,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              getText(context, 'created_info'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Pending Actions Section
  Widget _buildPendingActions(
    BuildContext context,
    ColorScheme colorScheme,
    DataProvider appData,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        WholeButton(
          onPressed: () => _handleDecline(),
          icon: FontAwesomeIcons.xmark,
          text: getText(context, 'request_action_decline'),
          circleColor: colorScheme.errorContainer,
        ),
        WholeButton(
          onPressed: () => _handleAccept(context, appData),
          icon: request.type == 'text'
              ? FontAwesomeIcons.pencil
              : FontAwesomeIcons.microphone,
          text: request.type == 'text'
              ? getText(context, 'request_action_write')
              : getText(context, 'request_action_record'),
          wide: true,
        ),
      ],
    );
  }

  // Message Section
  Widget _buildMessageSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.message,
              size: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              getText(context, 'request_message_label'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            request.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Metadata Row
  Widget _buildMetadataRow(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimestamp(context, colorScheme, request.createdAt),
        if (request.completedAt != null) ...[
          _buildDivider(colorScheme),
          _buildCompletedTimestamp(context, colorScheme),
        ],
        _buildStatusBadge(context, colorScheme),
      ],
    );
  }

  Widget _buildTimestamp(
    BuildContext context,
    ColorScheme colorScheme,
    DateTime timestamp,
  ) {
    return Row(
      spacing: 6,
      children: [
        FaIcon(
          FontAwesomeIcons.clock,
          size: 12,
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        Text(
          timeago.format(timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildCompletedTimestamp(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Row(
      spacing: 6,
      children: [
        const FaIcon(
          FontAwesomeIcons.circleCheck,
          size: 12,
          color: Colors.green,
        ),
        Text(
          '${getText(context, 'request_completed_at')} ${timeago.format(request.completedAt!)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Action Buttons
  Widget _buildViewButton(BuildContext context, ColorScheme colorScheme) {
    return _buildActionButton(
      context: context,
      colorScheme: colorScheme,
      onPressed: onView!,
      icon: FontAwesomeIcons.eye,
      label: getText(context, 'request_action_view'),
      isFilledButton: true,
    );
  }

  Widget _buildDeleteButton(BuildContext context, ColorScheme colorScheme) {
    return _buildActionButton(
      context: context,
      colorScheme: colorScheme,
      onPressed: onDelete!,
      icon: FontAwesomeIcons.trash,
      label: getText(context, 'request_action_delete'),
      isFilledButton: false,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isFilledButton,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: isFilledButton
            ? FilledButton.icon(
                onPressed: onPressed,
                icon: FaIcon(icon, size: 16),
                label: Text(label),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: FaIcon(icon, size: 16),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(
                    color: colorScheme.error.withOpacity(0.5),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ),
    );
  }

  // Helper Methods
  IconData _getTypeIcon() {
    return switch (request.type) {
      'text' => FontAwesomeIcons.pencil,
      'audio' => FontAwesomeIcons.microphone,
      _ => FontAwesomeIcons.question,
    };
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    return switch (request.status) {
      'pending' => colorScheme.tertiary,
      'completed' => Colors.green,
      'declined' => colorScheme.error,
      _ => colorScheme.onSurface.withOpacity(0.6),
    };
  }

  String _getTypeLabel(BuildContext context) {
    return request.type == 'text'
        ? getText(context, 'text_request')
        : getText(context, 'audio_request');
  }

  String _getDescriptionText(BuildContext context) {
    final part1 = getText(context, 'request_description_for_companion_part1');
    final part2 = request.type == 'text'
        ? getText(context, 'request_description_for_companion_part2_text')
        : getText(context, 'request_description_for_companion_part2_audio');
    return '$part1$part2';
  }

  void _handleDecline() {
    // TODO: Implement decline logic
  }

  void _handleAccept(BuildContext context, DataProvider appData) {
    appData.changeTabVisibility(false);

    final screen = request.type == 'text'
        ? WritingScreen(anchorPointId: request.anchorPointId)
        : AudioRecorderScreen(anchorPointId: request.anchorPointId);

    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
