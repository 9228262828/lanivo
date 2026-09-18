LANIVO — Lane Switch
Tagline: Switch fast. Stay alive.
Package: com.lanivo.laneswitch

Add to pubspec.yaml:

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.3.2

Included:
- Splash Screen
- Home Screen
- Endless Mode
- 60 Sec Rush Mode
- Perfect Run Mode
- 3-lane gameplay
- Left / Right controls
- Tap left or right half of play field
- Obstacles
- Coins
- Score
- Combo
- Distance
- Progressive speed
- Progressive spawn rate
- Pause / Resume
- Result Screen
- Play Again
- Best Scores per mode
- Statistics
- Dark Mode
- Haptic toggle
- Privacy Policy
- Terms & Conditions
- Reset Progress
- SharedPreferences persistence

No Flame
No physics engine
No Firebase
No backend
No login
No ads
No analytics
No image assets required
No audio assets required

Stability safeguards:
- Entire app is in lib/main.dart to avoid missing class/import errors.
- Single periodic Timer.
- Timer cancelled in dispose().
- Duplicate result navigation guarded.
- Run registration guarded so each run saves once.
- Explicit numeric conversions after clamp().
