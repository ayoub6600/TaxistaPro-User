/// «العب وأنت تستنى» — Taxista waiting games.
///
/// The host (booking screens) only needs this file:
/// * [WaitingGamesConfig.loadFrom] with the admin settings map (null = off, unless a tryout build).
/// * a `ValueListenable<RideGameStatus>` built from its own ride data — the games only listen.
/// * [WaitingGamesBox] inside the searching / ride sheet (≈ a quarter of the screen),
///   [WaitingGamesFullScreen] (opened by the box's «تكبير»), [GamesCenterPage],
///   and [WaitingGameToasts] for «🚕 لقينا لك سائق!» / «السائق قرّب يوصل!».
library;

export 'catalog.dart' show GameCatalog;
export 'core/config.dart' show WaitingGamesConfig;
export 'core/controller.dart' show RideGameStatus, WaitingGamesController;
export 'core/game_core.dart' show TaxistaGame, WorldGame, GameSession, GameResult, GameWorld, GameThumb;
export 'core/progress.dart' show GameProgress, GameStats;
export 'core/theme.dart' show GamesTheme, CarSkin;
export 'ui/players.dart' show WaitingGamesBox, WaitingGamesFullScreen, GamesCenterPage, WaitingGameToasts;
export 'ui/stage.dart' show GameStage, GamePicker, GameCard, StarsRow;
