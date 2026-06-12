import "package:dio/dio.dart";

String extractApiError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data["error"];
      if (err is Map<String, dynamic>) {
        return (err["message"] ?? err["code"] ?? "Erro desconhecido").toString();
      }
      final msg = data["message"];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    final code = e.response?.statusCode;
    if (code != null) return "Erro HTTP $code";
    return "Sem conexão [${e.type.name}]";
  }
  return "Erro inesperado: ${e.runtimeType}";
}

class Organization {
  const Organization({required this.id, required this.name, this.role = "member"});
  factory Organization.fromJson(Map<String, dynamic> j) => Organization(
        id: j["id"] as String,
        name: j["name"] as String,
        role: j["role"] as String? ?? "member",
      );
  final String id;
  final String name;
  // Current user's membership role in this org: owner | admin | member.
  final String role;

  bool get canEditMap => role == "owner" || role == "admin";
}

class Workspace {
  const Workspace({required this.id, required this.name});
  factory Workspace.fromJson(Map<String, dynamic> j) =>
      Workspace(id: j["id"] as String, name: j["name"] as String);
  final String id;
  final String name;
}

class OrgWithWorkspace {
  const OrgWithWorkspace({required this.organization, required this.workspace});
  final Organization organization;
  final Workspace workspace;
}

class WorkspaceMapData {
  const WorkspaceMapData({
    required this.id,
    required this.width,
    required this.height,
    required this.tileSize,
    required this.assetPackId,
    required this.spawn,
    required this.layers,
    required this.interactiveZones,
  });

  factory WorkspaceMapData.fromJson(Map<String, dynamic> j) => WorkspaceMapData(
        id: j["id"] as String,
        width: j["width"] as int,
        height: j["height"] as int,
        tileSize: j["tileSize"] as int,
        assetPackId: j["assetPackId"] as String? ?? "office-default-v1",
        spawn: j["spawn"] as Map<String, dynamic>? ??
            {"x": 1, "y": 1, "direction": "front"},
        layers: (j["layers"] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .toList() ??
            [],
        interactiveZones: (j["interactiveZones"] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .toList() ??
            [],
      );

  final String id;
  final int width;
  final int height;
  final int tileSize;
  final String assetPackId;
  final Map<String, dynamic> spawn;
  final List<Map<String, dynamic>> layers;
  final List<Map<String, dynamic>> interactiveZones;

  Map<String, dynamic> toSaveJson() => {
        "width": width,
        "height": height,
        "tileSize": tileSize,
        "assetPackId": assetPackId,
        "spawn": spawn,
        "layers": layers,
        "collision": [],
        "interactiveZones": interactiveZones,
      };
}

class WorkspaceService {
  WorkspaceService(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: "http://localhost:3000",
          headers: {"Authorization": "Bearer $token"},
        ));

  final Dio _dio;

  Future<List<Organization>> listOrganizations() async {
    final res = await _dio.get<Map<String, dynamic>>("/organizations");
    final list = res.data!["organizations"] as List;
    return list.map((e) => Organization.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrgWithWorkspace> createOrganization(String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      "/organizations",
      data: {"name": name},
    );
    final data = res.data!;
    return OrgWithWorkspace(
      organization: Organization.fromJson(data["organization"] as Map<String, dynamic>),
      workspace: Workspace.fromJson(data["workspace"] as Map<String, dynamic>),
    );
  }

  Future<List<Workspace>> listWorkspaces(String organizationId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      "/organizations/$organizationId/workspaces",
    );
    final list = res.data!["workspaces"] as List;
    return list.map((e) => Workspace.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Workspace> createWorkspace(String orgId, String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      "/organizations/$orgId/workspaces",
      data: {"name": name},
    );
    return Workspace.fromJson(res.data!["workspace"] as Map<String, dynamic>);
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    await _dio.delete<void>("/workspaces/$workspaceId");
  }

  Future<WorkspaceMapData> fetchMap(String workspaceId) async {
    final res = await _dio.get<Map<String, dynamic>>("/workspaces/$workspaceId/map");
    return WorkspaceMapData.fromJson(res.data!);
  }

  Future<void> saveMap(String workspaceId, WorkspaceMapData mapData) async {
    await _dio.put<dynamic>(
      "/workspaces/$workspaceId/map",
      data: mapData.toSaveJson(),
    );
  }
}
