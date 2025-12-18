import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/screens/crafting_screen.dart';
import 'package:anchor_point_app/presentations/screens/recorder_screen.dart';
import 'package:anchor_point_app/presentations/screens/writing_screen.dart';
import 'package:anchor_point_app/presentations/widgets/global/whole_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequestListTileNotifications extends StatelessWidget {
  final RequestModel request;
  final RequestTileMode mode;
  final String userId; // from Supabase auth
  final VoidCallback? onDelete;

  const RequestListTileNotifications({
    super.key,
    required this.request,
    required this.mode,
    required this.userId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appData = context.watch<DataProvider>();

    final halves = [request.textRequest, request.audioRequest];

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary, width: 1),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            _buildHeader(context),

            ...halves.map(
              (half) => _buildHalfRequest(context, half, colorScheme, appData),
            ),
          ],
        ),
      ),
    );
  }

  // Header
  Widget _buildHeader(BuildContext context) {
    return Center(
      child: mode == RequestTileMode.forRequester
          ? Text('request')
          : Text(
              AppLocalizations.of(context).translate('request_from') +
                  (request.requester != null
                      ? request.requester!.username!
                      : ""),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
    );
  }

  // Half request tile
  Widget _buildHalfRequest(
    BuildContext context,
    HalfRequestModel half,
    ColorScheme colorScheme,
    DataProvider appData,
  ) {
    final canAct = _canActOnHalfRequest(half);
    final isForYou = _isForYou(half);

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHalfHeader(context, half),
              const SizedBox(height: 8),
              if (isForYou)
                if (half.message?.isNotEmpty ?? false)
                  _buildMessage(context, half, colorScheme)
                else
                  _buildDescription(context, half, colorScheme),

              const SizedBox(height: 12),

              if (canAct && isForYou)
                _buildPendingActions(context, half, colorScheme, appData),

              const Divider(height: 24),

              _buildMetadata(context, half, colorScheme),
            ],
          ),
          if (!isForYou)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: BoxBorder.all(color: colorScheme.primary),
                ),
                child: Center(
                  child: Text(
                    'This half of request is for someone else to act.',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Permissions logic
  bool _canActOnHalfRequest(HalfRequestModel half) {
    return half.status == RequestStatus.pending;
  }

  bool _isForYou(HalfRequestModel half) {
    switch (mode) {
      case RequestTileMode.forRequested:
        return half.companionId == userId &&
            half.companionType == CompanionType.companion;

      case RequestTileMode.forRequester:
        return half.companionType == CompanionType.you;
    }
  }

  // UI pieces
  Widget _buildHalfHeader(BuildContext context, HalfRequestModel half) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        WholeButton(icon: half.typeIcon(), suggested: false),
        _buildStatusBadge(context, half),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, HalfRequestModel half) {
    final color = half.getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        AppLocalizations.of(context).translate(half.getStatusLabel()),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context,
    HalfRequestModel half,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 10),
            Icon(FontAwesomeIcons.message, size: 12),
            SizedBox(width: 10),
            Text('request_message'),
          ],
        ),
        SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            border: Border.all(color: colorScheme.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            half.message!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(
    BuildContext context,
    HalfRequestModel half,
    ColorScheme colorScheme,
  ) {
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        half.type == RequestType.text
            ? t.translate('request_description_for_companion_part2_text')
            : t.translate('request_description_for_companion_part2_audio'),
      ),
    );
  }

  Widget _buildPendingActions(
    BuildContext context,
    HalfRequestModel half,
    ColorScheme colorScheme,
    DataProvider appData,
  ) {
    final isText = half.type == RequestType.text;

    return Row(
      children: [
        WholeButton(
          icon: FontAwesomeIcons.xmark,
          text: AppLocalizations.of(
            context,
          ).translate('request_action_decline'),
          circleColor: colorScheme.errorContainer,
          onPressed: () {
            request.changeStatus(RequestStatus.declined, half.type);
          },
        ),
        const SizedBox(width: 12),
        WholeButton(
          wide: true,
          icon: isText ? FontAwesomeIcons.pencil : FontAwesomeIcons.microphone,
          text: isText
              ? AppLocalizations.of(context).translate('request_action_write')
              : AppLocalizations.of(context).translate('request_action_record'),
          onPressed: () {
            appData.changeTabVisibility(false);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isText
                    ? WritingScreen(
                        anchorPointId: request.anchorPointId,
                        request: request,
                      )
                    : AudioRecorderScreen(anchorPointId: request.anchorPointId),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetadata(
    BuildContext context,
    HalfRequestModel half,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          timeago.format(half.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (half.completedAt != null)
          Text(
            timeago.format(half.completedAt!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
