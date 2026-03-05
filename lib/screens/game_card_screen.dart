import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/database_service.dart';

class GameCardScreen extends StatefulWidget {
  final int gameId;

  const GameCardScreen({super.key, required this.gameId});

  @override
  State<GameCardScreen> createState() => _GameCardScreenState();
}

class _GameCardScreenState extends State<GameCardScreen> {
  late Future<Game?> _gameFuture;

  @override
  void initState() {
    super.initState();
    _gameFuture = DatabaseService.instance.getGame(widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Game?>(
        future: _gameFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }
          final game = snapshot.data;
          if (game == null) {
            return _notFoundState();
          }

          return _buildContent(context, game);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Game game) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Text(game.title, style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                _statusChip(game.status),
              ],
            ),
            const SizedBox(height: 24),
            Text(game.system ?? 'Unknown system'),
            const SizedBox(height: 8),
            Text(
              'Last played: ${game.lastPlayed?.toLocal().toString().split(' ').first ?? 'Never'}',
            ),
            const SizedBox(height: 8),
            Text('Play time: ${game.playTimeMinutes} min'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton('Launch', Icons.play_arrow, _mockLaunch),
                _actionButton('Status', Icons.check_circle, () {}),
                _actionButton('Notes', Icons.note, () {}),
                _actionButton('Guides', Icons.book, () {}),
                _actionButton('Achievements', Icons.emoji_events, () {}),
                _actionButton('Collections', Icons.collections_bookmark, () {}),
              ],
            ),
            const SizedBox(height: 24),
            _mockPanel('Notes', '3 notes'),
            const SizedBox(height: 12),
            _mockPanel('Guides', '2 guides'),
            const SizedBox(height: 12),
            _mockPanel('Achievements', '15/40 unlocked'),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(GameStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.displayName),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _mockPanel(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _notFoundState() {
    return const Center(child: Text('Game not found'));
  }

  Widget _errorState(String message) {
    return Center(child: Text('Error: $message'));
  }

  void _mockLaunch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Launching game (mock)...')),
    );
  }
}
