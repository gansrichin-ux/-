class LoadingTypes {
  static const String any = 'any';
  static const String rear = 'rear';
  static const String side = 'side';
  static const String top = 'top';
  static const String sideTop = 'side_top';
  static const String rearTop = 'rear_top';
  static const String rearSide = 'rear_side';
  static const String rearSideTop = 'rear_side_top';

  static const Map<String, String> labels = {
    any: 'Любая',
    rear: 'Задняя',
    side: 'Боковая',
    top: 'Верхняя',
    sideTop: 'Боковая + Верхняя',
    rearTop: 'Задняя + Верхняя',
    rearSide: 'Задняя + Боковая',
    rearSideTop: 'Задняя + Боковая + Верхняя',
  };

  static String getLabel(String? type) => labels[type] ?? type ?? 'Не указан';
  
  static List<String> getLabels(List<String> types) {
    return types.map((t) => getLabel(t)).toList();
  }
}
