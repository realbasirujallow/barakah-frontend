class Asset {
  final int? id;
  final String name;
  final String type;
  final double value;
  final String? userId;
  final double? penaltyRate;
  final double? taxRate;

  Asset({
    this.id,
    required this.name,
    required this.type,
    required this.value,
    this.userId,
    this.penaltyRate,
    this.taxRate,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      userId: json['userId'] as String?,
      penaltyRate: (json['penaltyRate'] as num?)?.toDouble(),
      taxRate: (json['taxRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'value': value,
      if (userId != null) 'userId': userId,
      if (penaltyRate != null) 'penaltyRate': penaltyRate,
      if (taxRate != null) 'taxRate': taxRate,
    };
  }

  Asset copyWith({
    int? id,
    String? name,
    String? type,
    double? value,
    String? userId,
    double? penaltyRate,
    double? taxRate,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      userId: userId ?? this.userId,
      penaltyRate: penaltyRate ?? this.penaltyRate,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  /// Returns the icon for the asset type
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'crypto':
        return '₿';
      case 'stock':
        return '📈';
      case 'gold':
        return '🥇';
      case 'cash':
        return '💵';
      case 'real_estate':
      case 'realestate':
        return '🏠';
      default:
        return '💰';
    }
  }
}
