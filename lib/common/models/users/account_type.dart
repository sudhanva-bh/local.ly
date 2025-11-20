enum AccountType {
  wholesaleSeller,
  retailSeller,
  consumer, // 👈 NEW
}

extension AccountTypeX on AccountType {
  String toValue() {
    switch (this) {
      case AccountType.wholesaleSeller:
        return 'wholesaleSeller';
      case AccountType.retailSeller:
        return 'retailSeller';
      case AccountType.consumer:
        return 'consumer'; // 👈 NEW
    }
  }

  static AccountType fromValue(String? value) {
    switch (value) {
      case 'wholesaleSeller':
        return AccountType.wholesaleSeller;
      case 'retailSeller':
        return AccountType.retailSeller;
      case 'consumer':
        return AccountType.consumer; // 👈 NEW
      default:
        // default fallback for unknown values
        return AccountType.retailSeller;
    }
  }

  String toWords() {
    switch (this) {
      case AccountType.wholesaleSeller:
        return 'Wholesale Seller';
      case AccountType.retailSeller:
        return 'Retail Seller';
      case AccountType.consumer:
        return 'Consumer'; // 👈 NEW
    }
  }
}
