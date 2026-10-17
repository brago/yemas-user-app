import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:nb_utils/nb_utils.dart';

class BookingPackage {
  int? id;
  String? name;
  String? description;
  num? price;
  String? startDate;
  String? endDate;
  List<ServiceData>? serviceList;
  var isFeatured;
  int? categoryId;
  List<Attachments>? attchments;
  List<String>? imageAttachments;
  int? status;
  String? packageType;
  int? earnPoints;
  RedeemPoints? redeemPoints;
  num originalPrice = 0;
  bool get isPackageDiscountApplied => originalPrice >= price.validate();
  bool get isAllServiceOnline => serviceList.validate().map((e) => e.isOnlineService).toList().where((element) => element == false).length == 0;

  BookingPackage({
    this.id,
    this.name,
    this.description,
    this.price,
    this.startDate,
    this.endDate,
    this.serviceList,
    this.isFeatured,
    this.categoryId,
    this.attchments,
    this.imageAttachments,
    this.status,
    this.packageType,
    this.earnPoints,
    this.redeemPoints
  });

  BookingPackage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    status = json['status'];
    if (json['services'] != null) {
      serviceList = json['services'] != null ? (json['services'] as List).map((i) => ServiceData.fromJson(i)).toList() : null;
    }
    attchments = json['attchments_array'] != null ? (json['attchments_array'] as List).map((i) => Attachments.fromJson(i)).toList() : null;
    imageAttachments = json['attchments'] != null ? List<String>.from(json['attchments']) : null;
    categoryId = json['category_id'];
    isFeatured = json['is_featured'];
    packageType = json['package_type'];
    originalPrice = serviceList.validate().sumByDouble((e) => e.price.validate());
    earnPoints = json['earn_points'];
    redeemPoints = json['redeem_points'] != null ? RedeemPoints.fromJson(json['redeem_points']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['status'] = status;
    data['package_type'] = packageType;
    if (serviceList != null) {
      data['services'] = serviceList!.map((v) => v.toJson()).toList();
    }
    data['category_id'] = categoryId;
    data['is_featured'] = isFeatured;
    if (attchments != null) {
      data['attchments_array'] = attchments!.map((v) => v.toJson()).toList();
    }
    if (imageAttachments != null) {
      data['attchments'] = imageAttachments;
    }
    if(earnPoints != null){
      data['earn_points'] = earnPoints;
    }
    if(redeemPoints != null){
      data['redeem_points'] = redeemPoints!.toJson();
    }
    return data;
  }
}

class Attachments {
  int? id;
  String? url;

  Attachments({this.id, this.url});

  factory Attachments.fromJson(Map<String, dynamic> json) {
    return Attachments(
      id: json['id'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['url'] = url;
    return data;
  }
}
