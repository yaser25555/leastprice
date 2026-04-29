import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/core/utils/helpers.dart';

class UserSavingsProfile {
  const UserSavingsProfile({
    required this.userId,
    required this.phoneNumber,
    required this.inviteCode,
    required this.invitedBy,
    required this.invitedFriendsCount,
    required this.referralRewardApplied,
    required this.shareBaseUrl,
    required this.inviteMessageTemplate,
  });

  final String userId;
  final String phoneNumber;
  final String inviteCode;
  final String invitedBy;
  final int invitedFriendsCount;
  final bool referralRewardApplied;
  final String shareBaseUrl;
  final String inviteMessageTemplate;

  factory UserSavingsProfile.initial() {
    return const UserSavingsProfile(
      userId: '',
      phoneNumber: '',
      inviteCode: 'LP-RIY-204',
      invitedBy: '',
      invitedFriendsCount: 0,
      referralRewardApplied: false,
      shareBaseUrl: LeastPriceDataConfig.appShareUrl,
      inviteMessageTemplate:
          'أنا وفرت {SAVED_AMOUNT} ريال باستخدام تطبيق أرخص سعر! '
          'حمل التطبيق الآن واستخدم كود الدعوة الخاص بي: {USER_CODE}\n{APP_LINK}',
    );
  }

  factory UserSavingsProfile.fromJson(Map<String, dynamic> json) {
    return UserSavingsProfile(
      userId: stringValue(json['userId']) ?? '',
      phoneNumber: stringValue(json['phoneNumber']) ?? '',
      inviteCode: stringValue(json['referralCode'] ?? json['inviteCode']) ??
          'LP-RIY-204',
      invitedBy: stringValue(json['invitedBy']) ?? '',
      invitedFriendsCount:
          intValue(json['invitedCount'] ?? json['invitedFriendsCount']),
      referralRewardApplied:
          boolValue(json['referralRewardApplied'] ?? json['rewardApplied']),
      shareBaseUrl:
          stringValue(json['shareBaseUrl']) ?? LeastPriceDataConfig.appShareUrl,
      inviteMessageTemplate: stringValue(json['inviteMessageTemplate']) ??
          'أنا وفرت {SAVED_AMOUNT} ريال باستخدام تطبيق أرخص سعر! '
              'حمل التطبيق الآن واستخدم كود الدعوة الخاص بي: {USER_CODE}\n{APP_LINK}',
    );
  }

  factory UserSavingsProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return UserSavingsProfile.fromJson({
      ...?document.data(),
      'userId': document.id,
    });
  }

  UserSavingsProfile copyWith({
    String? userId,
    String? phoneNumber,
    String? inviteCode,
    String? invitedBy,
    int? invitedFriendsCount,
    bool? referralRewardApplied,
    String? shareBaseUrl,
    String? inviteMessageTemplate,
  }) {
    return UserSavingsProfile(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      inviteCode: inviteCode ?? this.inviteCode,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedFriendsCount: invitedFriendsCount ?? this.invitedFriendsCount,
      referralRewardApplied:
          referralRewardApplied ?? this.referralRewardApplied,
      shareBaseUrl: shareBaseUrl ?? this.shareBaseUrl,
      inviteMessageTemplate:
          inviteMessageTemplate ?? this.inviteMessageTemplate,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'phoneNumber': phoneNumber,
      'referralCode': inviteCode,
      if (invitedBy.trim().isNotEmpty) 'invitedBy': invitedBy,
      'invitedCount': invitedFriendsCount,
      'referralRewardApplied': referralRewardApplied,
      'shareBaseUrl': shareBaseUrl,
      'inviteMessageTemplate': inviteMessageTemplate,
    };
  }
}
