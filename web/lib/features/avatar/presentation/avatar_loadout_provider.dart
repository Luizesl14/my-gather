import "package:flutter_riverpod/flutter_riverpod.dart";

import "../domain/avatar_loadout.dart";

/// Loadout do avatar customizado da sessão; null quando o usuário
/// está usando um personagem preset.
final avatarLoadoutProvider = StateProvider<AvatarLoadout?>((ref) => null);