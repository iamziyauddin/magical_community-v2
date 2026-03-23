import 'inventory_model.dart';

/// API Product model for external product data
class ApiProductModel {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiProductModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiProductModel.fromJson(Map<String, dynamic> json) {
    return ApiProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to InventoryModel for UI compatibility
  InventoryModel toInventoryModel() {
    return InventoryModel(
      id: id,
      productName: name,
      currentStock: 0, // API doesn't provide stock info
      totalReceived: 0,
      totalUsed: 0,
      lastUpdated: updatedAt,
      description: 'Product from API',
      createdAt: createdAt,
    );
  }
}

/// API Products Response model
class ApiProductsResponse {
  final bool success;
  final String message;
  final DateTime timestamp;
  final ApiProductsData data;

  ApiProductsResponse({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.data,
  });

  factory ApiProductsResponse.fromJson(Map<String, dynamic> json) {
    return ApiProductsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: ApiProductsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class ApiProductsData {
  final List<ApiProductModel> data;
  final ApiProductsMeta meta;

  ApiProductsData({required this.data, required this.meta});

  factory ApiProductsData.fromJson(Map<String, dynamic> json) {
    return ApiProductsData(
      data: (json['data'] as List)
          .map((item) => ApiProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: ApiProductsMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class ApiProductsMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  ApiProductsMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory ApiProductsMeta.fromJson(Map<String, dynamic> json) {
    return ApiProductsMeta(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPrevPage: json['hasPrevPage'] as bool,
    );
  }
}

/// API Usage Request model
class ApiUsageRequest {
  final String usageDate;
  final List<ApiUsageProduct> products;

  ApiUsageRequest({required this.usageDate, required this.products});

  Map<String, dynamic> toJson() {
    return {
      'usageDate': usageDate,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }
}

class ApiUsageProduct {
  final String productId;
  final int quantity;

  ApiUsageProduct({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'quantity': quantity};
  }
}

/// API Usage Response model
class ApiUsageResponse {
  final bool success;
  final String message;
  final DateTime timestamp;
  final ApiUsageData data;

  ApiUsageResponse({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.data,
  });

  factory ApiUsageResponse.fromJson(Map<String, dynamic> json) {
    return ApiUsageResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: ApiUsageData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class ApiUsageData {
  final int count;
  final List<ApiUsageRecord> records;
  final ApiClub club;
  final DateTime usageDate;

  ApiUsageData({
    required this.count,
    required this.records,
    required this.club,
    required this.usageDate,
  });

  factory ApiUsageData.fromJson(Map<String, dynamic> json) {
    return ApiUsageData(
      count: json['count'] as int,
      records: (json['records'] as List)
          .map((item) => ApiUsageRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      club: ApiClub.fromJson(json['club'] as Map<String, dynamic>),
      usageDate: DateTime.parse(json['usageDate'] as String),
    );
  }
}

class ApiUsageRecord {
  final String id;
  final String productId;
  final String clubId;
  final DateTime usageDate;
  final int quantity;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ApiProduct product;
  final ApiClub club;
  final ApiCreator creator;

  ApiUsageRecord({
    required this.id,
    required this.productId,
    required this.clubId,
    required this.usageDate,
    required this.quantity,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.club,
    required this.creator,
  });

  factory ApiUsageRecord.fromJson(Map<String, dynamic> json) {
    return ApiUsageRecord(
      id: json['id'] as String,
      productId: json['productId'] as String,
      clubId: json['clubId'] as String,
      usageDate: DateTime.parse(json['usageDate'] as String),
      quantity: json['quantity'] as int,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      product: ApiProduct.fromJson(json['product'] as Map<String, dynamic>),
      club: ApiClub.fromJson(json['club'] as Map<String, dynamic>),
      creator: ApiCreator.fromJson(json['creator'] as Map<String, dynamic>),
    );
  }
}

class ApiProduct {
  final String name;

  ApiProduct({required this.name});

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(name: json['name'] as String);
  }
}

class ApiClub {
  final String name;
  final String code;

  ApiClub({required this.name, required this.code});

  factory ApiClub.fromJson(Map<String, dynamic> json) {
    return ApiClub(name: json['name'] as String, code: json['code'] as String);
  }
}

class ApiCreator {
  final String firstName;
  final String lastName;

  ApiCreator({required this.firstName, required this.lastName});

  factory ApiCreator.fromJson(Map<String, dynamic> json) {
    return ApiCreator(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }
}
