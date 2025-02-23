class UserInfo {
  final double balance;
  final String status;
  final String model;
  final DateTime? expiresAt;

  UserInfo({
    required this.balance,
    required this.status,
    required this.model,
    this.expiresAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      balance: json['balance']?.toDouble() ?? 0.0,
      status: json['status'] ?? '未知',
      model: json['model'] ?? 'unknown',
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
    );
  }
} 