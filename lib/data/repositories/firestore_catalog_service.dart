import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/models/coupon.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/comparison_search_cache_entry.dart';
import 'package:leastprice/data/models/automation_health_status.dart';
import 'package:leastprice/core/utils/helpers.dart';

class FirestoreCatalogService {
  const FirestoreCatalogService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      firestore.collection(LeastPriceDataConfig.productsCollectionName);
  CollectionReference<Map<String, dynamic>> get _adBannersCollection =>
      firestore.collection(LeastPriceDataConfig.adBannersCollectionName);
  CollectionReference<Map<String, dynamic>> get _exclusiveDealsCollection =>
      firestore.collection(LeastPriceDataConfig.exclusiveDealsCollectionName);
  CollectionReference<Map<String, dynamic>> get _couponsCollection =>
      firestore.collection(LeastPriceDataConfig.couponsCollectionName);
  CollectionReference<Map<String, dynamic>>
      get _comparisonSearchCacheCollection => firestore
          .collection(LeastPriceDataConfig.comparisonSearchCacheCollectionName);
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      firestore.collection(LeastPriceDataConfig.usersCollectionName);
  CollectionReference<Map<String, dynamic>> get _systemHealthCollection =>
      firestore.collection(LeastPriceDataConfig.systemHealthCollectionName);
  CollectionReference<Map<String, dynamic>> get _searchRequestsCollection =>
      firestore.collection(LeastPriceDataConfig.searchRequestsCollectionName);

  Stream<List<AdBannerItem>> watchAdBanners() {
    return _adBannersCollection.snapshots().map((snapshot) {
      final banners = snapshot.docs
          .map(AdBannerItem.fromFirestore)
          .where((banner) => banner.active && banner.imageUrl.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return banners;
    });
  }

  Stream<List<AdBannerItem>> watchAdminAdBanners() {
    return _adBannersCollection.snapshots().map((snapshot) {
      final banners = snapshot.docs.map(AdBannerItem.fromFirestore).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return banners;
    });
  }

  Stream<List<ExclusiveDeal>> watchExclusiveDeals() {
    return _exclusiveDealsCollection.snapshots().map((snapshot) {
      final now = DateTime.now();
      final deals = snapshot.docs
          .map((document) {
            try {
              return ExclusiveDeal.fromFirestore(document);
            } catch (error, stackTrace) {
              debugPrint(
                'LeastPrice exclusive deal parse skipped for ${document.id}: $error',
              );
              debugPrintStack(stackTrace: stackTrace);
              return null;
            }
          })
          .whereType<ExclusiveDeal>()
          .where(
            (deal) =>
                deal.active &&
                !deal.isExpiredAt(now) &&
                deal.title.trim().isNotEmpty &&
                deal.imageUrl.trim().isNotEmpty,
          )
          .toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return deals;
    });
  }

  Stream<List<ExclusiveDeal>> watchAdminExclusiveDeals() {
    return _exclusiveDealsCollection.snapshots().map((snapshot) {
      final deals = snapshot.docs
          .map((document) {
            try {
              return ExclusiveDeal.fromFirestore(document);
            } catch (error, stackTrace) {
              debugPrint(
                'LeastPrice admin exclusive deal parse skipped for ${document.id}: $error',
              );
              debugPrintStack(stackTrace: stackTrace);
              return null;
            }
          })
          .whereType<ExclusiveDeal>()
          .toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return deals;
    });
  }

  Stream<List<Coupon>> watchCoupons() {
    return _couponsCollection.snapshots().map((snapshot) {
      final now = DateTime.now();
      final coupons = snapshot.docs
          .map((document) {
            try {
              return Coupon.fromFirestore(document);
            } catch (error, stackTrace) {
              debugPrint(
                'LeastPrice coupon parse skipped for ${document.id}: $error',
              );
              debugPrintStack(stackTrace: stackTrace);
              return null;
            }
          })
          .whereType<Coupon>()
          .where(
            (coupon) =>
                coupon.active &&
                !coupon.isExpiredAt(now) &&
                coupon.code.trim().isNotEmpty &&
                coupon.storeId.trim().isNotEmpty,
          )
          .toList()
        ..sort(_sortCoupons);
      return coupons;
    });
  }

  Stream<List<Coupon>> watchFeaturedCoupons() {
    return watchCoupons().map((coupons) {
      return coupons
          .where((coupon) => coupon.isSupportedFeaturedStore)
          .toList();
    });
  }

  Stream<UserSavingsProfile?> watchUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return UserSavingsProfile.fromFirestore(snapshot);
    });
  }

  Stream<List<UserSavingsProfile>> watchAdminUserProfiles() {
    return _usersCollection.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map(UserSavingsProfile.fromFirestore)
          .where((profile) => profile.userId.trim().isNotEmpty)
          .toList()
        ..sort((a, b) {
          if (a.planActivated != b.planActivated) {
            return a.planActivated ? -1 : 1;
          }
          return a.phoneNumber.compareTo(b.phoneNumber);
        });
      return users;
    });
  }

  Future<void> setUserPlanActivation({
    required String userId,
    required bool planActivated,
    String? planStatus,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const FormatException('Missing user id');
    }

    await _usersCollection.doc(normalizedUserId).set(
      {
        'planActivated': planActivated,
        'planStatus': (planStatus ?? (planActivated ? 'active' : 'inactive')).trim(),
        'planUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setUserAdminRole({
    required String userId,
    required String adminRole,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const FormatException('Missing user id');
    }

    final normalizedRole = adminRole.trim().toLowerCase();
    if (normalizedRole.isEmpty) {
      throw const FormatException('Missing admin role');
    }

    await _usersCollection.doc(normalizedUserId).set(
      {
        'adminRole': normalizedRole,
        'adminRoleUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<AutomationHealthStatus?> watchSystemHealth() {
    return _systemHealthCollection
        .doc(LeastPriceDataConfig.systemHealthDocumentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return AutomationHealthStatus.fromJson(snapshot.data() ?? const {});
    });
  }

  Future<ComparisonSearchCacheEntry?> fetchComparisonSearchCache(
    String query, {
    String? locationKey,
    String? targetStoreId,
  }) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.length < 2) {
      return null;
    }

    final documentId = _buildComparisonSearchCacheDocumentId(
      normalizedQuery,
      locationKey: locationKey,
      targetStoreId: targetStoreId,
    );
    final snapshot =
        await _comparisonSearchCacheCollection.doc(documentId).get();
    if (!snapshot.exists) {
      return null;
    }

    return ComparisonSearchCacheEntry.fromJson(snapshot.data() ?? const {});
  }

  Future<void> saveComparisonSearchCache({
    required String query,
    required List<ComparisonSearchResult> results,
    String? locationKey,
    String? locationLabel,
    String? targetStoreId,
  }) async {
    final normalizedQuery = normalizeArabic(query);
    if (normalizedQuery.length < 2 || results.isEmpty) {
      return;
    }

    final documentId = _buildComparisonSearchCacheDocumentId(
      normalizedQuery,
      locationKey: locationKey,
      targetStoreId: targetStoreId,
    );
    await _comparisonSearchCacheCollection.doc(documentId).set({
      'query': query.trim(),
      'normalizedQuery': normalizedQuery,
      if ((locationKey ?? '').trim().isNotEmpty) 'locationKey': locationKey,
      if ((locationLabel ?? '').trim().isNotEmpty)
        'locationLabel': locationLabel,
      if ((targetStoreId ?? '').trim().isNotEmpty) 'targetStoreId': targetStoreId,
      'cachedAt': Timestamp.fromDate(DateTime.now()),
      'results': results.map((result) => result.toJson()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserSavingsProfile> ensureUserProfile({
    required User user,
    String? pendingInviteCode,
    String? requiredPhoneNumber,
    String? emailAddress,
  }) async {
    final userDocument = _usersCollection.doc(user.uid);
    final snapshot = await userDocument.get();
    final phoneNumber = requiredPhoneNumber?.trim().isNotEmpty == true
        ? requiredPhoneNumber!.trim()
        : (user.phoneNumber?.trim() ?? '');
    final email = emailAddress?.trim().isNotEmpty == true
        ? emailAddress!.trim()
        : (user.email?.trim() ?? '');

    if (snapshot.exists) {
      final currentProfile = UserSavingsProfile.fromFirestore(snapshot);
      String inviteCode = currentProfile.inviteCode;
      if (inviteCode.trim().isEmpty) {
        inviteCode = _buildReferralCodeFromUserId(user.uid);
      }

      await userDocument.set(
        {
          'phoneNumber':
              phoneNumber.isNotEmpty ? phoneNumber : currentProfile.phoneNumber,
          'referralCode': inviteCode,
          if (email.isNotEmpty) 'email': email,
          'shareBaseUrl': currentProfile.shareBaseUrl,
          'inviteMessageTemplate': currentProfile.inviteMessageTemplate,
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return currentProfile.copyWith(
        userId: user.uid,
        phoneNumber:
            phoneNumber.isNotEmpty ? phoneNumber : currentProfile.phoneNumber,
        inviteCode: inviteCode,
      );
    }

    final referralCode = _buildReferralCodeFromUserId(user.uid);
    final normalizedInviteCode = pendingInviteCode?.trim().toUpperCase() ?? '';
    final invitedBy =
        normalizedInviteCode.isNotEmpty && normalizedInviteCode != referralCode
            ? normalizedInviteCode
            : '';

    final profile = UserSavingsProfile(
      userId: user.uid,
      phoneNumber: phoneNumber,
      inviteCode: referralCode,
      invitedBy: invitedBy,
      invitedFriendsCount: 0,
      referralRewardApplied: false,
      shareBaseUrl: LeastPriceDataConfig.appShareUrl,
      inviteMessageTemplate:
          'أنا وفرت {SAVED_AMOUNT} ريال باستخدام تطبيق أرخص سعر! '
          'حمل التطبيق الآن واستخدم كود الدعوة الخاص بي: {USER_CODE}\n{APP_LINK}',
      planActivated: false,
      planStatus: 'inactive',
      adminRole: 'user',
    );

    await userDocument.set(
      {
        ...profile.toFirestoreMap(),
        if (email.isNotEmpty) 'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return profile;
  }

  Stream<List<ProductComparison>> watchProducts({
    String? categoryId,
  }) {
    final normalizedCategoryId = categoryId?.trim() ?? '';
    return _productsCollection.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map(ProductComparison.fromFirestore)
          .where(
            (product) =>
                product.isAutomated &&
                product.expensiveName.trim().isNotEmpty &&
                product.alternativeName.trim().isNotEmpty &&
                (normalizedCategoryId.isEmpty ||
                    normalizedCategoryId == ProductCategoryCatalog.allId ||
                    product.categoryId == normalizedCategoryId),
          )
          .toList()
        ..sort(_sortProducts);

      return products;
    });
  }

  Stream<List<ProductComparison>> watchAllProducts() {
    return watchProducts();
  }

  Future<void> refreshProductsFromServer() async {
    await _productsCollection.get(const GetOptions(source: Source.server));
  }

  Future<void> addProduct(ProductComparison product) async {
    await _productsCollection.add({
      ...product.toFirestoreMap(),
      'is_automated': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAdBanner(AdBannerItem banner) async {
    final data = {
      ...banner.toFirestoreMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (banner.id.trim().isEmpty) {
      await _adBannersCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _adBannersCollection.doc(banner.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> publishAdBanner(String bannerId) async {
    await _adBannersCollection.doc(bannerId).set(
      {
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteAdBanner(String bannerId) async {
    await _adBannersCollection.doc(bannerId).delete();
  }

  Future<void> saveProduct(ProductComparison product) async {
    final data = {
      'expensiveName': product.expensiveName,
      'expensivePrice': product.expensivePrice,
      'expensiveImageUrl': product.expensiveImageUrl,
      'alternativeName': product.alternativeName,
      'alternativePrice': product.alternativePrice,
      'alternativeImageUrl': product.alternativeImageUrl,
      'buyUrl': product.buyUrl.trim().isEmpty
          ? ''
          : AffiliateLinkService.attachAffiliateTag(product.buyUrl),
      'category': product.categoryLabel,
      'categoryId': product.categoryId,
      'is_automated': product.isAutomated,
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'tags': product.tags,
      'fragranceNotes': product.fragranceNotes ?? '',
      'activeIngredients': product.activeIngredients ?? '',
      'localLocationLabel': product.localLocationLabel ?? '',
      'localLocationUrl': product.localLocationUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    final documentId = product.documentId?.trim() ?? '';
    if (documentId.isEmpty) {
      await _productsCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _productsCollection.doc(documentId).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> publishProduct(String documentId) async {
    await _productsCollection.doc(documentId).set(
      {
        'is_automated': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveExclusiveDeal(
    ExclusiveDeal deal, {
    String? editorUserId,
    String? editorEmail,
  }) async {
    final normalizedEditorUid = (editorUserId ?? '').trim();
    final normalizedEditorEmail = (editorEmail ?? '').trim().toLowerCase();
    final hasEditorIdentity =
        normalizedEditorUid.isNotEmpty || normalizedEditorEmail.isNotEmpty;
    final data = {
      ...deal.toFirestoreMap(),
      if (hasEditorIdentity) 'lastUpdatedByUid': normalizedEditorUid,
      if (hasEditorIdentity) 'lastUpdatedByEmail': normalizedEditorEmail,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (deal.id.trim().isEmpty) {
      await _exclusiveDealsCollection.add({
        ...data,
        if (hasEditorIdentity) 'createdByUid': normalizedEditorUid,
        if (hasEditorIdentity) 'createdByEmail': normalizedEditorEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _exclusiveDealsCollection.doc(deal.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> publishExclusiveDeal(
    String dealId, {
    String? editorUserId,
    String? editorEmail,
  }) async {
    final normalizedEditorUid = (editorUserId ?? '').trim();
    final normalizedEditorEmail = (editorEmail ?? '').trim().toLowerCase();
    final hasEditorIdentity =
        normalizedEditorUid.isNotEmpty || normalizedEditorEmail.isNotEmpty;
    await _exclusiveDealsCollection.doc(dealId).set(
      {
        if (hasEditorIdentity) 'lastUpdatedByUid': normalizedEditorUid,
        if (hasEditorIdentity) 'lastUpdatedByEmail': normalizedEditorEmail,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteExclusiveDeal(String dealId) async {
    await _exclusiveDealsCollection.doc(dealId).delete();
  }

  Future<void> deleteProduct(String documentId) async {
    await _productsCollection.doc(documentId).delete();
  }

  Future<void> submitSearchRequest({
    required String query,
    required String categoryId,
  }) async {
    final trimmedQuery = query.trim();
    final normalizedQuery = normalizeArabic(trimmedQuery);
    if (normalizedQuery.length < 2) {
      return;
    }

    final normalizedCategoryId = categoryId.trim().isEmpty
        ? ProductCategoryCatalog.allId
        : categoryId.trim();
    final categoryLabel =
        ProductCategoryCatalog.lookup(normalizedCategoryId).label;
    final documentId = _buildSearchRequestDocumentId(
      normalizedQuery: normalizedQuery,
      categoryId: normalizedCategoryId,
    );
    final requestDocument = _searchRequestsCollection.doc(documentId);
    final createPayload = {
      'query': trimmedQuery,
      'normalizedQuery': normalizedQuery,
      'categoryId': normalizedCategoryId,
      'categoryLabel': categoryLabel,
      'requestCount': 1,
      'status': 'pending',
      'source': 'app_search',
      'firstRequestedAt': FieldValue.serverTimestamp(),
      'lastRequestedAt': FieldValue.serverTimestamp(),
    };

    try {
      await requestDocument.update({
        'query': trimmedQuery,
        'normalizedQuery': normalizedQuery,
        'categoryId': normalizedCategoryId,
        'categoryLabel': categoryLabel,
        'requestCount': FieldValue.increment(1),
        'status': 'pending',
        'source': 'app_search',
        'lastRequestedAt': FieldValue.serverTimestamp(),
      });
      return;
    } on FirebaseException catch (error) {
      if (error.code != 'not-found') {
        rethrow;
      }
    }

    await requestDocument.set(createPayload, SetOptions(merge: true));
  }

  Future<void> submitRating(
    ProductComparison product,
    double userRating,
  ) async {
    final documentId = product.documentId;
    if (documentId == null || documentId.trim().isEmpty) {
      throw const FormatException('Missing Firestore document id');
    }

    final document = _productsCollection.doc(documentId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        throw const FormatException('Product does not exist');
      }

      final current = ProductComparison.fromFirestore(snapshot);
      final updated = current.withUserRating(userRating);

      transaction.update(document, {
        'rating': updated.rating,
        'reviewCount': updated.reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  int _sortProducts(ProductComparison a, ProductComparison b) {
    final categoryCompare = a.categoryLabel.compareTo(b.categoryLabel);
    if (categoryCompare != 0) {
      return categoryCompare;
    }

    return b.savingsPercent.compareTo(a.savingsPercent);
  }

  int _sortCoupons(Coupon a, Coupon b) {
    final discountCompare = (b.discountPercent ?? -1).compareTo(
      a.discountPercent ?? -1,
    );
    if (discountCompare != 0) {
      return discountCompare;
    }

    final expiryCompare = a.expiresAt.compareTo(b.expiresAt);
    if (expiryCompare != 0) {
      return expiryCompare;
    }

    return a.code.compareTo(b.code);
  }

  String _buildSearchRequestDocumentId({
    required String normalizedQuery,
    required String categoryId,
  }) {
    return '$categoryId--${normalizedQuery.replaceAll('/', '_')}';
  }

  String _buildComparisonSearchCacheDocumentId(
    String normalizedQuery, {
    String? locationKey,
    String? targetStoreId,
  }) {
    final normalizedLocation = (locationKey ?? '').trim().isEmpty
        ? 'saudi_arabia'
        : locationKey!.trim().toLowerCase();
    final safeQuery = normalizedQuery.replaceAll(
      RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]+'),
      '_',
    );
    final safeLocation = normalizedLocation.replaceAll(
      RegExp(r'[^a-zA-Z0-9_]+'),
      '_',
    );
    final safeStore = (targetStoreId ?? '').trim().isEmpty 
        ? 'all' 
        : targetStoreId!.trim().toLowerCase();
    return '$safeLocation--$safeStore--$safeQuery';
  }

  String _buildReferralCodeFromUserId(String userId) {
    final normalized =
        userId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final padded = normalized.padRight(10, 'X');
    final first = padded.substring(0, 5);
    final second = padded.substring(5, 10);
    return 'LP-$first-$second';
  }
}
