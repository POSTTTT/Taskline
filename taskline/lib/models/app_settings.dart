enum TimeFormatPref { hour12, hour24 }

enum DateFormatPref { dmy, mdy, ymd }

enum ThemeModePref { light, dark }

extension ThemeModePrefX on ThemeModePref {
  String get label => this == ThemeModePref.dark ? 'Dark' : 'Light';
}

/// The accent colour scheme. Each palette ships a light + dark variant; this
/// only picks the colour family, [ThemeModePref] picks the brightness.
enum PalettePref { amber, green, cyan, magenta }

extension PalettePrefX on PalettePref {
  String get label {
    switch (this) {
      case PalettePref.amber:
        return 'Amber';
      case PalettePref.green:
        return 'Green';
      case PalettePref.cyan:
        return 'Cyan';
      case PalettePref.magenta:
        return 'Magenta';
    }
  }
}

enum ReminderUnit { minute, hour, day, week, month, year }

extension ReminderUnitX on ReminderUnit {
  String get singular {
    switch (this) {
      case ReminderUnit.minute:
        return 'minute';
      case ReminderUnit.hour:
        return 'hour';
      case ReminderUnit.day:
        return 'day';
      case ReminderUnit.week:
        return 'week';
      case ReminderUnit.month:
        return 'month';
      case ReminderUnit.year:
        return 'year';
    }
  }

  String labelFor(int count) => count == 1 ? singular : '${singular}s';

  Duration toDuration(int count) {
    final n = count < 1 ? 1 : count;
    switch (this) {
      case ReminderUnit.minute:
        return Duration(minutes: n);
      case ReminderUnit.hour:
        return Duration(hours: n);
      case ReminderUnit.day:
        return Duration(days: n);
      case ReminderUnit.week:
        return Duration(days: n * 7);
      case ReminderUnit.month:
        return Duration(days: n * 30);
      case ReminderUnit.year:
        return Duration(days: n * 365);
    }
  }
}

class ReminderInterval {
  final bool enabled;
  final int count;
  final ReminderUnit unit;

  const ReminderInterval({
    this.enabled = true,
    this.count = 1,
    this.unit = ReminderUnit.day,
  });

  static const off = ReminderInterval(enabled: false);

  Duration? get duration => enabled ? unit.toDuration(count) : null;

  String get label {
    if (!enabled) return 'off';
    return 'every $count ${unit.labelFor(count)}';
  }

  ReminderInterval copyWith({bool? enabled, int? count, ReminderUnit? unit}) {
    return ReminderInterval(
      enabled: enabled ?? this.enabled,
      count: count ?? this.count,
      unit: unit ?? this.unit,
    );
  }

  Map<String, Object?> toJson() => {
        'enabled': enabled,
        'count': count,
        'unit': unit.name,
      };

  factory ReminderInterval.fromJson(Map<String, Object?> json) {
    final unitName = json['unit'];
    final unit = ReminderUnit.values.firstWhere(
      (u) => u.name == unitName,
      orElse: () => ReminderUnit.day,
    );
    final rawCount = json['count'];
    final count = rawCount is int && rawCount > 0 ? rawCount : 1;
    final enabled = json['enabled'] is bool ? json['enabled'] as bool : true;
    return ReminderInterval(enabled: enabled, count: count, unit: unit);
  }

  // Value equality so providers can `select` on intervals: without it every
  // AppSettings copy looks like a change and re-triggers notification syncs.
  @override
  bool operator ==(Object other) =>
      other is ReminderInterval &&
      other.enabled == enabled &&
      other.count == count &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(enabled, count, unit);
}

extension TimeFormatPrefX on TimeFormatPref {
  String get label =>
      this == TimeFormatPref.hour24 ? '24 hours' : '12 hours';

  String get pattern => this == TimeFormatPref.hour24 ? 'HH:mm' : 'h:mm a';
}

extension DateFormatPrefX on DateFormatPref {
  String get label {
    switch (this) {
      case DateFormatPref.dmy:
        return 'DD / MM / YYYY';
      case DateFormatPref.mdy:
        return 'MM / DD / YYYY';
      case DateFormatPref.ymd:
        return 'YYYY - MM - DD';
    }
  }

  String get pattern {
    switch (this) {
      case DateFormatPref.dmy:
        return 'd / M / y';
      case DateFormatPref.mdy:
        return 'M / d / y';
      case DateFormatPref.ymd:
        return 'y - MM - dd';
    }
  }
}

class AppSettings {
  final TimeFormatPref timeFormat;
  final DateFormatPref dateFormat;
  final ThemeModePref themeMode;
  final PalettePref palette;
  final bool showNotes;
  final bool launchAtStartup;
  final ReminderInterval moreThan1Year;
  final ReminderInterval dueIn1Year;
  final ReminderInterval dueIn1Month;
  final ReminderInterval dueIn1Week;
  final ReminderInterval dueIn1Day;
  final ReminderInterval dueIn1Hour;

  const AppSettings({
    this.timeFormat = TimeFormatPref.hour24,
    this.dateFormat = DateFormatPref.dmy,
    this.themeMode = ThemeModePref.light,
    this.palette = PalettePref.amber,
    this.showNotes = true,
    this.launchAtStartup = false,
    this.moreThan1Year =
        const ReminderInterval(count: 1, unit: ReminderUnit.year),
    this.dueIn1Year =
        const ReminderInterval(count: 1, unit: ReminderUnit.month),
    this.dueIn1Month =
        const ReminderInterval(count: 1, unit: ReminderUnit.week),
    this.dueIn1Week =
        const ReminderInterval(count: 1, unit: ReminderUnit.day),
    this.dueIn1Day =
        const ReminderInterval(count: 1, unit: ReminderUnit.hour),
    this.dueIn1Hour =
        const ReminderInterval(count: 10, unit: ReminderUnit.minute),
  });

  String get combinedPattern => '${dateFormat.pattern} - ${timeFormat.pattern}';

  AppSettings copyWith({
    TimeFormatPref? timeFormat,
    DateFormatPref? dateFormat,
    ThemeModePref? themeMode,
    PalettePref? palette,
    bool? showNotes,
    bool? launchAtStartup,
    ReminderInterval? moreThan1Year,
    ReminderInterval? dueIn1Year,
    ReminderInterval? dueIn1Month,
    ReminderInterval? dueIn1Week,
    ReminderInterval? dueIn1Day,
    ReminderInterval? dueIn1Hour,
  }) {
    return AppSettings(
      timeFormat: timeFormat ?? this.timeFormat,
      dateFormat: dateFormat ?? this.dateFormat,
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      showNotes: showNotes ?? this.showNotes,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      moreThan1Year: moreThan1Year ?? this.moreThan1Year,
      dueIn1Year: dueIn1Year ?? this.dueIn1Year,
      dueIn1Month: dueIn1Month ?? this.dueIn1Month,
      dueIn1Week: dueIn1Week ?? this.dueIn1Week,
      dueIn1Day: dueIn1Day ?? this.dueIn1Day,
      dueIn1Hour: dueIn1Hour ?? this.dueIn1Hour,
    );
  }

  Map<String, Object?> toJson() => {
        'timeFormat': timeFormat.name,
        'dateFormat': dateFormat.name,
        'themeMode': themeMode.name,
        'palette': palette.name,
        'showNotes': showNotes,
        'launchAtStartup': launchAtStartup,
        'moreThan1Year': moreThan1Year.toJson(),
        'dueIn1Year': dueIn1Year.toJson(),
        'dueIn1Month': dueIn1Month.toJson(),
        'dueIn1Week': dueIn1Week.toJson(),
        'dueIn1Day': dueIn1Day.toJson(),
        'dueIn1Hour': dueIn1Hour.toJson(),
      };

  static T _enumFrom<T extends Enum>(
    List<T> values,
    Object? raw,
    T fallback,
  ) {
    if (raw is! String) return fallback;
    return values.firstWhere((v) => v.name == raw, orElse: () => fallback);
  }

  static ReminderInterval _intervalFrom(Object? raw, ReminderInterval fallback) {
    if (raw is Map) {
      return ReminderInterval.fromJson(raw.cast<String, Object?>());
    }
    return fallback;
  }

  factory AppSettings.fromJson(Map<String, Object?> json) {
    const defaults = AppSettings();
    return AppSettings(
      timeFormat: _enumFrom(
          TimeFormatPref.values, json['timeFormat'], defaults.timeFormat),
      dateFormat: _enumFrom(
          DateFormatPref.values, json['dateFormat'], defaults.dateFormat),
      themeMode: _enumFrom(
          ThemeModePref.values, json['themeMode'], defaults.themeMode),
      palette:
          _enumFrom(PalettePref.values, json['palette'], defaults.palette),
      showNotes:
          json['showNotes'] is bool ? json['showNotes'] as bool : defaults.showNotes,
      launchAtStartup: json['launchAtStartup'] is bool
          ? json['launchAtStartup'] as bool
          : defaults.launchAtStartup,
      moreThan1Year:
          _intervalFrom(json['moreThan1Year'], defaults.moreThan1Year),
      dueIn1Year: _intervalFrom(json['dueIn1Year'], defaults.dueIn1Year),
      dueIn1Month: _intervalFrom(json['dueIn1Month'], defaults.dueIn1Month),
      dueIn1Week: _intervalFrom(json['dueIn1Week'], defaults.dueIn1Week),
      dueIn1Day: _intervalFrom(json['dueIn1Day'], defaults.dueIn1Day),
      dueIn1Hour: _intervalFrom(json['dueIn1Hour'], defaults.dueIn1Hour),
    );
  }
}
