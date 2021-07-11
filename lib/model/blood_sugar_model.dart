class BloodSugarModel{
  String unit;
  String value;

  BloodSugarModel({this.unit, this.value});

  @override
  String toString() {
    return 'BloodSugarModel{unit: $unit, value: $value}';
  }
}