import '../../models/user_model.dart';

class RolePermissions {
  RolePermissions._();

  static const String admin = 'admin';
  static const String logistician = 'logistician';
  static const String carrier = 'carrier';
  static const String forwarder = 'forwarder';
  static const String cargoOwner = 'cargo_owner';
  static const String lawyer = 'lawyer';

  // Hybrid roles (canonical keys)
  static const String carrierForwarder = 'carrier_forwarder';
  static const String cargoOwnerCarrier = 'cargo_owner_carrier';
  static const String logisticianCarrier = 'logistician_carrier';

  // Legacy (for matching in hasRole only)
  static const String driver = 'driver';

  // Helper to check if user has a specific role
  static bool hasRole(UserModel user, String targetRole) {
    if (user.roles.contains(targetRole)) return true;

    // Fallback for older data structure or direct role field
    if (user.role == targetRole) return true;

    // Mapping legacy roles to new ones
    if (targetRole == carrier && user.role == driver) return true;
    if (targetRole == carrierForwarder && user.role == 'driver_forwarder')
      return true;
    if (targetRole == cargoOwnerCarrier && user.role == 'driver_cargo_owner')
      return true;

    // Handle compound legacy roles like "driver_forwarder" containing "driver"
    if (user.role.contains(targetRole)) return true;

    return false;
  }

  // Common permission checks
  static bool canCreateCargo(UserModel user) {
    return hasRole(user, admin) ||
        hasRole(user, logistician) ||
        hasRole(user, cargoOwner);
  }

  static bool canFindCargo(UserModel user) {
    return hasRole(user, admin) ||
        hasRole(user, carrier) ||
        hasRole(user, forwarder) ||
        hasRole(user, logistician) ||
        hasRole(user, cargoOwner);
  }

  static bool canApplyToCargo(UserModel user) {
    return hasRole(user, admin) ||
        hasRole(user, carrier) ||
        hasRole(user, forwarder);
  }

  static bool canCreateTender(UserModel user) {
    return hasRole(user, admin) ||
        hasRole(user, logistician) ||
        hasRole(user, cargoOwner);
  }

  static bool canBidTender(UserModel user) {
    return hasRole(user, admin) ||
        hasRole(user, carrier) ||
        hasRole(user, forwarder);
  }

  static bool canManageOwnTransport(UserModel user) {
    // admin, carrier, logistician (if logistician has carrier capability)
    return hasRole(user, admin) ||
        hasRole(user, carrier) ||
        hasRole(user, logisticianCarrier);
  }

  static bool canAssignExecutor(UserModel user, String cargoOwnerId) {
    // admin, logistician, cargo_owner (if cargo is his)
    return hasRole(user, admin) ||
        hasRole(user, logistician) ||
        user.uid == cargoOwnerId;
  }

  static bool canUpdateCargoStatus(
      UserModel user, String? executorId, String cargoOwnerId) {
    if (hasRole(user, admin)) return true;
    if (hasRole(user, logistician)) return true;
    if (user.uid == cargoOwnerId) return true;
    if (executorId != null && user.uid == executorId) return true;
    return false;
  }

  static bool canUploadCargoDocuments(
      UserModel user, String? executorId, String cargoOwnerId) {
    if (hasRole(user, admin)) return true;
    if (hasRole(user, logistician)) return true;
    if (user.uid == cargoOwnerId) return true;
    if (executorId != null && user.uid == executorId) return true;
    return false;
  }

  static bool canVerifyDocuments(UserModel user, String cargoOwnerId) {
    return hasRole(user, admin) ||
        hasRole(user, logistician) ||
        user.uid == cargoOwnerId;
  }

  static bool canManageUsers(UserModel user) {
    return hasRole(user, admin);
  }

  static bool canHandleLegalRequests(UserModel user) {
    return hasRole(user, admin) || hasRole(user, lawyer);
  }

  static bool canViewAllCargos(UserModel user) {
    return true;
  }
}
