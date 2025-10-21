import 'package:anchor_point_app/presentations/widgets/from%20models/anchor_point_widget.dart';
import 'package:anchor_point_app/presentations/widgets/from%20models/anchor_point_widget_small.dart';

class AnchorPoint {
  final int id;
  final String ownerId;
  final String? name;
  final String? description;
  final AnchorPointStatus status;
  final String? imageUrl;

  AnchorPoint({
    required this.id,
    required this.ownerId,
    this.name,
    this.description,
    required this.status,
    this.imageUrl,
  });

  factory AnchorPoint.fromJson(Map<String, dynamic> json) {
    return AnchorPoint(
      id: json['id'] as int,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: AnchorPointStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => AnchorPointStatus.created,
      ),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'status': status.name,
      'image_url': imageUrl,
    };
  }

  AnchorPointWidgetSmall buildAPWidgetSmall() {
    return AnchorPointWidgetSmall(anchorPoint: this);
  }
}

enum AnchorPointStatus { created, drafted, crafted, archived }
