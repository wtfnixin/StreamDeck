import 'dart:convert';
import 'package:equatable/equatable.dart';

class WorkspaceActionModel extends Equatable {
  final String id;
  final String workspaceId;
  final String actionType; // 'launch_app', 'launch_website', 'run_command'
  final Map<String, dynamic> payload;
  final int sequenceOrder;

  const WorkspaceActionModel({
    required this.id,
    required this.workspaceId,
    required this.actionType,
    required this.payload,
    required this.sequenceOrder,
  });

  factory WorkspaceActionModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> payloadMap = {};
    final rawPayload = json['payload'];
    if (rawPayload is String) {
      try {
        payloadMap = Map<String, dynamic>.from(jsonDecode(rawPayload) as Map);
      } catch (_) {}
    } else if (rawPayload is Map) {
      payloadMap = Map<String, dynamic>.from(rawPayload);
    }
    return WorkspaceActionModel(
      id: json['id'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? json['workspace_id'] as String? ?? '',
      actionType: json['actionType'] as String? ?? json['action_type'] as String? ?? '',
      payload: payloadMap,
      sequenceOrder: json['sequenceOrder'] as int? ?? json['sequence_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'actionType': actionType,
      'payload': payload,
      'sequenceOrder': sequenceOrder,
    };
  }

  @override
  List<Object?> get props => [id, workspaceId, actionType, payload, sequenceOrder];
}

class WorkspaceModel extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String? description;
  final List<WorkspaceActionModel> actions;

  const WorkspaceModel({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    required this.actions,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    final actionsList = (json['actions'] as List? ?? [])
        .map((item) => WorkspaceActionModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return WorkspaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      actions: actionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, icon, description, actions];
}
