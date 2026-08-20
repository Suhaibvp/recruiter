import 'package:cloud_firestore/cloud_firestore.dart';

class RecruiterModel {
  final String uid;
  final String companyId; // Link to Company Document
  final String fullName;
  final String designation;
  final String officialEmail;
  final String phoneNumber;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final bool isSubscribed;
  final bool isSubscriptionCancelled;
  final DateTime? subscriptionExpiry;
  final String? subscriptionPlanId;
  final String? razorpaySubscriptionId;
  final String? appleSubscriptionId;

  RecruiterModel({
    required this.uid,
    required this.companyId,
    required this.fullName,
    required this.designation,
    required this.officialEmail,
    required this.phoneNumber,
    required this.emailVerified,
    required this.phoneVerified,
    required this.createdAt,
    this.isSubscribed = false,
    this.isSubscriptionCancelled = false,
    this.subscriptionExpiry,
    this.subscriptionPlanId,
    this.razorpaySubscriptionId,
    this.appleSubscriptionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'companyId': companyId,
      'fullName': fullName,
      'designation': designation,
      'officialEmail': officialEmail,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSubscribed': isSubscribed,
      'isSubscriptionCancelled': isSubscriptionCancelled,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
      'subscriptionPlanId': subscriptionPlanId,
      'razorpaySubscriptionId': razorpaySubscriptionId,
      'appleSubscriptionId': appleSubscriptionId,
    };
  }

  factory RecruiterModel.fromMap(Map<String, dynamic> map) {
    return RecruiterModel(
      uid: map['uid'] ?? '',
      companyId: map['companyId'] ?? '',
      fullName: map['fullName'] ?? '',
      designation: map['designation'] ?? '',
      officialEmail: map['officialEmail'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      emailVerified: map['emailVerified'] ?? false,
      phoneVerified: map['phoneVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSubscribed: map['isSubscribed'] ?? false,
      isSubscriptionCancelled: map['isSubscriptionCancelled'] ?? false,
      subscriptionExpiry: (map['subscriptionExpiry'] as Timestamp?)?.toDate(),
      subscriptionPlanId: map['subscriptionPlanId'],
      razorpaySubscriptionId: map['razorpaySubscriptionId'],
      appleSubscriptionId: map['appleSubscriptionId'],
    );
  }

  RecruiterModel copyWith({
    String? uid,
    String? companyId,
    String? fullName,
    String? designation,
    String? officialEmail,
    String? phoneNumber,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
    bool? isSubscribed,
    bool? isSubscriptionCancelled,
    DateTime? subscriptionExpiry,
    String? subscriptionPlanId,
    String? razorpaySubscriptionId,
    String? appleSubscriptionId,
  }) {
    return RecruiterModel(
      uid: uid ?? this.uid,
      companyId: companyId ?? this.companyId,
      fullName: fullName ?? this.fullName,
      designation: designation ?? this.designation,
      officialEmail: officialEmail ?? this.officialEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isSubscriptionCancelled: isSubscriptionCancelled ?? this.isSubscriptionCancelled,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      razorpaySubscriptionId:
          razorpaySubscriptionId ?? this.razorpaySubscriptionId,
      appleSubscriptionId: appleSubscriptionId ?? this.appleSubscriptionId,
    );
  }
}
