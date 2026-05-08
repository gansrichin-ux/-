import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/config/firebase_options.dart';
import 'core/config/cargo_statuses.dart';
import 'core/services/exchange_rate_service.dart';
import 'core/services/cargo_workflow_service.dart';
import 'models/cargo_model.dart';
import 'models/document_model.dart';
import 'models/exchange_rate_model.dart';
import 'models/message_model.dart';
import 'models/site_workflow_models.dart';
import 'models/tender_model.dart';
import 'models/transport_model.dart';
import 'models/user_model.dart';
import 'repositories/auth_repository.dart';
import 'repositories/cargo_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/site_workflow_repository.dart';
import 'repositories/tender_repository.dart';
import 'repositories/transport_repository.dart';
import 'repositories/user_repository.dart';

import 'core/config/truck_body_types.dart';
import 'core/theme/app_breakpoints.dart';
import 'core/widgets/app_responsive.dart';
import 'core/theme/app_text_styles.dart';
import 'core/widgets/app_button.dart';
import 'core/widgets/app_card.dart';
import 'core/widgets/app_text_field.dart';
import 'core/widgets/app_dropdown.dart';
import 'core/widgets/app_badges.dart';
import 'core/widgets/app_headers.dart';
import 'core/widgets/app_stat_card.dart';
import 'core/widgets/app_empty_state.dart';
import 'core/widgets/app_loading_state.dart';
import 'core/widgets/app_error_state.dart';
import 'core/widgets/app_status_badge.dart';
import 'core/widgets/cargo_widgets.dart';

part 'site/site_app.dart';
part 'site/site_router.dart';
part 'site/admin/site_admin_page.dart';
part 'site/theme/site_theme.dart';
part 'site/auth/site_auth.dart';
part 'site/widgets/login_preview.dart';
part 'site/dashboard/site_dashboard.dart';
part 'site/dashboard/role_workspace.dart';
part 'site/dashboard/overview_section.dart';
part 'site/dashboard/tender_section.dart';
part 'site/dashboard/cargos_section.dart';
part 'site/dashboard/chats_section.dart';
part 'site/dashboard/transport_sections.dart';
part 'site/dashboard/transport_dialogs.dart';
part 'site/dashboard/company_service_sections.dart';
part 'site/dashboard/workflow_sections.dart';
part 'site/dashboard/carriers_section.dart';
part 'site/dashboard/users_section.dart';
part 'site/dashboard/sync_section.dart';
part 'site/dialogs/add_cargo_dialog.dart';
part 'site/dialogs/chat_dialog.dart';
part 'site/dialogs/user_profile_dialog.dart';
part 'site/widgets/shared_widgets.dart';
part 'site/site_utils.dart';
part 'site/landing/site_landing.dart';
part 'site/profile/user_profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  var firebaseReady = true;
  Object? firebaseError;

  try {
    await AppFirebaseOptions.initialize();
  } catch (error) {
    firebaseReady = false;
    firebaseError = error;
  }

  String? initialTheme;
  try {
    final prefs = await SharedPreferences.getInstance();
    initialTheme = prefs.getString('site_theme');
  } catch (_) {}

  runApp(
    ProviderScope(
      child: LogistSiteApp(
        firebaseReady: firebaseReady,
        firebaseError: firebaseError,
        initialTheme: initialTheme,
      ),
    ),
  );
}
