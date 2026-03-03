/// Represents a game discovered during directory scan (not yet in database)
class DiscoveredGame {
  final String title;
  final String executablePath;
  final String system;

  DiscoveredGame({
    required this.title,
    required this.executablePath,
    required this.system,
  });
}
