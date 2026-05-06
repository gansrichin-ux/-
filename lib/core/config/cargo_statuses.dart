class CargoStatus {
  static const String draft = 'draft';
  static const String published = 'published';
  static const String hasApplications = 'has_applications';
  static const String executorSelected = 'executor_selected';
  static const String waitingConfirmation = 'waiting_confirmation';
  static const String confirmed = 'confirmed';
  static const String waitingLoading = 'waiting_loading';
  static const String loading = 'loading';
  static const String loaded = 'loaded';
  static const String inTransit = 'in_transit';
  static const String unloading = 'unloading';
  static const String delivered = 'delivered';
  static const String waitingDocuments = 'waiting_documents';
  static const String waitingPayment = 'waiting_payment';
  static const String closed = 'closed';
  static const String cancelled = 'cancelled';
  static const String dispute = 'dispute';
  static const String expired = 'expired';

  static const List<String> values = [
    draft,
    published,
    hasApplications,
    executorSelected,
    waitingConfirmation,
    confirmed,
    waitingLoading,
    loading,
    loaded,
    inTransit,
    unloading,
    delivered,
    waitingDocuments,
    waitingPayment,
    closed,
    cancelled,
    dispute,
    expired,
  ];

  static String fromLegacy(String value) {
    switch (value) {
      case 'Новый':
        return published;
      case 'В работе':
        return confirmed;
      case 'В пути':
        return inTransit;
      case 'Доставлено':
        return delivered;
      case 'Отменено':
        return cancelled;
      case 'Закрыто':
        return closed;
      case 'Спор':
        return dispute;
      default:
        return value;
    }
  }

  static String toLegacy(String status) {
    switch (status) {
      case published:
        return 'Новый';
      case confirmed:
        return 'В работе';
      case inTransit:
        return 'В пути';
      case delivered:
        return 'Доставлено';
      case cancelled:
        return 'Отменено';
      case closed:
        return 'Закрыто';
      case dispute:
        return 'Спор';
      default:
        return status;
    }
  }

  static String getDisplayStatus(String status) {
    switch (status) {
      case draft:
        return 'Черновик';
      case published:
        return 'Свободен';
      case hasApplications:
        return 'Есть отклики';
      case executorSelected:
        return 'Исполнитель выбран';
      case waitingConfirmation:
        return 'Ожидает подтверждения';
      case confirmed:
        return 'Подтвержден';
      case waitingLoading:
        return 'Ожидает погрузки';
      case loading:
        return 'На погрузке';
      case loaded:
        return 'Погружен';
      case inTransit:
        return 'В пути';
      case unloading:
        return 'На выгрузке';
      case delivered:
        return 'Доставлен';
      case waitingDocuments:
        return 'Ожидает документы';
      case waitingPayment:
        return 'Ожидает оплату';
      case closed:
        return 'Закрыт';
      case cancelled:
        return 'Отменен';
      case dispute:
        return 'Спор';
      case expired:
        return 'Просрочен';
      default:
        return toLegacy(status);
    }
  }
}
