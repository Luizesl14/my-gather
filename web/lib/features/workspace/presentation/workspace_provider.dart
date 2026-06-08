import "package:flutter_riverpod/flutter_riverpod.dart";

final workspaceIdProvider = StateProvider<String>((ref) => "office-default");
final orgIdProvider = StateProvider<String>((ref) => "");
