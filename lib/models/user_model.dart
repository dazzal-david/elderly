class UserModel {
  final String id;
  final String name;
  final int age;
  final String bloodGroup;
  final double height;
  final double weight;
  final String gender;
  final List<String> medicalConditions;
  final List<String> disabilities;
  final List<String> allergies;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodGroup,
    required this.height,
    required this.weight,
    required this.gender,
    required this.medicalConditions,
    required this.disabilities,
    required this.allergies,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      bloodGroup: json['blood_group'] ?? '',
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      gender: json['gender'] ?? 'Not Specified',
      medicalConditions: List<String>.from(json['medical_conditions'] ?? []),
      disabilities: List<String>.from(json['disabilities'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'blood_group': bloodGroup,
      'height': height,
      'weight': weight,
      'gender': gender,
      'medical_conditions': medicalConditions,
      'disabilities': disabilities,
      'allergies': allergies,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    int? age,
    String? bloodGroup,
    double? height,
    double? weight,
    String? gender,
    List<String>? medicalConditions,
    List<String>? disabilities,
    List<String>? allergies,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      disabilities: disabilities ?? this.disabilities,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt,
    );
  }
}