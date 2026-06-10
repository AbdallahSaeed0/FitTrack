// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void saveWorkoutState(String json) {
  html.window.localStorage['fittrack_workout'] = json;
}

String? loadWorkoutState() {
  return html.window.localStorage['fittrack_workout'];
}

void clearWorkoutState() {
  html.window.localStorage.remove('fittrack_workout');
}
