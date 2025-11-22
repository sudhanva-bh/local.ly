DateTime toIST(DateTime utcTime) {
  return utcTime.toUtc().add(const Duration(hours: 5, minutes: 30));
}
