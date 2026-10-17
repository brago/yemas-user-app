import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/shop_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'service_data_model.dart';

class ProviderInfoResponse {
  UserData? userData;
  List<ServiceData>? serviceList;
  List<RatingData>? handymanRatingReviewList;
  List<String>? handymanImageList;
  List<UserData>? handymanStaffList;
  List<ShopModel>? shops;

  ProviderInfoResponse({this.userData, this.serviceList, this.handymanRatingReviewList, this.handymanImageList, this.shops});

  ProviderInfoResponse.fromJson(Map<String, dynamic> json) {
    userData = json['data'] != null ? new UserData.fromJson(json['data']) : null;
    if (json['service'] != null) {
      serviceList = [];
      json['service'].forEach((v) {
        serviceList!.add(ServiceData.fromJson(v));
      });
    }
    if (json['handyman_rating_review'] != null) {
      handymanRatingReviewList = [];
      json['handyman_rating_review'].forEach((v) {
        handymanRatingReviewList!.add(new RatingData.fromJson(v));
      });
    }
    handymanImageList = json['handyman_image'] != null ? json['handyman_image'].cast<String>() : null;
    if (json['handyman_staff'] != null) {
      handymanStaffList = json['handyman_staff'] != null ? (json['handyman_staff'] as List).map((i) => UserData.fromJson(i)).toList() : null;
    }
    if (json['shop'] != null) {
      shops = [];
      json['shop'].forEach((v) {
        shops!.add(ShopModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (userData != null) {
      data['data'] = userData!.toJson();
    }
    if (serviceList != null) {
      data['service'] = serviceList!.map((v) => v.toJson()).toList();
    }
    if (handymanRatingReviewList != null) {
      data['handyman_rating_review'] = handymanRatingReviewList!.map((v) => v.toJson()).toList();
    }
    data['handyman_image'] = handymanImageList;
    if (handymanStaffList != null) {
      data['handyman_staff'] = handymanStaffList!.map((v) => v.toJson()).toList();
    }
    if (this.shops != null) {
      data['shop'] = this.shops;
    }
    return data;
  }
}
