import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:nb_utils/nb_utils.dart';

class ShopModel {
  int id;
  String registrationNumber;
  String name;
  int countryId;
  String countryName;
  int stateId;
  String stateName;
  int cityId;
  String cityName;
  String address;
  String shopStartTime;
  String shopEndTime;
  double latitude;
  double longitude;
  String contactNumber;
  String email;
  List<String> shopImage;
  List<ServiceData> services;
  int providerId;
  String providerName;
  String providerImage;
  int isFavourite;
  int serviceCount;

  num providerServiceRating;

  String get shopFirstImage => shopImage.isNotEmpty ? shopImage.first : '';

  bool isSelected = false;

  ShopModel({
    this.id = -1,
    this.registrationNumber = "",
    this.name = "",
    this.countryId = -1,
    this.countryName = "",
    this.stateId = -1,
    this.stateName = "",
    this.cityId = -1,
    this.cityName = "",
    this.address = "",
    this.shopStartTime = "",
    this.shopEndTime = "",
    this.latitude = 0,
    this.longitude = 0,
    this.contactNumber = "",
    this.email = "",
    this.shopImage = const <String>[],
    this.services = const <ServiceData>[],
    this.providerId = -1,
    this.providerName = "",
    this.providerImage = "",
    this.isFavourite = 0,
    this.serviceCount = 0,
    this.providerServiceRating = 0.0,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] is int ? json['id'] : -1,
      registrationNumber: json['registration_number'] is String ? json['registration_number'] : "",
      name: json['name'] is String ? json['name'] : "",
      countryId: json['country_id'] is int ? json['country_id'] : -1,
      countryName: json['country_name'] is String ? json['country_name'] : "",
      stateId: json['state_id'] is int ? json['state_id'] : -1,
      stateName: json['state_name'] is String ? json['state_name'] : "",
      cityId: json['city_id'] is int ? json['city_id'] : -1,
      cityName: json['city_name'] is String ? json['city_name'] : "",
      address: json['address'] is String ? json['address'] : "",
      shopStartTime: json['shop_start_time'] is String ? json['shop_start_time'] : "",
      shopEndTime: json['shop_end_time'] is String ? json['shop_end_time'] : "",
      latitude: json['latitude'] is double ? json['latitude'] : 0,
      longitude: json['longitude'] is double ? json['longitude'] : 0,
      contactNumber: json['contact_number'] is String ? json['contact_number'] : "",
      email: json['email'] is String ? json['email'] : "",
      shopImage: json['shop_image'] is List ? List<String>.from(json['shop_image']) : [],
      services: json['services'] is List ? List<ServiceData>.from(json['services'].map((x) => ServiceData.fromJson(x))) : [],
      providerId: json['provider_id'] is int ? json['provider_id'] : -1,
      providerName: json['provider_name'] is String ? json['provider_name'] : "",
      providerImage: json['provider_image'] is String ? json['provider_image'] : "",
      isFavourite: json['is_favourite'] is int ? json['is_favourite'] : 0,
      serviceCount: json['services_count'] is int ? json['services_count'] : 0,
      providerServiceRating: json['providers_service_rating'] is num ? json['providers_service_rating'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'name': name,
      'country_id': countryId,
      'country_name': countryName,
      'state_id': stateId,
      'state_name': stateName,
      'city_id': cityId,
      'city_name': cityName,
      'address': address,
      'shop_start_time': shopStartTime,
      'shop_end_time': shopEndTime,
      'latitude': latitude,
      'longitude': longitude,
      'contact_number': contactNumber,
      'email': email,
      'shop_image': shopImage.map((e) => e).toList(),
      'services': services.map((e) => e.toJson()).toList(),
      'provider_id': providerId,
      'provider_name': providerName,
      'provider_image': providerImage,
      'is_favourite': isFavourite,
      'providers_service_rating': providerServiceRating,
    };
  }

  String buildFullAddress() {
    List<String> addressParts = [];

    if (address.isNotEmpty) {
      addressParts.add(address);
    }

    if ((cityName).isNotEmpty) {
      addressParts.add(cityName.validate());
    }
    if ((stateName).isNotEmpty) {
      addressParts.add(stateName.validate());
    }
    if ((countryName).isNotEmpty) {
      addressParts.add(countryName.validate());
    }

    if (addressParts.isEmpty) return '---';

    return addressParts.join(', ');
  }
}

class ShopResponse {
  List<ShopModel>? shopList;

  ShopResponse({this.shopList});

  factory ShopResponse.fromJson(Map<String, dynamic> json) {
    return ShopResponse(
      shopList: json['data'] != null ? (json['data'] as List).map((i) => ShopModel.fromJson(i)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.shopList != null) {
      data['data'] = this.shopList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ShopDetailResponse {
  ShopModel? shopDetail;

  ShopDetailResponse({this.shopDetail});

  factory ShopDetailResponse.fromJson(Map<String, dynamic> json) {
    return ShopDetailResponse(
      shopDetail: json['shop'] != null ? ShopModel.fromJson(json['shop']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.shopDetail != null) {
      data['shop'] = this.shopDetail!.toJson();
    }
    return data;
  }
}