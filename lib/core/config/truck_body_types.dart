class TruckBodyTypes {
  static const String truck = 'truck';
  static const String tent = 'tent';
  static const String refrigerator = 'refrigerator';
  static const String cistern = 'cistern';
  static const String dumpTruck = 'dump_truck';
  static const String openTruck = 'open_truck';
  static const String concreteMixer = 'concrete_mixer';
  static const String bitumenCarrier = 'bitumen_carrier';
  static const String gasCarrier = 'gas_carrier';
  static const String grainCarrier = 'grain_carrier';
  static const String containerPlatform = 'container_platform';
  static const String feedCarrier = 'feed_carrier';
  static const String crane = 'crane';
  static const String timberCarrier = 'timber_carrier';
  static const String manipulator = 'manipulator';
  static const String minibus = 'minibus';
  static const String flourCarrier = 'flour_carrier';
  static const String openContainer = 'open_container';
  static const String semiTrailer = 'semi_trailer';
  static const String livestockCarrier = 'livestock_carrier';
  static const String lowboy = 'lowboy';
  static const String pipeCarrier = 'pipe_carrier';
  static const String allMetal = 'all_metal';
  static const String cementCarrier = 'cement_carrier';
  static const String flatbed = 'flatbed';
  static const String woodChipCarrier = 'wood_chip_carrier';
  static const String towTruck = 'tow_truck';
  static const String excavator = 'excavator';
  static const String panelCarrier = 'panel_carrier';
  static const String loader = 'loader';

  static const Map<String, String> labels = {
    truck: 'Фургон',
    tent: 'Тент',
    refrigerator: 'Рефрижератор',
    cistern: 'Цистерна',
    dumpTruck: 'Самосвал',
    openTruck: 'Открытый',
    concreteMixer: 'Бетоносмеситель',
    bitumenCarrier: 'Битумовоз',
    gasCarrier: 'Газовоз',
    grainCarrier: 'Зерновоз',
    containerPlatform: 'Контейнерная площадка',
    feedCarrier: 'Кормовоз',
    crane: 'Автокран',
    timberCarrier: 'Лесовоз',
    manipulator: 'Манипулятор',
    minibus: 'Микроавтобус',
    flourCarrier: 'Муковоз',
    openContainer: 'Открытый контейнер',
    semiTrailer: 'Полуприцеп',
    livestockCarrier: 'Скотовоз',
    lowboy: 'Трал',
    pipeCarrier: 'Трубовоз',
    allMetal: 'Цельнометаллический',
    cementCarrier: 'Цементовоз',
    flatbed: 'Бортовой',
    woodChipCarrier: 'Щеповоз',
    towTruck: 'Эвакуатор',
    excavator: 'Экскаватор',
    panelCarrier: 'Панелевоз',
    loader: 'Погрузчик',
  };

  static String getLabel(String? type) => labels[type] ?? type ?? 'Не указан';
}
