class PhraseReviewSchedule {
  const PhraseReviewSchedule._();

  static int nextIntervalDays({
    required int currentIntervalDays,
    required bool wasCorrect,
  }) {
    if (!wasCorrect) return 1;
    if (currentIntervalDays <= 0) return 1;
    if (currentIntervalDays == 1) return 3;
    if (currentIntervalDays <= 3) return 7;
    if (currentIntervalDays <= 7) return 14;
    return 30;
  }
}
