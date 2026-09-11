class ServicePriceModel {
  final String id;
  final String serviceCode;
  final String name;
  final double price;
  final bool active;

  const ServicePriceModel({
    required this.id,
    required this.serviceCode,
    required this.name,
    required this.price,
    required this.active,
  });

  factory ServicePriceModel.fromJson(Map<String, dynamic> json) {
    return ServicePriceModel(
      id: json['id'] as String,
      serviceCode: json['service_code'] as String,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_code': serviceCode,
      'name': name,
      'price': price,
      'active': active,
    };
  }
}
