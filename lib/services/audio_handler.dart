import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player;

  void Function()? onSkipToNext;
  void Function()? onSkipToPrevious;

  MusicAudioHandler({AudioPlayer? player}) : player = player ?? AudioPlayer() {
    _setup();
    this.player.playerStateStream.listen(_broadcastState);
    this.player.positionStream.listen((_) => _broadcastState(this.player.playerState));
  }

  Future<void> _setup() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {}
  }

  void _broadcastState(PlayerState state) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[state.processingState]!,
      playing: state.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
    ));
  }

  void setMediaItem(Song song) {
    mediaItem.add(MediaItem(
      id: song.audioUrl,
      title: song.title,
      artist: song.artist,
      artUri: song.imageUrl != null ? Uri.tryParse(song.imageUrl!) : null,
      duration: Duration(seconds: song.duration),
    ));
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }
}
