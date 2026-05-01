import 'dart:async';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leastprice/core/theme/app_palette.dart';
import 'package:leastprice/core/config/least_price_data_config.dart';
import 'package:leastprice/data/models/user_savings_profile.dart';
import 'package:leastprice/data/models/automation_health_status.dart';
import 'package:leastprice/data/models/comparison_search_result.dart';
import 'package:leastprice/data/models/ad_banner_item.dart';
import 'package:leastprice/data/models/product_category_catalog.dart';
import 'package:leastprice/data/models/exclusive_deal.dart';
import 'package:leastprice/data/models/product_comparison.dart';
import 'package:leastprice/data/models/coupon.dart';
import 'package:leastprice/services/api/serp_api_shopping_search_service.dart';
import 'package:leastprice/services/api/affiliate_link_service.dart';
import 'package:leastprice/data/repositories/firestore_catalog_service.dart';
import 'package:leastprice/data/repositories/product_repository.dart';
import 'package:leastprice/core/utils/helpers.dart';
import 'home_exports.dart';
import 'package:leastprice/features/admin/admin_exports.dart';

class LeastPriceHomePage extends StatefulWidget {
  const LeastPriceHomePage({
    super.key,
    required this.firebaseReady,
    required this.currentUser,
    required this.initialUserProfile,
    this.bootstrapNotice,
  });

  final bool firebaseReady;
  final User currentUser;
  final UserSavingsProfile initialUserProfile;
  final String? bootstrapNotice;

  @override
  State<LeastPriceHomePage> createState() => _LeastPriceHomePageState();
}

class _LeastPriceHomePageState extends State<LeastPriceHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreCatalogService _catalogService =
      const FirestoreCatalogService();
  final ProductRepository _fallbackRepository = const ProductRepository();
  final SerpApiShoppingSearchService _comparisonSearchService =
      const SerpApiShoppingSearchService();
  final Connectivity _connectivity = Connectivity();
  late Stream<List<ProductComparison>> _productsStream;
  StreamSubscription<dynamic>? _connectivitySubscription;
  StreamSubscription<UserSavingsProfile?>? _userProfileSubscription;
  StreamSubscription<List<AdBannerItem>>? _bannerSubscription;
  StreamSubscription<List<Coupon>>? _couponSubscription;
  StreamSubscription<AutomationHealthStatus?>? _systemHealthSubscription;
  Timer? _smartSearchDebounce;
  String _query = '';
  final String _selectedCategoryId = ProductCategoryCatalog.allId;
  MarketplaceSearchCity _selectedSearchCity = marketplaceSearchCities.first;
  HomeCatalogSection _selectedHomeSection = HomeCatalogSection.comparisons;
  bool _hasInternet = true;
  bool _isRefreshing = false;
  bool _isSearchingOnline = false;
  bool _isDetectingCity = false;
  String? _smartSearchNotice;
  String _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
  ProductDataSource _dataSource = ProductDataSource.remote;
  UserSavingsProfile _userProfile = UserSavingsProfile.initial();
  AutomationHealthStatus _systemHealth = AutomationHealthStatus.initial();
  List<AdBannerItem> _activeBanners = AdBannerItem.mockData;
  List<Coupon> _activeCoupons = const <Coupon>[];
  List<ComparisonSearchResult> _comparisonSearchResults =
      const <ComparisonSearchResult>[];
  static const int _trialVisibleResultsCount = 5;

  bool get _isPaidPlanActive => _userProfile.planActivated;
  bool get _isPrimaryAdmin =>
      (widget.currentUser.email ?? '').trim().toLowerCase() ==
      LeastPriceDataConfig.adminEmail.toLowerCase();
  bool get _canAccessAdminPanel =>
      _isPrimaryAdmin || _userProfile.isMarketingManager;

  void _handleFirestoreSubscriptionError(
    String label,
    Object error,
    StackTrace stackTrace, {
    VoidCallback? fallback,
  }) {
    debugPrint('LeastPrice $label stream failed: $error');
    if (stackTrace != StackTrace.empty) {
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      fallback?.call();
    });
  }

  void _handleFirestorePermissionAwareError(
    String label,
    Object error,
    StackTrace stackTrace, {
    VoidCallback? fallback,
  }) {
    if (error is FirebaseException &&
        error.plugin == 'cloud_firestore' &&
        error.code == 'permission-denied') {
      _handleFirestoreSubscriptionError(
        '$label permission',
        error,
        stackTrace,
        fallback: fallback,
      );
      return;
    }

    _handleFirestoreSubscriptionError(
      label,
      error,
      stackTrace,
      fallback: fallback,
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _userProfile = widget.initialUserProfile;
    _dataSource = widget.firebaseReady
        ? ProductDataSource.remote
        : ProductDataSource.asset;
    _productsStream = _buildProductsStream();

    if (widget.firebaseReady) {
      _userProfileSubscription = _catalogService
          .watchUserProfile(widget.currentUser.uid)
          .listen((profile) {
        if (!mounted || profile == null) {
          return;
        }
        setState(() {
          _userProfile = profile;
        });
      }, onError: (Object error, StackTrace stackTrace) {
        _handleFirestorePermissionAwareError(
          'user profile',
          error,
          stackTrace,
        );
      });
      _bannerSubscription = _catalogService.watchAdBanners().listen((banners) {
        if (!mounted) {
          return;
        }
        setState(() {
          _activeBanners = banners.isEmpty ? AdBannerItem.mockData : banners;
        });
      }, onError: (Object error, StackTrace stackTrace) {
        _handleFirestorePermissionAwareError(
          'ad banners',
          error,
          stackTrace,
          fallback: () {
            _activeBanners = AdBannerItem.mockData;
          },
        );
      });
      _couponSubscription = _catalogService.watchFeaturedCoupons().listen((
        coupons,
      ) {
        if (!mounted) {
          return;
        }
        setState(() {
          _activeCoupons = coupons;
          _comparisonSearchResults = _attachCouponsToSearchResults(
            _comparisonSearchResults,
          );
        });
      }, onError: (Object error, StackTrace stackTrace) {
        _handleFirestorePermissionAwareError(
          'featured coupons',
          error,
          stackTrace,
          fallback: () {
            _activeCoupons = const <Coupon>[];
            _comparisonSearchResults = _attachCouponsToSearchResults(
              _comparisonSearchResults,
            );
          },
        );
      });
      _systemHealthSubscription = _catalogService.watchSystemHealth().listen((
        status,
      ) {
        if (!mounted || status == null) {
          return;
        }
        setState(() {
          _systemHealth = status;
        });
      }, onError: (Object error, StackTrace stackTrace) {
        _handleFirestorePermissionAwareError(
          'system health',
          error,
          stackTrace,
          fallback: () {
            _systemHealth = AutomationHealthStatus.initial();
          },
        );
      });
      unawaited(_setupConnectivityMonitoring());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_detectCityFromCurrentLocation(showFeedback: false));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_refreshCatalog(showSuccessMessage: false));
      });
    }
  }

  Future<void> _detectCityFromCurrentLocation({
    bool showFeedback = true,
  }) async {
    if (_isDetectingCity || !mounted) {
      return;
    }
    setState(() {
      _isDetectingCity = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  'خدمة الموقع غير مفعلة. فعّل GPS ثم حاول مرة أخرى.',
                  'Location services are disabled. Enable GPS and try again.',
                ),
              ),
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr(
                  'تم رفض إذن الموقع. يمكنك اختيار المدينة يدويًا.',
                  'Location permission was denied. You can choose the city manually.',
                ),
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return;
      }

      final cityTokens = <String>[
        placemarks.first.locality ?? '',
        placemarks.first.subAdministrativeArea ?? '',
        placemarks.first.administrativeArea ?? '',
      ].map(normalizeArabic).where((value) => value.isNotEmpty).toList();

      MarketplaceSearchCity? detectedCity;
      for (final city in marketplaceSearchCities) {
        final cityLabel = normalizeArabic(city.arLabel);
        final cityLabelEn = normalizeArabic(city.enLabel);
        final cityId = normalizeArabic(city.id.replaceAll('_', ' '));
        final isMatch = cityTokens.any(
          (token) =>
              token.contains(cityLabel) ||
              cityLabel.contains(token) ||
              token.contains(cityLabelEn) ||
              token.contains(cityId),
        );
        if (isMatch) {
          detectedCity = city;
          break;
        }
      }

      if (detectedCity == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedSearchCity = detectedCity!;
      });

      if (_query.trim().isNotEmpty && _hasInternet) {
        await _runSmartSearch(_query, forceRefresh: true);
      }

      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تم تحديد المدينة تلقائيًا: ${detectedCity.label}',
                'City detected automatically: ${detectedCity.label}',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تعذر تحديد المدينة تلقائيًا الآن. اختر المدينة يدويًا.',
                'Unable to detect city automatically right now. Choose city manually.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingCity = false;
        });
      }
    }
  }

  Stream<List<ProductComparison>> _loadFallbackProducts() async* {
    try {
      final result = await _fallbackRepository.loadProducts();
      if (mounted) {
        setState(() {
          _userProfile = result.referralProfile ?? _userProfile;
          _dataSource = result.source;
        });
      }

      yield result.products;
    } catch (error) {
      debugPrint('LeastPrice fallback catalog failed: $error');
      if (mounted) {
        setState(() {
          _dataSource = ProductDataSource.mock;
        });
      }

      yield ProductComparison.mockData;
    }
  }

  Stream<List<ProductComparison>> _buildProductsStream() {
    if (!widget.firebaseReady) {
      return _loadFallbackProducts();
    }

    return _catalogService.watchProducts(
      categoryId: _selectedCategoryId,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _userProfileSubscription?.cancel();
    _bannerSubscription?.cancel();
    _couponSubscription?.cancel();
    _systemHealthSubscription?.cancel();
    _smartSearchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _setupConnectivityMonitoring() async {
    try {
      final initialStatus = await _connectivity.checkConnectivity();
      if (!mounted) return;
      _handleConnectivityChange(initialStatus, showFeedback: false);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (dynamic status) {
          _handleConnectivityChange(status, showFeedback: true);
        },
      );
    } catch (_) {
      if (!mounted) return;
    }
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text;
    setState(() {
      _query = nextQuery;
      if (nextQuery.trim().isNotEmpty) {
        _selectedHomeSection = HomeCatalogSection.comparisons;
      }
    });

    _scheduleSmartSearch(nextQuery);
  }

  void _clearSearch() {
    _searchController.clear();
  }

  Future<void> _submitComparisonSearch(String rawQuery) async {
    _smartSearchDebounce?.cancel();
    final nextQuery = rawQuery.trim();
    if (nextQuery.isEmpty || !_hasInternet) {
      _clearSmartSearchState();
      return;
    }

    if (mounted) {
      setState(() {
        _query = rawQuery;
        _selectedHomeSection = HomeCatalogSection.comparisons;
      });
    }

    await _runSmartSearch(nextQuery, forceRefresh: true);
  }

  void _selectSearchCity(String cityId) {
    final nextCity = marketplaceSearchCityById(cityId);
    if (nextCity.id == _selectedSearchCity.id) {
      return;
    }

    setState(() {
      _selectedSearchCity = nextCity;
      _selectedHomeSection = HomeCatalogSection.comparisons;
    });

    if (_query.trim().isNotEmpty && _hasInternet) {
      unawaited(_runSmartSearch(_query, forceRefresh: true));
    }
  }

  void _selectHomeSection(HomeCatalogSection section) {
    if (_selectedHomeSection == section) {
      return;
    }

    setState(() {
      _selectedHomeSection = section;
    });
  }

  void _scheduleSmartSearch(String rawQuery) {
    _smartSearchDebounce?.cancel();

    final normalizedQuery = normalizeArabic(rawQuery);
    if (normalizedQuery.isEmpty ||
        normalizedQuery.length < 2 ||
        !_hasInternet) {
      _clearSmartSearchState();
      return;
    }

    _smartSearchDebounce = Timer(const Duration(milliseconds: 650), () {
      unawaited(_runSmartSearch(rawQuery));
    });
  }

  void _clearSmartSearchState() {
    if (_comparisonSearchResults.isEmpty &&
        _smartSearchNotice == null &&
        !_isSearchingOnline) {
      return;
    }

    if (!mounted) {
      _comparisonSearchResults = const <ComparisonSearchResult>[];
      _smartSearchNotice = null;
      _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
      _isSearchingOnline = false;
      return;
    }

    setState(() {
      _comparisonSearchResults = const <ComparisonSearchResult>[];
      _smartSearchNotice = null;
      _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
      _isSearchingOnline = false;
    });
  }

  String _comparisonSearchFallbackMessage() {
    return tr(
      'عذراً، لم نجد نتائج حالياً',
      'Sorry, we could not find results right now.',
    );
  }

  Future<void> _performSerpSearch(
    String trimmedQuery, {
    bool forceRefresh = false,
  }) async {
    final result = await _comparisonSearchService.search(
      query: trimmedQuery,
      firebaseReady: widget.firebaseReady,
      forceRefresh: forceRefresh,
      city: _selectedSearchCity,
    );

    if (!mounted || normalizeArabic(trimmedQuery) != normalizeArabic(_query)) {
      return;
    }

    setState(() {
      final fullResults = _attachCouponsToSearchResults(result.results);
      final visibleResults = _isPaidPlanActive
          ? fullResults
          : fullResults.take(_trialVisibleResultsCount).toList(growable: false);
      _comparisonSearchResults = visibleResults;
      _smartSearchNotice = result.results.isEmpty
          ? _comparisonSearchFallbackMessage()
          : !_isPaidPlanActive && fullResults.length > _trialVisibleResultsCount
              ? tr(
                  'يتم عرض أول $_trialVisibleResultsCount نتائج فقط. بعد التحويل البنكي يتم تفعيل الخطة يدويًا وإظهار جميع الميزات.',
                  'Only the first $_trialVisibleResultsCount results are shown. After bank transfer, the plan is activated manually and all features are unlocked.',
                )
          : result.notice;
      _comparisonSearchSourceLabel = result.fromCache
          ? tr(
              'نتائج محفوظة • ${_selectedSearchCity.label}',
              'Cached results • ${_selectedSearchCity.label}',
            )
          : result.results.any((item) => item.isLiveDirect)
              ? tr(
                  'نتائج مباشرة • ${_selectedSearchCity.label}',
                  'Live results • ${_selectedSearchCity.label}',
                )
              : tr(
                  'بحث حي • ${_selectedSearchCity.label}',
                  'Live search • ${_selectedSearchCity.label}',
                );
    });
  }

  Future<void> _runSmartSearch(
    String rawQuery, {
    bool forceRefresh = false,
  }) async {
    final trimmedQuery = rawQuery.trim();
    if (trimmedQuery.isEmpty || !mounted || !_hasInternet) {
      _clearSmartSearchState();
      return;
    }

    setState(() {
      _isSearchingOnline = true;
      _smartSearchNotice = null;
    });

    try {
      await _performSerpSearch(trimmedQuery, forceRefresh: forceRefresh);
    } catch (error) {
      debugPrint('LeastPrice marketplace search failed: $error');
      if (!mounted ||
          normalizeArabic(trimmedQuery) != normalizeArabic(_query)) {
        return;
      }

      setState(() {
        _comparisonSearchResults = const <ComparisonSearchResult>[];
        _comparisonSearchSourceLabel = tr('بحث السوق', 'Market search');
        _smartSearchNotice = _comparisonSearchFallbackMessage();
      });
    } finally {
      if (mounted && normalizeArabic(trimmedQuery) == normalizeArabic(_query)) {
        setState(() {
          _isSearchingOnline = false;
        });
      }
    }
  }

  void _handleConnectivityChange(
    dynamic rawStatus, {
    required bool showFeedback,
  }) {
    final results = _normalizeConnectivityResults(rawStatus);
    final hasInternet = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (_hasInternet == hasInternet) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _hasInternet = hasInternet;
    });

    if (!showFeedback) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasInternet
              ? tr('تمت استعادة الاتصال بالشبكة.', 'Connection restored.')
              : tr('لا يوجد اتصال بالإنترنت حالياً.',
                  'No internet connection right now.'),
        ),
      ),
    );

    if (hasInternet) {
      unawaited(_refreshCatalog(showSuccessMessage: false));
      _scheduleSmartSearch(_query);
    } else {
      _clearSmartSearchState();
    }
  }

  List<ConnectivityResult> _normalizeConnectivityResults(dynamic rawStatus) {
    if (rawStatus is ConnectivityResult) {
      return [rawStatus];
    }

    if (rawStatus is List<ConnectivityResult>) {
      return rawStatus;
    }

    if (rawStatus is List) {
      return rawStatus.whereType<ConnectivityResult>().toList();
    }

    return const [ConnectivityResult.none];
  }

  Future<void> _refreshCatalog({bool showSuccessMessage = true}) async {
    if (!widget.firebaseReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'أكمل إعداد Firebase أولاً حتى يتمكن التطبيق من التحديث من Cloud Firestore.',
              'Complete the Firebase setup first so the app can refresh from Cloud Firestore.',
            ),
          ),
        ),
      );
      return;
    }

    if (!_hasInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'لا يوجد اتصال حالياً. سنعرض آخر البيانات المتاحة حتى تعود الشبكة.',
              'There is no connection right now. We will keep showing the latest available data until the network returns.',
            ),
          ),
        ),
      );
      return;
    }

    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _catalogService.refreshProductsFromServer();
      if (_query.trim().isNotEmpty) {
        await _runSmartSearch(_query, forceRefresh: true);
      }
      if (!mounted) return;

      if (showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تم تحديث قائمة المنتجات من الإنترنت بنجاح.',
                'Product list updated successfully from the internet.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              'تعذر الوصول إلى قاعدة البيانات حالياً. تحقق من الاتصال ثم أعد السحب.',
              'Unable to reach the database right now. Check your connection, then pull to refresh again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openExternalUrl(
    String url, {
    bool enforceSupportedStore = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isWhatsApp = AffiliateLinkService.looksLikeWhatsAppContact(url);

    try {
      final preparedUrl = enforceSupportedStore
          ? AffiliateLinkService.prepareForOpen(url)
          : url;
      final preparedUri = Uri.parse(preparedUrl);

      if (enforceSupportedStore &&
          !AffiliateLinkService.isSupportedStore(preparedUri)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'الرابط الحالي لا يوجّه إلى متجر سعودي مدعوم.',
                'This link does not point to a supported Saudi store.',
              ),
            ),
          ),
        );
        return;
      }

      final opened = await launchUrl(
        preparedUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              tr(
                isWhatsApp
                    ? 'تعذر فتح واتساب حالياً.'
                    : 'تعذر فتح رابط التواصل حالياً.',
                isWhatsApp
                    ? 'Unable to open WhatsApp right now.'
                    : 'Unable to open the contact link right now.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tr(
              isWhatsApp
                  ? 'رقم واتساب أو رابطه غير صالح حالياً.'
                  : 'رابط التواصل غير صالح أو غير متاح حالياً.',
              isWhatsApp
                  ? 'The WhatsApp number or link is invalid right now.'
                  : 'The contact link is invalid or unavailable right now.',
            ),
          ),
        ),
      );
    }
  }

  List<ComparisonSearchResult> _attachCouponsToSearchResults(
    List<ComparisonSearchResult> results,
  ) {
    return results
        .map(
          (result) => result.copyWith(
            matchedCoupon: _bestCouponForStore(result.storeId),
            clearMatchedCoupon: true,
          ),
        )
        .toList(growable: false);
  }

  Coupon? _bestCouponForStore(String storeId) {
    final normalizedStoreId = normalizeStoreIdToken(storeId);
    if (normalizedStoreId.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final matches = _activeCoupons
        .where(
          (coupon) =>
              normalizeStoreIdToken(coupon.storeId) == normalizedStoreId &&
              coupon.active &&
              !coupon.isExpiredAt(now),
        )
        .toList();
    if (matches.isEmpty) {
      return null;
    }

    matches.sort((a, b) {
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
    });
    return matches.first;
  }

  Future<void> _copyCouponCode(String code) async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: trimmedCode));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'تم نسخ الكود، سيتم تطبيقه عند الدفع.',
            'The code was copied and can be used at checkout.',
          ),
        ),
      ),
    );
  }

  double _estimatedInviteSavingsFor(List<ProductComparison> products) {
    if (products.isEmpty) {
      return 0;
    }

    final topSavings = [...products]
      ..sort((a, b) => b.savingsAmount.compareTo(a.savingsAmount));

    return topSavings
        .take(math.min(3, topSavings.length))
        .fold<double>(0, (total, item) => total + item.savingsAmount);
  }

  Future<void> _inviteFriend(List<ProductComparison> products) async {
    final inviteLink =
        '${_userProfile.shareBaseUrl}/invite/${_userProfile.inviteCode}';
    final savedAmount = formatAmountValue(_estimatedInviteSavingsFor(products));
    final message = _userProfile.inviteMessageTemplate
        .replaceAll('{SAVED_AMOUNT}', savedAmount)
        .replaceAll('{USER_CODE}', _userProfile.inviteCode)
        .replaceAll('{APP_LINK}', inviteLink);

    await Share.share(
      message,
      subject: tr(
        'ادعُ صديقاً للتوفير مع أرخص سعر',
        'Invite a friend to save with LeastPrice',
      ),
    );
  }

  Future<void> _openBanner(AdBannerItem banner) async {
    final contactUrl = LeastPriceDataConfig.adminWhatsAppUrl;
    await _openExternalUrl(contactUrl);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> _verifyLocalAdminPassword() async {
    final passwordController = TextEditingController();
    var obscurePassword = true;
    var hasError = false;

    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tr('دخول المسؤول', 'Admin access')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(
                      'أدخل كلمة المرور المحلية لفتح لوحة التحكم على الجوال.',
                      'Enter the local password to open the mobile admin center.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: tr('كلمة المرور', 'Password'),
                      errorText: hasError
                          ? tr(
                              'كلمة المرور غير صحيحة.',
                              'The password is incorrect.',
                            )
                          : null,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      final isValid = passwordController.text.trim() ==
                          LeastPriceDataConfig.adminPassword;
                      if (isValid) {
                        Navigator.of(context).pop(true);
                        return;
                      }
                      setDialogState(() {
                        hasError = true;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(tr('إلغاء', 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final isValid = passwordController.text.trim() ==
                        LeastPriceDataConfig.adminPassword;
                    if (isValid) {
                      Navigator.of(context).pop(true);
                      return;
                    }
                    setDialogState(() {
                      hasError = true;
                    });
                  },
                  child: Text(tr('دخول', 'Open')),
                ),
              ],
            );
          },
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      passwordController.dispose();
    });
    return allowed ?? false;
  }

  Future<void> _openAdminDashboard() async {
    final allowed = await _verifyLocalAdminPassword();
    if (!allowed || !mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminControlCenter(adminUser: widget.currentUser),
      ),
    );
  }

  void _showFirebaseSetupRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'التطبيق يحتاج تهيئة Firebase وCloud Firestore أولاً قبل استخدام قاعدة البيانات.',
            'The app needs Firebase and Cloud Firestore setup before using the database.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _canAccessAdminPanel
          ? FloatingActionButton.small(
              heroTag: 'admin-dashboard-fab',
              tooltip: tr('لوحة المسؤول', 'Admin panel'),
              backgroundColor: AppPalette.navy,
              foregroundColor: Colors.white,
              onPressed: widget.firebaseReady
                  ? _openAdminDashboard
                  : _showFirebaseSetupRequired,
              child: const Icon(Icons.admin_panel_settings_rounded),
            )
          : null,
      body: StreamBuilder<List<ProductComparison>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          final appleStyle = isAppleInterface(context);
          final products = snapshot.data ?? const <ProductComparison>[];
          final hasQuery = _query.trim().isNotEmpty;
          final showOffersSection =
              _selectedHomeSection == HomeCatalogSection.offers;
          final showComparisonsSection =
              _selectedHomeSection == HomeCatalogSection.comparisons;
          final showAboutSection =
              _selectedHomeSection == HomeCatalogSection.about;
          final comparisonResults = _comparisonSearchResults;
          final comparisonDataSourceLabel = showComparisonsSection
              ? _comparisonSearchSourceLabel
              : _dataSource.label;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: appleStyle
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF8F8FB), Color(0xFFF1F2F7)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppPalette.softOrange, Color(0xFFFFE7D1)],
                    ),
            ),
            child: RefreshIndicator(
              color: const Color(0xFFE8711A),
              onRefresh: _refreshCatalog,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: CompactHeaderSection(
                      currentUserLabel: _userProfile.phoneNumber.isNotEmpty
                          ? _userProfile.phoneNumber
                          : (widget.currentUser.email?.trim().isNotEmpty == true
                              ? widget.currentUser.email!.trim()
                              : tr('مستخدم موثّق', 'Verified user')),
                      inviteCode: _userProfile.inviteCode,
                      invitedFriendsCount: _userProfile.invitedFriendsCount,
                      systemHealthLabel: _systemHealth.statusLabel,
                      onInviteTap: () => _inviteFriend(products),
                      onLogoutTap: _signOut,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: HomeSectionSwitcher(
                        selectedSection: _selectedHomeSection,
                        onSectionSelected: _selectHomeSection,
                      ),
                    ),
                  ),
                  if (showComparisonsSection)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: ComparisonSearchBarSection(
                          searchController: _searchController,
                          query: _query,
                          resultsCount: comparisonResults.length,
                          dataSourceLabel: comparisonDataSourceLabel,
                          searchHintText: tr(
                            'ابحث عن أي منتج لمعرفة السعر الأقل',
                            'Search any product to find the lowest price',
                          ),
                          isSearchingOnline: _isSearchingOnline,
                          availableCities: marketplaceSearchCities,
                          selectedCityId: _selectedSearchCity.id,
                          onCitySelected: _selectSearchCity,
                          onClearSearch: _clearSearch,
                          onSubmitted: (value) {
                            unawaited(_submitComparisonSearch(value));
                          },
                          onDetectCityTap: () {
                            unawaited(
                              _detectCityFromCurrentLocation(showFeedback: true),
                            );
                          },
                        ),
                      ),
                    ),
                  if (showComparisonsSection && !_isPaidPlanActive)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: PlanPickerSection(
                          isPaidActive: _isPaidPlanActive,
                          visibleResultsCount: _trialVisibleResultsCount,
                          onWhatsAppTap: () => _openExternalUrl(
                            LeastPriceDataConfig.adminWhatsAppUrl,
                          ),
                        ),
                      ),
                    ),
                  if (!_hasInternet)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: StatusBanner(
                          icon: Icons.wifi_off_rounded,
                          title: tr('الاتصال غير متوفر', 'No connection'),
                          message: tr(
                            'سيعرض التطبيق آخر البيانات المحفوظة، وعند عودة الإنترنت يمكنك السحب للأسفل لتحديث الأسعار.',
                            'The app will show the latest saved data. Once the internet returns, pull down to refresh prices.',
                          ),
                          backgroundColor: AppPalette.softOrange,
                          borderColor: AppPalette.cardBorder,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    ),
                  if (!showComparisonsSection && !widget.firebaseReady)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: tr(
                            'Firebase غير مهيأ',
                            'Firebase is not configured',
                          ),
                          message: tr(
                            'أضف إعدادات Firebase وملفات Android ثم أعد تشغيل التطبيق ليبدأ جلب المنتجات من Cloud Firestore.',
                            'Add Firebase settings and Android files, then restart the app to start loading products from Cloud Firestore.',
                          ),
                          backgroundColor: AppPalette.softOrange,
                          borderColor: AppPalette.cardBorder,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    )
                  else if (!showComparisonsSection &&
                      snapshot.hasError &&
                      products.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: StatusBanner(
                          icon: Icons.cloud_off_rounded,
                          title: tr(
                            'تعذر قراءة البيانات',
                            'Unable to read data',
                          ),
                          message: tr(
                            'لم نتمكن من الوصول إلى Cloud Firestore حالياً. تأكد من إعداد القاعدة والاتصال بالشبكة ثم جرّب مرة أخرى.',
                            'We could not reach Cloud Firestore right now. Check the database setup and your network, then try again.',
                          ),
                          backgroundColor: AppPalette.softOrange,
                          borderColor: AppPalette.cardBorder,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: ExclusiveCouponsSection(
                        stream: widget.firebaseReady
                            ? _catalogService.watchFeaturedCoupons()
                            : Stream<List<Coupon>>.value(Coupon.mockData),
                        onCopyCoupon: _copyCouponCode,
                      ),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: ExclusiveDealsSection(
                        stream: widget.firebaseReady
                            ? _catalogService.watchExclusiveDeals()
                            : Stream<List<ExclusiveDeal>>.value(
                                ExclusiveDeal.mockData,
                              ),
                      ),
                    ),
                  if (showOffersSection)
                    SliverToBoxAdapter(
                      child: AdBannersSection(
                        banners: _activeBanners,
                        onBannerTap: _openBanner,
                      ),
                    ),
                  if (showAboutSection)
                    SliverToBoxAdapter(
                      child: AboutLeastPriceSection(
                        onContactTap: () => _openExternalUrl(
                          LeastPriceDataConfig.adminWhatsAppUrl,
                        ),
                      ),
                    ),
                  if (showComparisonsSection &&
                      !hasQuery &&
                      !_isSearchingOnline)
                    const SliverToBoxAdapter(child: SizedBox.shrink())
                  else if (showComparisonsSection &&
                      _isSearchingOnline &&
                      comparisonResults.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 32, 20, 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppPalette.comparisonEmerald,
                          ),
                        ),
                      ),
                    )
                  else if (showComparisonsSection && comparisonResults.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: ComparisonSearchPlaceholder(
                          title: _smartSearchNotice?.trim().isNotEmpty == true
                              ? _smartSearchNotice!
                              : _comparisonSearchFallbackMessage(),
                          icon: Icons.manage_search_rounded,
                        ),
                      ),
                    )
                  else if (showComparisonsSection)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final result = comparisonResults[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == comparisonResults.length - 1
                                    ? 0
                                    : 18,
                              ),
                              child: ComparisonSearchResultCard(
                                result: result,
                                onTap: () =>
                                    _openExternalUrl(result.productUrl),
                                onCopyCoupon: result.matchedCoupon == null
                                    ? null
                                    : () => _copyCouponCode(
                                          result.matchedCoupon!.code,
                                        ),
                              ),
                            );
                          },
                          childCount: comparisonResults.length,
                        ),
                      ),
                    ),
                  if (showComparisonsSection &&
                      _smartSearchNotice != null &&
                      comparisonResults.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _smartSearchNotice!,
                              style: const TextStyle(
                                color: AppPalette.softNavy,
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
