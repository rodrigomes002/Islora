abstract interface class SpeechService {
  Future<void> speak(String text);

  Future<void> stop();
}
