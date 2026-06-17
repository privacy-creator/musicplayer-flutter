import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/player_service.dart';
import '../services/streaming_service.dart';
import '../models/stream_room.dart';

class ListeningRoomScreen extends StatelessWidget {
  const ListeningRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final streaming = context.watch<StreamingService>();
    return streaming.inRoom
        ? _RoomView(room: streaming.room!, streaming: streaming)
        : const _LobbyView();
  }
}

// ── Lobby ─────────────────────────────────────────────────────────────────────

class _LobbyView extends StatelessWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.liveListening)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined,
                size: 72,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.6)),
            const SizedBox(height: 24),
            _LobbyCard(
              icon: Icons.broadcast_on_personal,
              label: l10n.createRoom,
              onTap: () =>
                  Navigator.push(context, _route(const _CreateRoomSheet())),
            ),
            const SizedBox(height: 12),
            _LobbyCard(
              icon: Icons.group_add_outlined,
              label: l10n.joinRoom,
              onTap: () =>
                  Navigator.push(context, _route(const _JoinRoomSheet())),
            ),
          ],
        ),
      ),
    );
  }

  MaterialPageRoute<void> _route(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}

class _LobbyCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LobbyCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ── Create room sheet ─────────────────────────────────────────────────────────

class _CreateRoomSheet extends StatefulWidget {
  const _CreateRoomSheet();

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final player = context.watch<PlayerService>();
    final song = player.currentSong;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createRoom)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (song != null)
              ListTile(
                leading:
                    const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                title: Text(song.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist),
                contentPadding: EdgeInsets.zero,
              )
            else
              Text(l10n.noSongPlaying,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            FilledButton(
              onPressed: _loading ? null : _start,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.createRoom),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final player = context.read<PlayerService>();
    final streaming = context.read<StreamingService>();
    try {
      await streaming.createRoom(
        trackId: player.currentSong?.id,
        position: player.position.inMilliseconds / 1000.0,
        isPlaying: player.isPlaying,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }
}

// ── Join room sheet ───────────────────────────────────────────────────────────

class _JoinRoomSheet extends StatefulWidget {
  const _JoinRoomSheet();

  @override
  State<_JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<_JoinRoomSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final streaming = context.watch<StreamingService>();
    if (streaming.error != null) {
      _error = streaming.error;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinRoom)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: l10n.roomCode,
                hintText: l10n.enterRoomCode,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            FilledButton(
              onPressed: _loading ? null : _join,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.joinRoom),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    final code = _ctrl.text.trim();
    if (code.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<StreamingService>().joinRoom(code);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }
}

// ── Room view ─────────────────────────────────────────────────────────────────

class _RoomView extends StatelessWidget {
  final StreamRoom room;
  final StreamingService streaming;

  const _RoomView({required this.room, required this.streaming});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final player = context.watch<PlayerService>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LiveBadge(),
            const SizedBox(width: 8),
            Text(l10n.liveListening),
          ],
        ),
        actions: [
          if (streaming.isHost)
            TextButton(
              onPressed: () => _confirmEnd(context),
              child: Text(l10n.endRoom,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            )
          else
            TextButton(
              onPressed: () => streaming.leaveRoom(),
              child: Text(l10n.leaveRoom),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Room code card
          _RoomCodeCard(roomCode: room.roomCode),
          const SizedBox(height: 16),

          // Now playing
          _NowPlayingCard(room: room, player: player),
          const SizedBox(height: 16),

          // Host controls
          if (streaming.isHost)
            _HostControlsCard(room: room, player: player, streaming: streaming),

          // Participants
          _ParticipantsCard(
              room: room, streaming: streaming, currentUserId: null),
        ],
      ),
    );
  }

  void _confirmEnd(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.endRoom),
        content: Text(l10n.endRoomConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              streaming.endRoom();
            },
            child: Text(l10n.endRoom),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('LIVE',
          style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  final String roomCode;

  const _RoomCodeCard({required this.roomCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.inviteCode,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(
                    roomCode,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: l10n.inviteCode,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: roomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.roomCodeCopied)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final StreamRoom room;
  final PlayerService player;

  const _NowPlayingCard({required this.room, required this.player});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final song = player.currentSong;

    final title = song != null && song.id == room.currentTrackId
        ? song.title
        : l10n.noSongPlaying;
    final artist = song != null && song.id == room.currentTrackId
        ? song.artist
        : '';

    return Card(
      child: ListTile(
        leading: Icon(Icons.music_note,
            color: Theme.of(context).colorScheme.primary, size: 32),
        title: Text(l10n.nowPlayingLabel,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (artist.isNotEmpty) Text(artist, maxLines: 1),
          ],
        ),
        isThreeLine: artist.isNotEmpty,
      ),
    );
  }
}

class _HostControlsCard extends StatelessWidget {
  final StreamRoom room;
  final PlayerService player;
  final StreamingService streaming;

  const _HostControlsCard(
      {required this.room, required this.player, required this.streaming});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hostControls,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () async {
                    await player.playPrevious();
                    _pushSync(streaming, player);
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 48,
                  icon: Icon(player.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () async {
                    await player.togglePlayPause();
                    _pushSync(streaming, player);
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next),
                  onPressed: () async {
                    await player.playNext();
                    _pushSync(streaming, player);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.sync, size: 16),
                label: Text(l10n.syncNow),
                onPressed: () => _pushSync(streaming, player),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pushSync(StreamingService streaming, PlayerService player) {
    streaming.updateState(
      trackId: player.currentSong?.id,
      position: player.position.inMilliseconds / 1000.0,
      isPlaying: player.isPlaying,
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  final StreamRoom room;
  final StreamingService streaming;
  final int? currentUserId;

  const _ParticipantsCard(
      {required this.room,
      required this.streaming,
      required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final participants = room.participants;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.participants} (${participants.length})',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            if (participants.isEmpty)
              Text(l10n.noParticipants,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))
            else
              for (final p in participants)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text(p.email.isNotEmpty
                        ? p.email[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(p.email,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: p.id == room.hostId
                      ? Chip(
                          label: Text(l10n.host,
                              style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )
                      : (streaming.isHost
                          ? IconButton(
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              tooltip: l10n.transferHost,
                              onPressed: () => streaming.transferHost(p.id),
                            )
                          : null),
                ),
          ],
        ),
      ),
    );
  }
}
