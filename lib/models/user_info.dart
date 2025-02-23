class UserInfo {
  final String id;
  final String name;
  final String image;
  final String email;
  final bool isAdmin;
  final double balance;
  final String status;
  final String introduction;
  final String role;
  final double chargeBalance;
  final double totalBalance;
  final int category;

  UserInfo({
    required this.id,
    required this.name,
    required this.image,
    required this.email,
    required this.isAdmin,
    required this.balance,
    required this.status,
    required this.introduction,
    required this.role,
    required this.chargeBalance,
    required this.totalBalance,
    required this.category,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return UserInfo(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      isAdmin: data['isAdmin'] ?? false,
      balance: double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0,
      status: data['status']?.toString() ?? '',
      introduction: data['introduction']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      chargeBalance: double.tryParse(data['chargeBalance']?.toString() ?? '0') ?? 0.0,
      totalBalance: double.tryParse(data['totalBalance']?.toString() ?? '0') ?? 0.0,
      category: int.tryParse(data['category']?.toString() ?? '0') ?? 0,
    );
  }
} 