/// Optional absolute-volume capability. Null means no usable level is reported.
abstract interface class TvVolumeControl {
  Future<int?> volume();
  Future<void> setVolume(int value);
}
