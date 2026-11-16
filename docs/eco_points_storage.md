# Eco Points: disposal-only storage

## Confirmed policy

- SQLite via the existing DBHelper; no second database, package, or migration.
- One balance per installation; no user accounts or made-up permanent user ID.
- Starting balance is zero: getTotalEcoPoints sums the disposal log.
- eco_points_log stores real disposals only.
- Production writes from the Eco Points UI use addEcoPoints(categoryName).
- No adjustment, opening-balance, savePoints, or generic increment service.

The earlier proposed adjustment service and its tests have been removed.
DBHelper and its schema are unchanged. Its existing lib/db_test.dart harness
also calls addEcoPoints for a test disposal; do not run it against real user data.

## Screen behavior

Eco Points loads getTotalEcoPoints and getEcoPointsLog (newest first). Reward
progress and remaining points use the loaded total, with the existing target
of 200 retained. The sample 120 and sample activities are removed.

Record a disposal on the Eco Points screen: select a category, tap
Mark as Disposed, then confirm that a real disposal occurred. Values come from
ecoPointsPerCategory: Electronics 50, Batteries 20, Clothing 30, Plastic 15.
The save button is disabled while recording. After addEcoPoints succeeds,
setState refreshes the total and activity list. Cancelling writes nothing.

Refresh and app resume reload persisted data. Read/write errors offer recovery;
a failed refresh after a successful save does not automatically repeat the save.
No Map or guide-screen changes are included.

## Checks

    flutter test --no-pub test/points_screen_test.dart
    flutter analyze --no-pub lib/screens/points_screen.dart test/points_screen_test.dart

Widget tests use a fake DBHelper, not a native database. Native SQLite must be
tested on Android, not Chrome.

## Phone verification

1. Run flutter run -d R9HR10A1LSJ -t lib/main.dart from W:\.
2. Open Eco Points; compare the total and history with actual existing disposals.
   An empty database should show zero and No disposals recorded yet.
3. Open a disposal confirmation and cancel; balance and history must not change.
4. After an actual disposal, choose its category and confirm once. Verify the
   correct award and a new activity entry.
5. Stop and reopen the app without uninstalling or clearing storage; verify the
   same balance and activity remain.

Do not add fabricated disposals to a user's database for testing. Automated
screen tests use a fake database. Read-only and cancellation checks on the phone
do not need a real disposal.
## Verification result for this change

- 10 focused widget tests passed, including confirmation cancellation and all
  four reward values.
- Static analysis passed for the screen and tests.
- Android debug APK built, installed over the existing app, and launched on
  SM M025F (R9HR10A1LSJ), retaining app data.
- On-phone Eco Points initially displayed zero and real reward progress.
- The user confirmed recording the Electronics disposal during testing.
  The native screen refreshed from zero to 50 points and displayed the new
  Electronics +50 activity. This is a user-confirmed disposal, not an
  unexplained database write. No record was removed or adjusted.
- After force-stop and relaunch, the native screen still displayed 50 and
  50 / 200 progress. Persistence across a process restart is verified.
- On-phone cancellation remains unverified; the widget cancellation test passed.
- No Confirm tap was intentionally sent by the agent. No database cleanup,
  migration, adjustment, or clearing of application data was performed.