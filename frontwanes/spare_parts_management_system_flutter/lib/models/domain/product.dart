class Product {
  final String? id;
  final String name;
  final String referenceCode;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? image;
  final double unitPrice;
  final String? description;
  final double? supplierPrice;
  final String? supplierId;
  final Map<String, dynamic>? supplier;

  Product({
    this.id,
    required this.name,
    required this.referenceCode,
    this.barcode,
    this.brand,
    this.category,
    this.image,
    required this.unitPrice,
    this.description,
    this.supplierPrice,
    this.supplierId,
    this.supplier,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    double parseUnitPrice(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name'] as String? ?? '',
      referenceCode: json['reference_code'] as String? ?? '',
      barcode: json['barcode'] as String?,
      brand: json['brand'] as String?,
      category: json['category'] as String?,
      image: json['image'] as String?,
      unitPrice: parseUnitPrice(json['unit_price']),
      description: json['description'] as String?,
      supplierPrice:
          json['supplier_price'] != null
              ? double.tryParse(json['supplier_price'].toString())
              : null,
      supplierId: json['supplier_id']?.toString(),
      supplier: json['supplier'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (id != null) data['_id'] = id;
    data['name'] = name;
    data['reference_code'] = referenceCode;
    if (barcode != null) data['barcode'] = barcode;
    data['brand'] = brand;
    data['category'] = category;
    data['image'] = image;
    data['unit_price'] = unitPrice;
    data['description'] = description;
    if (supplierPrice != null) data['supplier_price'] = supplierPrice;
    if (supplierId != null) data['supplier_id'] = supplierId;
    if (supplier != null) data['supplier'] = supplier;
    return data;
  }

  String getCategoryDisplayName() {
    if (category == null || category!.isEmpty) return 'Non catégorisé';

    // Convert enum values to display names
    switch (category!.toUpperCase()) {
      case 'ELECTRONICS':
        return 'Électronique';
      case 'AUTOMOTIVE':
        return 'Automobile';
      case 'MECHANICAL':
        return 'Mécanique';
      case 'ELECTRICAL':
        return 'Électrique';
      case 'PLUMBING':
        return 'Plomberie';
      case 'HVAC':
        return 'Climatisation';
      case 'TOOLS':
        return 'Outils';
      case 'SAFETY_EQUIPMENT':
        return 'Équipement de sécurité';
      case 'LUBRICANTS':
        return 'Lubrifiants';
      case 'FILTERS':
        return 'Filtres';
      case 'BELTS':
        return 'Courroies';
      case 'BRAKES':
        return 'Freins';
      case 'ENGINE_PARTS':
        return 'Pièces moteur';
      case 'TRANSMISSION':
        return 'Transmission';
      case 'SUSPENSION':
        return 'Suspension';
      case 'OTHER':
        return 'Autre';
      default:
        return category!;
    }
  }

  String getBrandDisplayName() {
    if (brand == null || brand!.isEmpty) return 'Marque non spécifiée';

    // Convert enum values to display names
    switch (brand!.toUpperCase()) {
      case 'BOSCH':
        return 'Bosch';
      case 'CONTINENTAL':
        return 'Continental';
      case 'VALEO':
        return 'Valeo';
      case 'MANN':
        return 'Mann';
      case 'MAHLE':
        return 'Mahle';
      case 'NGK':
        return 'NGK';
      case 'DENSO':
        return 'Denso';
      case 'DELPHI':
        return 'Delphi';
      case 'SKF':
        return 'SKF';
      case 'TIMKEN':
        return 'Timken';
      case 'GATES':
        return 'Gates';
      case 'DAYCO':
        return 'Dayco';
      case 'BREMBO':
        return 'Brembo';
      case 'SACHS':
        return 'Sachs';
      case 'LUK':
        return 'Luk';
      case 'ZF':
        return 'ZF';
      case 'BILSTEIN':
        return 'Bilstein';
      case 'KYB':
        return 'KYB';
      case 'MONROE':
        return 'Monroe';
      case 'KONI':
        return 'Koni';
      case 'MOBIL':
        return 'Mobil';
      case 'CASTROL':
        return 'Castrol';
      case 'SHELL':
        return 'Shell';
      case 'TOTAL':
        return 'Total';
      case 'ELF':
        return 'Elf';
      case 'MOTUL':
        return 'Motul';
      case 'LIQUI_MOLY':
        return 'Liqui Moly';
      case 'MILLERS':
        return 'Millers';
      case 'RED_LINE':
        return 'Red Line';
      case 'AMSOIL':
        return 'Amsoil';
      case 'ROYAL_PURPLE':
        return 'Royal Purple';
      case 'PENNZOIL':
        return 'Pennzoil';
      case 'VALVOLINE':
        return 'Valvoline';
      case 'QUAKER_STATE':
        return 'Quaker State';
      case 'HAVOLINE':
        return 'Havoline';
      case 'OTHER':
        return 'Autre';
      default:
        return brand!;
    }
  }
}
