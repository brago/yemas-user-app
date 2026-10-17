import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  String? uid;
  String? senderId;
  String? receiverId;
  String? photoUrl;
  List<String>? attachmentfiles;
  String? messageType;
  bool? isMe;
  bool? isMessageRead;
  String? message;
  int? createdAt;
  Timestamp? createdAtTime;
  Timestamp? updatedAtTime;
  DocumentReference? chatDocumentReference;

  ChatMessageModel({
    this.uid,
    this.senderId,
    this.createdAtTime,
    this.updatedAtTime,
    this.receiverId,
    this.createdAt,
    this.message,
    this.isMessageRead,
    this.photoUrl,
    this.attachmentfiles,
    this.messageType,
    this.chatDocumentReference,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      uid: json['uid'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      message: json['message'],
      isMessageRead: json['isMessageRead'],
      photoUrl: json['photoUrl'],
      attachmentfiles: json['attachmentfiles'] is List ? List<String>.from(json['attachmentfiles'].map((x) => x)) : [],
      messageType: json['messageType'],
      createdAt: json['createdAt'],
      createdAtTime: json['createdAtTime'],
      updatedAtTime: json['updatedAtTime'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (uid != null) data['uid'] = uid;
    if (createdAt != null) data['createdAt'] = createdAt;
    if (message != null) data['message'] = message;
    if (senderId != null) data['senderId'] = senderId;
    if (isMessageRead != null) data['isMessageRead'] = isMessageRead;
    if (receiverId != null) data['receiverId'] = receiverId;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (attachmentfiles != null) data['attachmentfiles'] = attachmentfiles?.map((e) => e).toList();
    if (createdAtTime != null) data['createdAtTime'] = createdAtTime;
    if (updatedAtTime != null) data['updatedAtTime'] = updatedAtTime;
    if (messageType != null) data['messageType'] = messageType;
    return data;
  }
}
