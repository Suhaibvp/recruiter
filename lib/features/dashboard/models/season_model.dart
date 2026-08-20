import 'package:flutter/material.dart';

/// Represents different seasons throughout the year
enum SeasonType { spring, summer, autumn, winter }

/// Represents special events and holidays
enum SpecialEvent {
  none,
  christmas,
  newYear,
  eidAlFitr,
  eidAlAdha,
  diwali,
  valentines,
}

/// Model for seasonal information
class SeasonInfo {
  final SeasonType type;
  final SpecialEvent specialEvent;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> gradientColors;
  final String emoji;
  final IconData icon;

  const SeasonInfo({
    required this.type,
    this.specialEvent = SpecialEvent.none,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gradientColors,
    required this.emoji,
    required this.icon,
  });

  bool get hasSpecialEvent => specialEvent != SpecialEvent.none;

  String get displayName =>
      hasSpecialEvent ? _getEventName(specialEvent) : name;

  String _getEventName(SpecialEvent event) {
    switch (event) {
      case SpecialEvent.christmas:
        return 'Christmas Season';
      case SpecialEvent.newYear:
        return 'New Year';
      case SpecialEvent.eidAlFitr:
        return 'Eid al-Fitr';
      case SpecialEvent.eidAlAdha:
        return 'Eid al-Adha';
      case SpecialEvent.diwali:
        return 'Diwali';
      case SpecialEvent.valentines:
        return "Valentine's Day";
      case SpecialEvent.none:
        return name;
    }
  }
}
