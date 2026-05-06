import '../../models/user_model.dart';

class RolePermissions {
  RolePermissions._();

  static const String admin = 'admin';
  static const String logistician = 'logistician';
  static const String driver = 'driver';
  static const String forwarder = 'forwarder';
  static const String cargoOwner = 'cargo_owner';

  // Helper to check if user has a specific role
  static bool hasRole(UserModel user, String targetRole) {
    if (user.roles.contains(targetRole)) return true;
    // Fallback for older data structure where roles was not an array
    if (user.role == targetRole) return true;
    // Handle compound legacy roles like "driver_forwarder"
    if (user.role.contains(targetRole)) return true;
    return false;
  }

  // Common permission checks
  static bool canCreateCargo(UserModel user) {
    return hasRole(user, admin) || 
           hasRole(user, logistician) || 
           hasRole(user, cargoOwner);
  }

  static bool canEditCargo(UserModel user, String cargoOwnerId) {
    return hasRole(user, admin) || user.uid == cargoOwnerId;
  }

  static bool canDeleteCargo(UserModel user, String cargoOwnerId) {
    return hasRole(user, admin) || user.uid == cargoOwnerId;
  }

  static bool canAssignDriver(UserModel user, String cargoOwnerId) {
    return hasRole(user, admin) || user.uid == cargoOwnerId;
  }

  static bool canApplyToCargo(UserModel user) {
    return hasRole(user, driver) || hasRole(user, forwarder);
  }

  static bool canManageUsers(UserModel user) {
    return hasRole(user, admin);
  }

  static bool canViewAllCargos(UserModel user) {
    return hasRole(user, admin) || hasRole(user, logistician) || hasRole(user, driver);
  }
}
