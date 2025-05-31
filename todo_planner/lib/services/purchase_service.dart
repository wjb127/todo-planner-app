import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'ad_service.dart';

class PurchaseService {
  static const String removeAdsProductId = 'remove_ads_11000'; // 실제 상품 ID로 변경 필요
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static late StreamSubscription<List<PurchaseDetails>> _subscription;
  static bool _isAvailable = false;
  static List<ProductDetails> _products = [];

  // 인앱결제 초기화
  static Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (!_isAvailable) {
      print('InAppPurchase is not available');
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    // 구매 상태 변경 리스너 설정
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // 상품 정보 로드
    await _loadProducts();
    
    // 미완료 구매 복원
    await _restorePurchases();
  }

  // 상품 정보 로드
  static Future<void> _loadProducts() async {
    if (!_isAvailable) return;

    const Set<String> productIds = {removeAdsProductId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
  }

  // 광고 제거 구매
  static Future<void> purchaseRemoveAds() async {
    if (!_isAvailable || _products.isEmpty) {
      print('Purchase not available or products not loaded');
      return;
    }

    final ProductDetails productDetails = _products.firstWhere(
      (product) => product.id == removeAdsProductId,
      orElse: () => throw Exception('Product not found'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // 구매 상태 업데이트 처리
  static Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 구매 대기 중
        print('Purchase pending');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // 구매 실패
        print('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        // 구매 성공 또는 복원
        if (purchaseDetails.productID == removeAdsProductId) {
          await AdService.setAdRemoved(true);
          print('Ads removed successfully');
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // 구매 복원
  static Future<void> _restorePurchases() async {
    if (!_isAvailable) return;
    await _inAppPurchase.restorePurchases();
  }

  // 구매 복원 (사용자가 직접 호출)
  static Future<void> restorePurchases() async {
    await _restorePurchases();
  }

  // 상품 가격 가져오기
  static String getRemoveAdsPrice() {
    if (_products.isEmpty) return '₩11,000';
    
    final product = _products.firstWhere(
      (product) => product.id == removeAdsProductId,
      orElse: () => throw Exception('Product not found'),
    );
    
    return product.price;
  }

  // 리소스 정리
  static void dispose() {
    _subscription.cancel();
  }
}

// iOS 결제 큐 델리게이트
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
} 