class RiderModel {
  final String id;
  final String name;
  final String phone;
  final String status;
  final String passportNumber;
  final String emiratesId;
  final String address;
  final String? email;    // Added for Step 4
  final String? password; // Added for Step 4

  RiderModel({
    required this.id,
    required this.name,
    required this.phone,
    this.status = 'available',
    required this.passportNumber,
    required this.emiratesId,
    this.address = '',
    this.email,
    this.password,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'available',
      passportNumber: json['passport_number'] ?? 'N/A',
      emiratesId: json['emirates_id'] ?? 'N/A',
      address: json['address'] ?? '',
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'status': status,
      'passport_number': passportNumber,
      'emirates_id': emiratesId,
      'address': address,
      'email': email,
      'password': password,
    };
  }
}
