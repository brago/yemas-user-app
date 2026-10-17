class LoyaltyHistoryResponse {
  bool status;
  Pagination pagination;
  List<LoyaltyHistoryItem> data;

  LoyaltyHistoryResponse({
    this.status = false,
    required this.pagination,
    this.data = const [],
  });

  factory LoyaltyHistoryResponse.fromJson(Map<String, dynamic> json) {
    return LoyaltyHistoryResponse(
      status: json['status'] == true,
      pagination: json['pagination'] is Map ? Pagination.fromJson(json['pagination']) : Pagination(),
      data: json['data'] is List ? (json['data'] as List).map((e) => LoyaltyHistoryItem.fromJson(e as Map<String, dynamic>)).toList() : <LoyaltyHistoryItem>[],
    );
  }
}

class Pagination {
  int totalItems;
  int perPage;
  int currentPage;
  int totalPages;
  int from;
  int to;
  String nextPage;
  dynamic previousPage;

  Pagination({
    this.totalItems = -1,
    this.perPage = -1,
    this.currentPage = -1,
    this.totalPages = -1,
    this.from = -1,
    this.to = -1,
    this.nextPage = "",
    this.previousPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalItems: json['total_items'] is int ? json['total_items'] : -1,
      perPage: json['per_page'] is int ? json['per_page'] : -1,
      currentPage: json['currentPage'] is int ? json['currentPage'] : -1,
      totalPages: json['totalPages'] is int ? json['totalPages'] : -1,
      from: json['from'] is int ? json['from'] : -1,
      to: json['to'] is int ? json['to'] : -1,
      nextPage: json['next_page'] is String ? json['next_page'] : "",
      previousPage: json['previous_page'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'per_page': perPage,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'from': from,
      'to': to,
      'next_page': nextPage,
      'previous_page': previousPage,
    };
  }
}

class LoyaltyHistoryItem {
  final int id;
  final String type;
  final int points;
  final String source;
  final String status;
  final int bookingId;
  final String description;
  final String createdAt;

  const LoyaltyHistoryItem({
    this.id = -1,
    this.type = '',
    this.points = 0,
    this.source = '',
    this.status = '',
    this.bookingId = -1,
    this.description = '',
    this.createdAt = '',
  });

  factory LoyaltyHistoryItem.fromJson(Map<String, dynamic> json) {
    return LoyaltyHistoryItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? -1,
      type: json['type']?.toString() ?? '',
      points: json['points'] is int ? json['points'] as int : int.tryParse('${json['points']}') ?? 0,
      source: json['source']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      bookingId: json['booking_id'] is int ? json['booking_id'] as int : int.tryParse('${json['booking_id']}') ?? -1,
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

