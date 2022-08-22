part of hyperpay;

// Regular experessions for each brand
// These expressions were chosen according to this article.
// https://uxplanet.org/streamlining-the-checkout-experience-4-4-6793dad81360

RegExp _visaRegExp = RegExp(r'^4[0-9]{12}(?:[0-9]{3})?$');
RegExp _mastercardRegExp = RegExp(r'^5[1-5][0-9]{5,}$');
extension DetectBrand on String {
  /// Detects a card brand from its number.
  ///
  /// Supports VISA, MasterCard
  BrandType get detectBrand {
    final cleanNumber = this.replaceAll(' ', '');
    bool _isVISA = _visaRegExp.hasMatch(cleanNumber);
    bool _isMASTERCARD = _mastercardRegExp.hasMatch(cleanNumber);

    if (_isVISA) {
      return BrandType.visa;
    } else if (_isMASTERCARD) {
      return BrandType.mastercard;
    } else {
      return BrandType.none;
    }
  }
}

extension BrandTypeExtension on BrandType {
  /// String representation for each card type as mentioned in HyperPay docs.
  ///
  /// https://wordpresshyperpay.docs.oppwa.com/reference/parameters
  String get asString {
    switch (this) {
      case BrandType.visa:
        return 'VISA';
      case BrandType.mastercard:
        return 'MASTER';
      default:
        return '';
    }
  }

  /// Get the entity ID of this brand based on merchant configuration.
  String? entityID(HyperpayConfig config) {
    String? _entityID = '';
    switch (this) {
      case BrandType.visa:
        _entityID = config.creditcardEntityID;
        break;
      case BrandType.mastercard:
        _entityID = config.creditcardEntityID;
        break;

      default:
        _entityID = null;
    }
    return _entityID;
  }

  /// Match the string entered by user against RegExp rules
  /// for each card type.
  ///
  /// TODO: localize the messages.
  String? validateNumber(String number) {
    // Remove the white spaces inserted by formatters
    final cleanNumber = number.replaceAll(' ', '');

    switch (this) {
      case BrandType.visa:
        if (_visaRegExp.hasMatch(cleanNumber)) {
          return null;
        } else if (cleanNumber.isEmpty) {
          return "Required";
        } else {
          return "Inavlid VISA number";
        }
      case BrandType.mastercard:
        if (_mastercardRegExp.hasMatch(cleanNumber)) {
          return null;
        } else if (cleanNumber.isEmpty) {
          return "Required";
        } else {
          return "Inavlid MASTER CARD number";
        }
      default:
        return "No brand provided";
    }
  }

  /// Maximum length of this card number
  ///
  /// https://wordpresshyperpay.docs.oppwa.com/reference/parameters
  int get maxLength {
    switch (this) {
      case BrandType.visa:
        return 16;
      case BrandType.mastercard:
        return 16;
      default:
        return 19;
    }
  }
}
