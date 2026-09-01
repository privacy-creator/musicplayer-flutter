import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/player_service.dart';
import '../services/streaming_service.dart';
import '../models/chat_message.dart';
import '../models/recent_room.dart';
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

class _LobbyView extends StatefulWidget {
  const _LobbyView();

  @override
  State<_LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<_LobbyView> {
  late Future<List<RecentRoom>> _recentRooms;

  @override
  void initState() {
    super.initState();
    _recentRooms = context.read<StreamingService>().loadRecentRooms();
  }

  Future<void> _rejoin(String code) async {
    try {
      await context.read<StreamingService>().joinRoom(code);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.liveListening)),
      body: Column(
        children: [
          _BetaBanner(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
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
                      onTap: () => Navigator.push(
                          context, _route(const _CreateRoomSheet())),
                    ),
                    const SizedBox(height: 12),
                    _LobbyCard(
                      icon: Icons.group_add_outlined,
                      label: l10n.joinRoom,
                      onTap: () => Navigator.push(
                          context, _route(const _JoinRoomSheet())),
                    ),
                    FutureBuilder<List<RecentRoom>>(
                      future: _recentRooms,
                      builder: (context, snapshot) {
                        final rooms = snapshot.data ?? [];
                        if (rooms.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.recentRooms,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                              const SizedBox(height: 4),
                              for (final r in rooms)
                                Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.history),
                                    title: Text(r.code,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2)),
                                    trailing: TextButton(
                                      onPressed: () => _rejoin(r.code),
                                      child: Text(l10n.rejoin),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  MaterialPageRoute<void> _route(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}

class _BetaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.tertiaryContainer.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 18, color: colors.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Beta — deze functie is in ontwikkeling. '
              'Problemen zijn mogelijk.',
              style: TextStyle(
                  fontSize: 13, color: colors.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = streaming.error ?? 'Onbekende fout';
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
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: l10n.roomChat,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _ChatSheet(),
            ),
          ),
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
            _HostControlsCard(room: room, player: player),

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

  const _HostControlsCard({required this.room, required this.player});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final cs = Theme.of(context).colorScheme;
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
                    color: cs.primary,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: player.playPrevious,
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 48,
                  icon: Icon(player.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle),
                  color: cs.primary,
                  onPressed: player.togglePlayPause,
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next),
                  onPressed: player.playNext,
                ),
              ],
            ),
          ],
        ),
      ),
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
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(p.name.isNotEmpty
                            ? p.name[0].toUpperCase()
                            : '?'),
                      ),
                      if (streaming.isOnline(p.name))
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(p.name,
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

// ── Chat ──────────────────────────────────────────────────────────────────────

class _ChatSheet extends StatefulWidget {
  const _ChatSheet();

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text;
    if (text.trim().isEmpty) return;
    context.read<StreamingService>().sendChatMessage(text);
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final messages = context.watch<StreamingService>().chatMessages;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l10n.roomChat,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('💬'))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) =>
                          _ChatBubble(message: messages[i]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: l10n.chatHint,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: l10n.chatSend,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment:
          message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: message.isMine
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMine)
              Text(message.senderName,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.primary)),
            Text(message.text),
          ],
        ),
      ),
    );
  }
}
