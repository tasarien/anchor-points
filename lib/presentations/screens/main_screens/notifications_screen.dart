import 'package:anchor_point_app/core/localizations/app_localizations.dart';
import 'package:anchor_point_app/data/models/request_model.dart';
import 'package:anchor_point_app/presentations/providers/data_provider.dart';
import 'package:anchor_point_app/presentations/widgets/ap_request_tile.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/request_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getText(String text) {
      return AppLocalizations.of(context).translate(text);
    }

    DataProvider appData = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(getText('requests'))),
      body: Expanded(
        child: Column(
          children: [
            if (appData.requestsForUser.isEmpty)
              Center(
                child: Text(
                  getText("no_notifications_yet"),
                  style: TextStyle(fontSize: 18),
                ),
              ),
            if (appData.requestsForUser.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: ListView.builder(
                    itemCount: appData.requestsForUser.length,
                    itemBuilder: (context, index) {
                      RequestModel request = appData.requestsForUser[index];
                      return RequestListTileNotifications(
                        request: request,
                        mode: RequestTileMode.forRequested,
                        userId: Supabase.instance.client.auth.currentUser!.id,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
