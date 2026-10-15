class UserModel {
  final String id;
  final String name;
  final String email;
  final String currency;
  final String currencySymbol;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.currency = 'INR',
    this.currencySymbol = '₹',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      currency: json['currency'] ?? 'INR',
      currencySymbol: json['currencySymbol'] ?? '₹',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'currency': currency,
      'currencySymbol': currencySymbol,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? currency,
    String? currencySymbol,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
