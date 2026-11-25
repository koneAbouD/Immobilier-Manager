/// État de l'authentification — sealed class pour exhaustivité des switch.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  /// Prénom à présenter (vide si inconnu), jamais l'identifiant de connexion :
  /// celui-ci est un numéro de téléphone.
  final String displayName;
  const AuthAuthenticated(this.displayName);
}

/// Session ouverte mais mise sous clé : les jetons ne sont plus disponibles en
/// clair, seul le code d'accès (ou la biométrie) peut les ressortir du coffre
/// chiffré.
///
/// Distinct de [AuthUnauthenticated] : l'utilisateur n'a pas à ressaisir ses
/// identifiants, cinq chiffres — ou un doigt — suffisent.
class AuthLocked extends AuthState {
  /// Prénom à afficher (`null` si inconnu : l'écran salue sans nommer).
  final String? displayName;

  /// Motif du verrouillage, à présenter discrètement.
  final String? message;

  const AuthLocked({this.displayName, this.message});
}

/// Connexion réussie, code d'accès à choisir avant d'entrer dans l'application.
class AuthPinSetup extends AuthState {
  final String? displayName;

  const AuthPinSetup({this.displayName});
}

/// Connexion réussie alors qu'un code existe déjà pour ce compte : on le
/// redemande au lieu d'en faire choisir un nouveau. La saisie re-dérive la clé
/// du coffre, pour y ranger le refresh token tout neuf.
class AuthPinResume extends AuthState {
  final String? displayName;

  const AuthPinResume({this.displayName});
}

class AuthUnauthenticated extends AuthState {
  /// Message optionnel (ex. « Session expirée… ») lors d'une déconnexion subie.
  final String? message;
  const AuthUnauthenticated([this.message]);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
