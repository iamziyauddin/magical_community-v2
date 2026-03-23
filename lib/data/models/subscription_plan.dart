class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final int duration;
  final String durationUnit;
  final List<String> features;
  final bool isTrial;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.durationUnit,
    required this.features,
    required this.isTrial,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as int,
      durationUnit: json['durationUnit'] as String,
      features: List<String>.from(json['features'] as List),
      isTrial: (json['isTrial'] as bool?) ?? false,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'durationUnit': durationUnit,
      'features': features,
      'isTrial': isTrial,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get displayDuration =>
      '$duration ${durationUnit.toLowerCase()}${duration > 1 ? 's' : ''}';
  String get displayPrice => '₹${price.toInt()}';
}

class SubscriptionPlansResponse {
  final bool success;
  final String message;
  final List<SubscriptionPlan> data;
  final String timestamp;

  const SubscriptionPlansResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory SubscriptionPlansResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlansResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data']['plans'] as List)
          .map(
            (item) => SubscriptionPlan.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((plan) => plan.toJson()).toList(),
      'timestamp': timestamp,
    };
  }
}
