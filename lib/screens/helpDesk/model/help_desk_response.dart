import '../../../model/bank_list_response.dart';
import '../../../model/package_data_model.dart';

class HelpDeskResponse {
  Pagination? pagination;
  List<HelpDeskListData>? data;

  HelpDeskResponse({this.pagination, this.data});

  factory HelpDeskResponse.fromJson(Map<String, dynamic> json) {
    return HelpDeskResponse(
      data: json["data"] != null ? (json['data'] as List).map((i) => HelpDeskListData.fromJson(i)).toList() : null,
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      data['pagination'] = pagination!.toJson();
    }
    return data;
  }
}

class HelpDeskListData {
  int? id;
  String? subject;
  int? employeeId;
  String? description;
  String? createdAt;
  String? updatedAt;
  String? employeeName;
  String? status;
  List<String>? helDeskAttachments;
  List<Attachments>? attachments;

  HelpDeskListData({
    this.id,
    this.subject,
    this.employeeId,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.employeeName,
    this.status,
    this.helDeskAttachments,
    this.attachments,
  });

  HelpDeskListData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    subject = json['subject'];
    employeeId = json['employee_id'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    employeeName = json['employee_name'];
    status = json['status'];
    helDeskAttachments = json['attachments'] != null ? new List<String>.from(json['attachments']) : null;
    attachments = json['attachments_array'] != null ? (json['attachments_array'] as List).map((i) => Attachments.fromJson(i)).toList() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['subject'] = subject;
    data['employee_id'] = employeeId;
    data['description'] = description;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['employee_name'] = employeeName;
    data['status'] = status;
    if (helDeskAttachments != null) {
      data['attachments'] = helDeskAttachments;
    }
    if (attachments != null) {
      data['attachments_array'] = attachments!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
