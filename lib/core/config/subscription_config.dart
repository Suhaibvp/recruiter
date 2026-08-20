class SubscriptionConfig {
  static const String monthlyStoreKitId = 'com.waqttix.talentbay.recruiter.monthly';
  static const String sixMonthsStoreKitId = 'com.waqttix.talentbay.recruiter.sixmonths';
  static const String yearlyStoreKitId = 'com.waqttix.talentbay.recruiter.yearly';

  static const Map<String, String> planStoreKitIds = {
    'monthly_1499': monthlyStoreKitId,
    'six_months_8549': sixMonthsStoreKitId,
    'yearly_17089': yearlyStoreKitId,
  };

  static String? getStoreKitProductId(String planId) {
    return planStoreKitIds[planId];
  }
}
