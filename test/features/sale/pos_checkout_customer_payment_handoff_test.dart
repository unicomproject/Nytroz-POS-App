import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/data/datasources/pos_checkout_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

void main() {
  const line = PosCheckoutLineRequest(variantId: 'variant-1', quantity: 1);

  test('selected customer and existing idempotency key reach start-payment',
      () async {
    final requests = <Map<String, dynamic>>[];
    final datasource = PosCheckoutRemoteDatasource(_dio(requests));

    await datasource.startPayment(
      deviceId: 'device-1',
      paymentMethod: 'cash',
      lines: const [line],
      cashReceived: 3000,
      customerId: 'customer-selected',
      idempotencyKey: 'stable-payment-key',
    );

    expect(requests.single['customerId'], 'customer-selected');
    expect(requests.single['idempotencyKey'], 'stable-payment-key');
  });

  test('latest changed customer is used without duplicated customer state',
      () async {
    final requests = <Map<String, dynamic>>[];
    final datasource = PosCheckoutRemoteDatasource(_dio(requests));

    for (final customerId in ['customer-old', 'customer-latest']) {
      await datasource.startPayment(
        deviceId: 'device-1',
        paymentMethod: 'cash',
        lines: const [line],
        cashReceived: 3000,
        customerId: customerId,
        idempotencyKey: 'key-$customerId',
      );
    }

    expect(requests.last['customerId'], 'customer-latest');
  });

  test('walk-in start-payment omits customerId', () async {
    final requests = <Map<String, dynamic>>[];
    final datasource = PosCheckoutRemoteDatasource(_dio(requests));

    await datasource.startPayment(
      deviceId: 'device-1',
      paymentMethod: 'cash',
      lines: const [line],
      cashReceived: 3000,
      idempotencyKey: 'walk-in-key',
    );

    expect(requests.single.containsKey('customerId'), isFalse);
  });

  test('customer validation failure preserves canonical cart and customer',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(posNewSaleCartProvider.notifier);
    cart.addToCart(_product);
    cart.setCustomer(_customer);
    final before = container.read(posNewSaleCartProvider);
    final datasource = PosCheckoutRemoteDatasource(_dio([], reject: true));

    await expectLater(
      datasource.startPayment(
        deviceId: 'device-1',
        paymentMethod: 'cash',
        lines: const [line],
        cashReceived: 3000,
        customerId: before.selectedCustomer!.customerId,
        idempotencyKey: 'rejected-key',
      ),
      throwsA(isA<PosCheckoutApiException>()),
    );

    final after = container.read(posNewSaleCartProvider);
    expect(after.selectedCustomer, same(before.selectedCustomer));
    expect(after.items, same(before.items));
    expect(after.total, before.total);
  });
}

Dio _dio(List<Map<String, dynamic>> requests, {bool reject = false}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests.add(Map<String, dynamic>.from(options.data as Map));
    if (reject) {
      return handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 400,
          data: const {
            'code': 'pos_checkout.customer_not_found',
            'message': 'The selected customer could not be found.',
          },
        ),
      ));
    }
    handler.resolve(Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: 200,
      data: const {
        'data': {
          'saleId': 'sale-1',
          'saleNumber': 'SO-000001',
          'paymentMethod': 'cash',
          'currency': 'LKR',
        },
      },
    ));
  }));
  return dio;
}

const _customer = PosCustomer(
  customerId: 'customer-selected',
  fullName: 'Selected Customer',
  phone: '+94770000000',
  status: 'ACTIVE',
);

const _product = PosNewSaleProduct(
  id: 'product-1',
  productId: 'product-1',
  variantId: 'variant-1',
  name: 'Match Shorts',
  category: 'Apparel',
  price: 2800,
  stockStatus: 'InStock',
);
