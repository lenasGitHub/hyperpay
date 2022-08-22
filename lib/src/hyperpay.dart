part of hyperpay;

class HyperpayPlugin {
  HyperpayPlugin._(this._config);

  static const MethodChannel _channel = const MethodChannel('hyperpay');

  late HyperpayConfig _config;

  CheckoutSettings? _checkoutSettings;
  String _checkoutID = '';

  HyperpayConfig get config => _config;

  static Future<HyperpayPlugin> setup({required HyperpayConfig config}) async {
    await _channel.invokeMethod(
      'setup_service',
      {
        'mode': config.paymentMode.string,
      },
    );

    return HyperpayPlugin._(config);
  }

  void initSession({required CheckoutSettings checkoutSetting}) async {
    _clearSession();
    _checkoutSettings = checkoutSetting;
  }

  void _clearSession() {
    if (_checkoutSettings != null) {
      _checkoutSettings?.clear();
    }
  }

  Future<String> get getCheckoutID async {
    try {
      final body = {
        'entityId': _checkoutSettings?.entityId,
        'amount': _checkoutSettings?.amount.toStringAsFixed(2),
        ..._checkoutSettings?.additionalParams ?? {},
      };

      final Response response = await post(
        _config.checkoutEndpoint,
        headers: _checkoutSettings?.headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw HttpException('${response.statusCode}: ${response.body}');
      }

      final Map _resBody = json.decode(response.body);

      if (_resBody['result'] != null && _resBody['result']['code'] != null) {
        switch (_resBody['result']['code']) {
          case '000.200.100':
            _checkoutID = _resBody['id'];
            break;
          case '200.300.404':
            throw HyperpayException(
              _resBody['description'],
              _resBody['code'],
              _resBody.containsKey('parameterErrors')
                  ? _resBody['parameterErrors']
                      .map(
                        (param) =>
                            '(param: ${param['name']}, value: ${param['value']})',
                      )
                      .join(',')
                  : '',
            );
          default:
            throw HyperpayException(
              _resBody['description'],
              _resBody['code'],
            );
        }

        log(_checkoutID, name: "HyperpayPlugin/getCheckoutID");

        return _checkoutID;
      } else {
        throw HyperpayException(
          'The returned result does not contain the key "result" as the first key.',
          'RESPONSE BODY NOT IDENTIFIED',
          'please structure the returned body as {result: {code: CODE, description: DESCRIPTION}, id: CHECKOUT_ID, ...}.',
        );
      }
    } catch (exception) {
      log('${exception.toString()}', name: "HyperpayPlugin/getCheckoutID");
      rethrow;
    }
  }

  Future<PaymentSuccess> pay(CardInfo card, urlStatus) async {
    try {
      final result = await _channel.invokeMethod(
        'start_payment_transaction',
        {
          'checkoutID': _checkoutID,
          'brand': _checkoutSettings?.brand.asString,
          'card': card.toMap(),
        },
      );

      log('$result', name: "HyperpayPlugin/platformResponse");

      if (result == 'canceled') {
        // Checkout session is still going on.
        return PaymentSuccess(
            code: PaymentStatus.init,
            data: Success(
                result: Result(
              code: '',
              message: '',
              orderId: -1,
              status: 0,
            )));
      }

      final status =
          await checkoutHyperpayApi(urlStatus, _checkoutSettings?.getXAuth);
      // final status = await paymentStatus(
      //   _checkoutID,
      //   headers: _checkoutSettings?.headers,
      // );
      final String code = status!.result!.code;

      if (code.paymentStatus == PaymentStatus.rejected) {
        throw HyperpayException("Rejected payment.", code, status.toString());
      } else {
        log('${code.paymentStatus}', name: "HyperpayPlugin/paymentStatus");

        _clearSession();
        _checkoutID = '';

        return PaymentSuccess(code: code.paymentStatus, data: status);
      }
    } catch (e) {
      log('$e', name: "HyperpayPlugin/pay");
      rethrow;
    }
  }

  Future<Success?> checkoutHyperpayApi(checkoutHyperpay, getXAuth) async {
    var url = Uri.parse(checkoutHyperpay);
    var response = await get(url, headers: {
      'X-Auth-Token': getXAuth,
    });

    print(response.body);
    final data = Success.fromJson(json.decode(response.body));
    if (response.statusCode == 200) {
      return data;
    } else {
      return null;
    }
  }
}

class PaymentSuccess {
  PaymentSuccess({
    required this.code,
    required this.data,
  });

  PaymentStatus code;
  Success data;
}

class Success {
  Success({
    this.result,
  });

  Result? result;

  factory Success.fromJson(Map<String, dynamic> json) => Success(
        result: Result.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "result": result!.toJson(),
      };
}

class Result {
  Result({
    required this.status,
    required this.message,
    required this.code,
    required this.orderId,
  });

  int status;
  String message;
  String code;
  int orderId;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
      status: json["status"],
      message: json["message"],
      code: json["code"],
      orderId: json["order_id"]);

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "code": code,
        "order_id": orderId,
      };
}


 // Future<Map<String, dynamic>> paymentStatus(String checkoutID,
  //     {Map<String, String>? headers}) async {
  //   try {
  //     var url = Uri.parse(
  //         'https://test.oppwa.com/v1/checkouts/$checkoutID/payment?entityId=8ac7a4ca68374ef501683a8babbd0717');
  //     print(url);
  //     Response response = await get(url, headers: {
  //       'Authorization':
  //           'Bearer OGFjN2E0Y2E2ODM3NGVmNTAxNjgzYTg5ZDM2NjA3MTN8bUVlM21wRzhYNw=='
  //     });

  //     final Map<String, dynamic> _resBody = json.decode(response.body);
  //     if (_resBody['result'] != null && _resBody['result']['code'] != null) {
  //       print("lenaaaaaa 22222 2222 22222");
  //       log(
  //         '${_resBody['result']['code']}: ${_resBody['result']['description']}',
  //         name: "HyperpayPlugin/checkPaymentStatus",
  //       );

  //       return _resBody['result'];
  //     } else {
  //       throw HyperpayException(
  //         'The returned result does not contain the key "result" as the first key.',
  //         'RESPONSE BODY NOT IDENTIFIED',
  //         'please structure the returned body as {result: {code: CODE, description: DESCRIPTION}, id: CHECKOUT_ID, ...}.',
  //       );
  //     }
  //   } catch (exception) {
  //     rethrow;
  //   }
  // }