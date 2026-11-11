class TvInput {
  const TvInput({required this.id, required this.label});
  final String id;
  final String label;
}

abstract interface class TvInputControl {
  Future<List<TvInput>> inputs();
  Future<void> selectInput(String id);
}
