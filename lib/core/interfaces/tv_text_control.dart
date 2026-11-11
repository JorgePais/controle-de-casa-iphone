/// Text entry into the currently focused TV application field.
abstract interface class TvTextControl {
  Future<void> insertText(String text);
  Future<void> submitText();
}
