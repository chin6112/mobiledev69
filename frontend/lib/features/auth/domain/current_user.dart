class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final int? id;
  final String username;
  final String displayName;
}
