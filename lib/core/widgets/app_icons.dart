import 'package:flutter/widgets.dart';

class AppIcons {
  AppIcons._();

  static const _base = 'assets/icons/custom';

  static const dashboard = '$_base/ic_dashboard.png';
  static const company = '$_base/ic_company.png';
  static const myCargos = '$_base/ic_my_cargos.png';
  static const findCargo = '$_base/ic_find_cargo.png';
  static const findTransport = '$_base/ic_find_transport.png';
  static const saved = '$_base/ic_saved.png';
  static const chats = '$_base/ic_chats.png';
  static const tenders = '$_base/ic_tenders.png';
  static const insurance = '$_base/ic_insurance.png';
  static const legal = '$_base/ic_legal.png';
  static const carriers = '$_base/ic_carriers.png';
  static const users = '$_base/ic_users.png';
  static const support = '$_base/ic_support.png';
  static const theme = '$_base/ic_theme.png';
  static const notifications = '$_base/ic_notifications.png';
  static const profile = '$_base/ic_profile.png';
  static const logout = '$_base/ic_logout.png';
  static const tabDashboard = '$_base/ic_tab_dashboard.png';
  static const staff = '$_base/ic_staff.png';
  static const transport = '$_base/ic_transport.png';
  static const tabCargos = '$_base/ic_tab_cargos.png';
  static const tabSaved = '$_base/ic_tab_saved.png';
  static const settings = '$_base/ic_settings.png';
  static const workspace = '$_base/ic_workspace.png';
  static const edit = '$_base/ic_edit.png';
  static const reputationAccess = '$_base/ic_reputation_access.png';
  static const activeCargos = '$_base/ic_active_cargos.png';
  static const inTransit = '$_base/ic_in_transit.png';
  static const pendingConfirmation = '$_base/ic_pending_confirmation.png';
  static const pendingLoading = '$_base/ic_pending_loading.png';
  static const pendingPayment = '$_base/ic_pending_payment.png';
  static const inDispute = '$_base/ic_in_dispute.png';
  static const averageCheck = '$_base/ic_average_check.png';
  static const closedTrips = '$_base/ic_closed_trips.png';

  static const all = <String>[
    dashboard,
    company,
    myCargos,
    findCargo,
    findTransport,
    saved,
    chats,
    tenders,
    insurance,
    legal,
    carriers,
    users,
    support,
    theme,
    notifications,
    profile,
    logout,
    tabDashboard,
    staff,
    transport,
    tabCargos,
    tabSaved,
    settings,
    workspace,
    edit,
    reputationAccess,
    activeCargos,
    inTransit,
    pendingConfirmation,
    pendingLoading,
    pendingPayment,
    inDispute,
    averageCheck,
    closedTrips,
  ];
}

class AppPngIcon extends StatelessWidget {
  final String asset;
  final double size;
  final String? semanticLabel;
  final BoxFit fit;
  final FilterQuality filterQuality;

  const AppPngIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.semanticLabel,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      semanticLabel: semanticLabel,
      filterQuality: filterQuality,
    );
  }
}
