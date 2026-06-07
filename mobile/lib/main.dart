import 'dart:convert';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

part 'core/theme.dart';
part 'core/session_store.dart';
part 'core/api_client.dart';
part 'services/notification_service.dart';
part 'features/app/vitalis_app.dart';
part 'features/app/root_screen.dart';
part 'features/app/home_shell.dart';
part 'features/auth/welcome_screen.dart';
part 'features/auth/auth_screen.dart';
part 'features/dashboard/dashboard_page.dart';
part 'features/assessment/assessment_page.dart';
part 'features/recommendations/recommendations_page.dart';
part 'features/recommendations/meal_plan_page.dart';
part 'features/recommendations/food_log_panel.dart';
part 'features/reminders/reminders_page.dart';
part 'features/profile/profile_page.dart';
part 'widgets/shared_widgets.dart';
part 'utils/helpers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const VitalisApp());
}
