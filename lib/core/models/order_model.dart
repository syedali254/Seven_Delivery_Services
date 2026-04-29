enum OrderStatus { processing, assigned, inTransit, delivered, cancelled }

class OrderModel {
  final String id;
  final String senderName;
  final String senderPhone;
  final String pickupAddress;
  final String receiverName;
  final String receiverPhone;
  final String address;
  final String city;
  final String content;
  final double weight;
  final int pieces;
  final double codAmount;
  final double serviceFee;
  final OrderStatus status;
  final String? riderId;
  final bool verified;

  OrderModel({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.pickupAddress,
    required this.receiverName,
    required this.receiverPhone,
    required this.address,
    required this.city,
    required this.content,
    required this.weight,
    required this.pieces,
    required this.codAmount,
    required this.serviceFee,
    required this.status,
    this.riderId,
    this.verified = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      senderName: json['sender_name'] ?? '',
      senderPhone: json['sender_phone'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      receiverName: json['receiver_name'] ?? '',
      receiverPhone: json['receiver_phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? 'Dubai',
      content: json['content'] ?? 'General Goods',
      weight: (json['weight'] ?? 1.0).toDouble(),
      pieces: json['pieces'] ?? 1,
      codAmount: (json['cod_amount'] ?? 0.0).toDouble(),
      serviceFee: (json['service_fee'] ?? 25.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.processing,
      ),
      riderId: json['rider_id'],
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'pickup_address': pickupAddress,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'address': address,
      'city': city,
      'content': content,
      'weight': weight,
      'pieces': pieces,
      'cod_amount': codAmount,
      'service_fee': serviceFee,
      'status': status.name,
      'rider_id': riderId,
      'verified': verified,
    };
  }
}
