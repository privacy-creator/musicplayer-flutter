// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Music Player';

  @override
  String get navSongs => 'Canciones';

  @override
  String get navPlaylists => 'Listas';

  @override
  String get tooltipRefresh => 'Actualizar';

  @override
  String get tooltipShuffleAll => 'Mezclar todo';

  @override
  String get searchHint => 'Buscar canciones...';

  @override
  String get filterLanguage => 'Idioma';

  @override
  String get filterGenre => 'Género';

  @override
  String get allLanguage => 'Todos los idiomas';

  @override
  String get allGenre => 'Todos los géneros';

  @override
  String get noSongsFound => 'No se encontraron canciones';

  @override
  String get offlineBanner => 'Sin conexión — canciones en caché';

  @override
  String get noInternet => 'Sin conexión a internet';

  @override
  String addedToQueue(String title) {
    return '$title añadida a la cola';
  }

  @override
  String get tooltipDownload => 'Guardar sin conexión';

  @override
  String get tooltipDeleteDownload => 'Eliminar descarga';

  @override
  String get offlineBadge => 'Disponible sin conexión';

  @override
  String get btnAddToQueue => 'Añadir a la cola';

  @override
  String songAdded(String title) {
    return '$title añadida';
  }

  @override
  String get queue => 'Cola';

  @override
  String get lyrics => 'Letra';

  @override
  String get btnPlay => 'Reproducir';

  @override
  String get btnPause => 'Pausar';

  @override
  String get nowPlaying => 'Reproduciendo ahora';

  @override
  String get tooltipQueue => 'Cola';

  @override
  String get clearQueue => 'Vaciar cola';

  @override
  String get emptyQueue => 'No hay canciones en la cola';

  @override
  String get sectionNowPlaying => 'Reproduciendo ahora';

  @override
  String sectionQueue(int count) {
    return 'Cola ($count)';
  }

  @override
  String get sectionUpNext => 'A continuación';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get adminSubtitle => 'Solo para administradores';

  @override
  String get tooltipAdminLogout => 'Cerrar sesión admin';

  @override
  String get tooltipAdminLogin => 'Admin login';

  @override
  String get hintEmail => 'Correo electrónico';

  @override
  String get hintPassword => 'Contraseña';

  @override
  String get btnSignIn => 'Iniciar sesión';

  @override
  String get errorFillAll => 'Por favor complete todos los campos';

  @override
  String get mfaTotp => 'Ingresa tu código de autenticación';

  @override
  String get mfaEmail => 'Ingresa el código enviado a tu correo';

  @override
  String get hint6digit => 'Código de 6 dígitos';

  @override
  String get btnVerify => 'Verificar';

  @override
  String get backToLogin => '← Volver al inicio de sesión';

  @override
  String get noPlaylists => 'Aún no hay listas';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
    );
    return '$_temp0';
  }

  @override
  String get tooltipPlayAll => 'Reproducir todo';

  @override
  String get tooltipShuffle => 'Mezclar';

  @override
  String get noSongsInPlaylist => 'No hay canciones en esta lista';

  @override
  String get errorCannotLoad => 'No se pudo cargar la canción';

  @override
  String get languagePicker => 'Idioma';

  @override
  String get langNl => 'Holandés';

  @override
  String get langEn => 'Inglés';

  @override
  String get langEs => 'Español';
}
