import 'dart:convert';

import 'package:nb_utils/nb_utils.dart';

import '../utils/constant.dart';

class UserData {
  int? id;
  String? firstName;
  String? lastName;
  String? username;
  int? providerId;
  int? status;
  int? totalBooking;
  int? totalCompletedBooking;

  ///check its use
  String? description;
  String? knownLanguages;
  String? whyChooseMe;
  String? skills;
  String? userType;
  String? email;
  String? contactNumber;
  int? countryId;
  int? stateId;
  int? cityId;
  String? cityName;
  String? address;
  String? providerTypeId;
  String? providerType;
  int? isFeatured;
  String? displayName;
  String? createdAt;
  String? updatedAt;
  String? profileImage;
  String? timeZone;
  String? lastNotificationSeen;
  String? uid;
  String? socialImage;
  String? loginType;
  int? serviceAddressId;
  num? providersServiceRating;
  num? handymanRating;
  int? isVerifyProvider;
  String? designation;
  String? apiToken;
  String? emailVerifiedAt;
  List<String>? userRole;
  HandymanReview? handymanReview;
  int? isUserExist;
  String? password;
  num? isFavourite;

  String? verificationId;
  String? otpCode;

  bool isSelected = false;
  int? isOnline;
  int? emailVerified;

  // Handyman Data
  String? handymanImage;
  int? isVerifyHandyman;

  int? minPrice;
  int? maxPrice;
  String? referral_code;
  int? loyalty_points;
  int? referrer_points;
  int? referred_user_points;

  ///Local
  bool get isHandyman => userType == USER_TYPE_HANDYMAN;

  bool get isProvider => userType == USER_TYPE_PROVIDER;

  List<String> get knownLanguagesArray => buildKnownLanguages();

  List<String> get skillsArray => buildSkills();

  List<String> buildKnownLanguages() {
    List<String> array = [];
    String tempLanguages = knownLanguages.validate();
    if (tempLanguages.isNotEmpty && tempLanguages.isJson()) {
      Iterable it1 = jsonDecode(knownLanguages.validate());
      array.addAll(it1.map((e) => e.toString()).toList());
    }

    return array;
  }

  List<String> buildSkills() {
    List<String> array = [];
    String tempSkills = skills.validate();
    if (tempSkills.isNotEmpty && tempSkills.isJson()) {
      Iterable it2 = jsonDecode(skills.validate());
      array.addAll(it2.map((e) => e.toString()).toList());
    }

    return array;
  }

  WhyChooseMe get whyChooseMeObj => buildWhyChooseMe();

  WhyChooseMe buildWhyChooseMe() {
    WhyChooseMe obj = WhyChooseMe();
    String tempWhyChooseMe = whyChooseMe.validate();
    if (tempWhyChooseMe.isNotEmpty && tempWhyChooseMe.isJson()) {
      obj = WhyChooseMe.fromJson(jsonDecode(tempWhyChooseMe));
    }
    return obj;
  }

  UserData(
      {this.address,
      this.apiToken,
      this.cityId,
      this.contactNumber,
      this.countryId,
      this.createdAt,
      this.displayName,
      this.socialImage,
      this.email,
      this.emailVerifiedAt,
      this.firstName,
      this.id,
      this.isFeatured,
      this.lastName,
      this.description,
      this.knownLanguages,
      this.whyChooseMe,
      this.skills,
      this.providerType,
      this.cityName,
      this.providerId,
      this.providerTypeId,
      this.stateId,
      this.status,
      this.updatedAt,
      this.userRole,
      this.userType,
      this.username,
      this.profileImage,
      this.uid,
      this.handymanRating,
      this.handymanReview,
      this.lastNotificationSeen,
      this.loginType,
      this.providersServiceRating,
      this.serviceAddressId,
      this.timeZone,
      this.isOnline,
      this.isVerifyProvider,
      this.isUserExist,
      this.password,
      this.isFavourite,
      this.designation,
      this.verificationId,
      this.otpCode,
      this.totalBooking,
      this.totalCompletedBooking,
      this.emailVerified,
      this.handymanImage,
      this.isVerifyHandyman,
      this.minPrice,
      this.maxPrice,
      this.referral_code,
      this.loyalty_points,
      this.referrer_points,
      this.referred_user_points});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
        address: json['address'],
        apiToken: json['api_token'],
        cityId: json['city_id'],
        contactNumber: json['contact_number'],
        countryId: json['country_id'],
        createdAt: json['created_at'],
        displayName: json['display_name'],
        email: json['email'],
        emailVerifiedAt: json['email_verified_at'],
        firstName: json['first_name'],
        id: json['id'].toString().toInt(),
        isFeatured: json['is_featured'],
        lastName: json['last_name'],
        socialImage: json['social_image'],
        providerId: json['provider_id'],
        //providertype_id: json['providertype_id'],
        stateId: json['state_id'],
        status: json['status'],
        updatedAt: json['updated_at'],
        userRole: json['user_role'] != null ? new List<String>.from(json['user_role']) : null,
        userType: json['user_type'],
        username: json['username'],
        isOnline: json['isOnline'],
        profileImage: json['profile_image'],
        uid: json['uid'],
        password: json['password'],
        isFavourite: json['is_favourite'],
        description: json['description'],
        knownLanguages: json['known_languages'],
        whyChooseMe: json['why_choose_me'],
        skills: json['skills'],
        providerType: json['providertype'],
        cityName: json['city_name'],
        loginType: json['login_type'],
        serviceAddressId: json['service_address_id'],
        lastNotificationSeen: json['last_notification_seen'],
        providersServiceRating: json['providers_service_rating'],
        handymanRating: json['handyman_rating'],
        handymanReview: json['handyman_review'] != null ? new HandymanReview.fromJson(json['handyman_review']) : null,
        timeZone: json['time_zone'],
        isVerifyProvider: json['is_verify_provider'],
        isUserExist: json['is_user_exist'],
        verificationId: json['verificationId'],
        designation: json['designation'],
        otpCode: json['otpCode'],
        totalBooking: json['total_services_booked'],
        totalCompletedBooking: json['total_completed_services'],
        emailVerified: json['is_email_verified'],
        handymanImage: json['handyman_image'],
        isVerifyHandyman: json['is_verified'],
        minPrice: json['min_price'],
        maxPrice: json['max_price'],
        loyalty_points: json['loyalty_points'],
        referral_code: json['referral_code'],
        referrer_points: json['referrer_points'],
        referred_user_points: json['referred_user_points']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (address != null) data['address'] = address;
    if (apiToken != null) data['api_token'] = apiToken;
    if (cityId != null) data['city_id'] = cityId;
    if (password != null) data['password'] = password;
    if (contactNumber != null) data['contact_number'] = contactNumber;
    if (countryId != null) data['country_id'] = countryId;
    if (createdAt != null) data['created_at'] = createdAt;
    if (displayName != null) data['display_name'] = displayName;
    if (email != null) data['email'] = email;
    if (emailVerifiedAt != null) data['email_verified_at'] = emailVerifiedAt;
    if (firstName != null) data['first_name'] = firstName;
    if (id != null) data['id'] = id;
    if (socialImage != null) data['social_image'] = socialImage;
    if (isFeatured != null) data['is_featured'] = isFeatured;
    if (lastName != null) data['last_name'] = lastName;
    if (providerId != null) data['provider_id'] = providerId;
    if (providerTypeId != null) data['providertype_id'] = providerTypeId;
    if (stateId != null) data['state_id'] = stateId;
    if (status != null) data['status'] = status;
    if (updatedAt != null) data['updated_at'] = updatedAt;
    if (userType != null) data['user_type'] = userType;
    if (username != null) data['username'] = username;
    if (profileImage != null) data['profile_image'] = profileImage;
    if (uid != null) data['uid'] = uid;
    if (isOnline != null) data['isOnline'] = isOnline;
    if (description != null) data['description'] = description;
    if (knownLanguages != null) data['known_languages'] = knownLanguages;
    if (whyChooseMe != null) data['why_choose_me'] = whyChooseMe;
    if (skills != null) data['skills'] = skills;
    if (providerType != null) data['providertype'] = providerType;
    if (cityName != null) data['city_name'] = cityName;
    if (timeZone != null) data['time_zone'] = timeZone;
    if (loginType != null) data['login_type'] = loginType;
    if (serviceAddressId != null) data['service_address_id'] = serviceAddressId;
    if (lastNotificationSeen != null) data['last_notification_seen'] = lastNotificationSeen;
    if (providersServiceRating != null) data['providers_service_rating'] = providersServiceRating;
    if (handymanRating != null) data['handyman_rating'] = handymanRating;
    if (isVerifyProvider != null) data['is_verify_provider'] = isVerifyProvider;
    if (isUserExist != null) data['is_user_exist'] = isUserExist;
    if (designation != null) data['designation'] = designation;
    if (verificationId != null) data['verificationId'] = verificationId;
    if (otpCode != null) data['otpCode'] = otpCode;
    if (isFavourite != null) data['is_favourite'] = isFavourite;
    if (totalBooking != null) data['total_services_booked'] = totalBooking;
    if (totalCompletedBooking != null) data['total_completed_services'] = totalCompletedBooking;

    if (emailVerified != null) data['is_email_verified'] = emailVerified;
    if (handymanImage != null) data['handyman_image'] = handymanImage;
    if (isVerifyHandyman != null) data['is_verified'] = isVerifyHandyman;
    if (minPrice != null) data['min_price'] = minPrice;
    if (maxPrice != null) data['max_price'] = maxPrice;
    if (referral_code != null) data['referral_code'] = referral_code;
    if (loyalty_points != null) data['loyalty_points'] = loyalty_points;
    if (referrer_points != null) data['referrer_points'] = referrer_points;
    if (referred_user_points != null) data['referred_user_points'] = referred_user_points;
    if (handymanReview != null) {
      data['handyman_review'] = handymanReview!.toJson();
    }
    if (userRole != null) {
      data['user_role'] = userRole;
    }
    return data;
  }

  Map<String, dynamic> toFirebaseJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (id != null) data['id'] = id;
    if (uid != null) data['uid'] = uid;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;
    if (displayName != null) data['display_name'] = displayName;
    if (password != null) data['password'] = password;
    if (profileImage != null) data['profile_image'] = profileImage;
    if (isOnline != null) data['isOnline'] = isOnline;
    if (updatedAt != null) data['updated_at'] = updatedAt;
    if (createdAt != null) data['created_at'] = createdAt;
    if (minPrice != null) data['min_price'] = minPrice;
    if (maxPrice != null) data['max_price'] = maxPrice;
    if (referral_code != null) data['referral_code'] = referral_code;
    if (loyalty_points != null) data['loyalty_points'] = loyalty_points;
    if (referrer_points != null) data['referrer_points'] = referrer_points;
    if (referred_user_points != null) data['referred_user_points'] = referred_user_points;
    return data;
  }
}

class HandymanReview {
  int? id;
  int? customerId;
  num? rating;
  String? review;
  int? serviceId;
  int? bookingId;
  int? handymanId;
  String? handymanName;
  String? handymanProfileImage;
  String? customerName;
  String? customerProfileImage;
  String? createdAt;

  HandymanReview({
    this.id,
    this.customerId,
    this.rating,
    this.review,
    this.serviceId,
    this.bookingId,
    this.handymanId,
    this.handymanName,
    this.handymanProfileImage,
    this.customerName,
    this.customerProfileImage,
    this.createdAt,
  });

  HandymanReview.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    rating = json['rating'];
    review = json['review'];
    serviceId = json['service_id'];
    bookingId = json['booking_id'];
    handymanId = json['handyman_id'];
    handymanName = json['handyman_name'];
    handymanProfileImage = json['handyman_profile_image'];
    customerName = json['customer_name'];
    customerProfileImage = json['customer_profile_image'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['customer_id'] = customerId;
    data['rating'] = rating;
    data['review'] = review;
    data['service_id'] = serviceId;
    data['booking_id'] = bookingId;
    data['handyman_id'] = handymanId;
    data['handyman_name'] = handymanName;
    data['handyman_profile_image'] = handymanProfileImage;
    data['customer_name'] = customerName;
    data['customer_profile_image'] = customerProfileImage;
    data['created_at'] = createdAt;
    return data;
  }
}

class WhyChooseMe {
  String title;
  String aboutDescription;
  List<String> reason;

  WhyChooseMe({
    this.title = "",
    this.aboutDescription = "",
    this.reason = const <String>[],
  });

  factory WhyChooseMe.fromJson(Map<String, dynamic> json) {
    return WhyChooseMe(
      title: json['title'] is String ? json['title'] : "",
      aboutDescription: json['about_description'] is String ? json['about_description'] : "",
      reason: json['why_choose_me_reason'] is List ? List<String>.from(json['why_choose_me_reason'].map((x) => x)) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'about_description': aboutDescription,
      'why_choose_me_reason': reason.map((e) => e).toList(),
    };
  }
}
