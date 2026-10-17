class NotificationListResponse {
  List<NotificationData>? notificationData;
  int? allUnreadCount;

  NotificationListResponse({this.notificationData, this.allUnreadCount});

  NotificationListResponse.fromJson(Map<String, dynamic> json) {
    if (json['notification_data'] != null) {
      notificationData = [];
      json['notification_data'].forEach((v) {
        notificationData!.add(new NotificationData.fromJson(v));
      });
    }
    allUnreadCount = json['all_unread_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (notificationData != null) {
      data['notification_data'] = notificationData!.map((v) => v.toJson()).toList();
    }
    data['all_unread_count'] = allUnreadCount;
    return data;
  }
}

class NotificationData {
  String? id;
  String? readAt;
  String? createdAt;
  String? profileImage;
  NotificationInnerData? data;

  NotificationData({this.id, this.readAt, this.createdAt, this.data});

  NotificationData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    readAt = json['read_at'];
    createdAt = json['created_at'];
    profileImage = json['profile_image'];
    data = json['data'] != null ? new NotificationInnerData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['read_at'] = readAt;
    data['created_at'] = createdAt;
    data['profile_image'] = profileImage;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class NotificationInnerData {
  int? id;
  String? type;
  String? subject;
  String? message;
  String? notificationType;
  String? checkBookingType;
  int? jobId;

  NotificationInnerData({this.id, this.type, this.checkBookingType, this.subject, this.message, this.notificationType, this.jobId,});

  NotificationInnerData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    subject = json['subject'];
    message = json['message'];
    notificationType = json['notification-type'];
    checkBookingType = json['check_booking_type'];
    jobId = json['job_id'] is int ? json['job_id'] : 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['type'] = type;
    data['subject'] = subject;
    data['message'] = message;
    data['notification-type'] = notificationType;
    data['check_booking_type'] = checkBookingType;
    data['job_id'] = jobId;
    return data;
  }
}