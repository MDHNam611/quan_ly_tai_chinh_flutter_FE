class AccountModel {
  final String id;
  final String name;
  final double balance;
  final String? description;
  final String? icon;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    this.description,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'description': description,
      'icon': icon,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'],
      name: map['name'],
      balance: (map['balance'] as num).toDouble(),
      description: map['description'],
      icon: map['icon'],
    );
  }
}