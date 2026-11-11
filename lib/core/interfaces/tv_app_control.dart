/// App shortcuts supported by the selected television.
abstract interface class TvAppControl {
  Future<void> openYouTube();
  Future<void> openNetflix();
  Future<void> openPrimeVideo();
  Future<void> openDisneyPlus();
}
