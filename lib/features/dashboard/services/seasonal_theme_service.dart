import 'package:flutter/material.dart';
import 'package:recruiter_talentbay/features/dashboard/models/season_model.dart';

/// Service to detect current season and special events based on date
class SeasonalThemeService {
  /// Get the current season information based on the current date
  static SeasonInfo getCurrentSeason() {
    final now = DateTime.now();
    return getSeasonForDate(now);
  }

  /// Get season information for a specific date
  static SeasonInfo getSeasonForDate(DateTime date) {
    // Check for special events first
    final specialEvent = _getSpecialEvent(date);
    if (specialEvent != SpecialEvent.none) {
      return _getSpecialEventInfo(specialEvent);
    }

    // Otherwise, return seasonal information
    final season = _getSeason(date);
    return _getSeasonInfo(season);
  }

  /// Determine the season based on month (Northern Hemisphere)
  static SeasonType _getSeason(DateTime date) {
    final month = date.month;

    if (month >= 3 && month <= 5) {
      return SeasonType.spring; // March, April, May
    } else if (month >= 6 && month <= 8) {
      return SeasonType.summer; // June, July, August
    } else if (month >= 9 && month <= 11) {
      return SeasonType.autumn; // September, October, November
    } else {
      return SeasonType.winter; // December, January, February
    }
  }

  /// Check for special events
  static SpecialEvent _getSpecialEvent(DateTime date) {
    final month = date.month;
    final day = date.day;

    // Christmas Season (December 20-26)
    if (month == 12 && day >= 20 && day <= 26) {
      return SpecialEvent.christmas;
    }

    // New Year (December 27 - January 5)
    if ((month == 12 && day >= 27) || (month == 1 && day <= 5)) {
      return SpecialEvent.newYear;
    }

    // Valentine's Day (February 10-14)
    if (month == 2 && day >= 10 && day <= 14) {
      return SpecialEvent.valentines;
    }

    // Eid al-Fitr (approximate - varies by lunar calendar)
    // This is a simplified check; you should use a proper Islamic calendar library
    // For 2026: around March 20
    if (month == 3 && day >= 18 && day <= 23) {
      return SpecialEvent.eidAlFitr;
    }

    // Eid al-Adha (approximate - varies by lunar calendar)
    // For 2026: around May 27
    if (month == 5 && day >= 25 && day <= 30) {
      return SpecialEvent.eidAlAdha;
    }

    // Diwali (approximate - varies by lunar calendar)
    // Usually in October or November
    if (month == 10 && day >= 20 && day <= 25) {
      return SpecialEvent.diwali;
    }

    return SpecialEvent.none;
  }

  /// Get season information based on season type
  static SeasonInfo _getSeasonInfo(SeasonType type) {
    switch (type) {
      case SeasonType.spring:
        return const SeasonInfo(
          type: SeasonType.spring,
          name: 'Spring',
          description: 'Season of renewal and growth',
          primaryColor: Color(0xFFFF69B4), // Hot pink
          secondaryColor: Color(0xFF90EE90), // Light green
          gradientColors: [
            Color(0xFFFFC0CB), // Pink
            Color(0xFF98FB98), // Pale green
            Color(0xFFE0F7FA), // Light cyan
          ],
          emoji: '🌸',
          icon: Icons.local_florist,
        );

      case SeasonType.summer:
        return const SeasonInfo(
          type: SeasonType.summer,
          name: 'Summer',
          description: 'Season of sunshine and warmth',
          primaryColor: Color(0xFFFFA500), // Orange
          secondaryColor: Color(0xFF87CEEB), // Sky blue
          gradientColors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFFA500), // Orange
            Color(0xFF87CEEB), // Sky blue
          ],
          emoji: '☀️',
          icon: Icons.wb_sunny,
        );

      case SeasonType.autumn:
        return const SeasonInfo(
          type: SeasonType.autumn,
          name: 'Autumn',
          description: 'Season of harvest and change',
          primaryColor: Color(0xFFD2691E), // Chocolate
          secondaryColor: Color(0xFFFF8C00), // Dark orange
          gradientColors: [
            Color(0xFFFF8C00), // Dark orange
            Color(0xFFD2691E), // Chocolate
            Color(0xFF8B4513), // Saddle brown
          ],
          emoji: '🍂',
          icon: Icons.spa,
        );

      case SeasonType.winter:
        return const SeasonInfo(
          type: SeasonType.winter,
          name: 'Winter',
          description: 'Season of rest and reflection',
          primaryColor: Color(0xFF4682B4), // Steel blue
          secondaryColor: Color(0xFFB0E0E6), // Powder blue
          gradientColors: [
            Color(0xFFADD8E6), // Light blue
            Color(0xFF87CEEB), // Sky blue
            Color(0xFF4682B4), // Steel blue
          ],
          emoji: '❄️',
          icon: Icons.ac_unit,
        );
    }
  }

  /// Get special event information
  static SeasonInfo _getSpecialEventInfo(SpecialEvent event) {
    switch (event) {
      case SpecialEvent.christmas:
        return const SeasonInfo(
          type: SeasonType.winter,
          specialEvent: SpecialEvent.christmas,
          name: 'Christmas',
          description: 'Merry Christmas and Happy Holidays!',
          primaryColor: Color(0xFFDC143C), // Crimson
          secondaryColor: Color(0xFF228B22), // Forest green
          gradientColors: [
            Color(0xFFDC143C), // Crimson
            Color(0xFF228B22), // Forest green
            Color(0xFFFFD700), // Gold
          ],
          emoji: '🎄',
          icon: Icons.celebration,
        );

      case SpecialEvent.newYear:
        return const SeasonInfo(
          type: SeasonType.winter,
          specialEvent: SpecialEvent.newYear,
          name: 'New Year',
          description: 'Happy New Year!',
          primaryColor: Color(0xFFFFD700), // Gold
          secondaryColor: Color(0xFF9370DB), // Medium purple
          gradientColors: [
            Color(0xFFFFD700), // Gold
            Color(0xFF9370DB), // Medium purple
            Color(0xFF4169E1), // Royal blue
          ],
          emoji: '🎉',
          icon: Icons.celebration,
        );

      case SpecialEvent.eidAlFitr:
      case SpecialEvent.eidAlAdha:
        return const SeasonInfo(
          type: SeasonType.spring,
          specialEvent: SpecialEvent.eidAlFitr,
          name: 'Eid',
          description: 'Eid Mubarak!',
          primaryColor: Color(0xFF14B8A6), // Teal
          secondaryColor: Color(0xFFFFD700), // Gold
          gradientColors: [
            Color(0xFF14B8A6), // Teal
            Color(0xFFFFD700), // Gold
            Color(0xFF9333EA), // Purple
          ],
          emoji: '🌙',
          icon: Icons.nightlight,
        );

      case SpecialEvent.diwali:
        return const SeasonInfo(
          type: SeasonType.autumn,
          specialEvent: SpecialEvent.diwali,
          name: 'Diwali',
          description: 'Happy Diwali! Festival of Lights',
          primaryColor: Color(0xFFFF6347), // Tomato
          secondaryColor: Color(0xFFFFD700), // Gold
          gradientColors: [
            Color(0xFFFF6347), // Tomato
            Color(0xFFFFA500), // Orange
            Color(0xFFFFD700), // Gold
          ],
          emoji: '🪔',
          icon: Icons.light_mode,
        );

      case SpecialEvent.valentines:
        return const SeasonInfo(
          type: SeasonType.winter,
          specialEvent: SpecialEvent.valentines,
          name: "Valentine's Day",
          description: 'Happy Valentine\'s Day!',
          primaryColor: Color(0xFFFF1493), // Deep pink
          secondaryColor: Color(0xFFFF69B4), // Hot pink
          gradientColors: [
            Color(0xFFFF1493), // Deep pink
            Color(0xFFFF69B4), // Hot pink
            Color(0xFFFFC0CB), // Pink
          ],
          emoji: '💝',
          icon: Icons.favorite,
        );

      case SpecialEvent.none:
        // This shouldn't happen, but return current season as fallback
        final season = _getSeason(DateTime.now());
        return _getSeasonInfo(season);
    }
  }
}
