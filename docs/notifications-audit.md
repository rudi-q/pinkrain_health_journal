# Notification Management Audit

**Date:** 2026-05-19
**Branch / commit reviewed:** `feat/data-export-import` @ `69fb4b8`
**Scope:** medication-reminder pipeline only — `MedicationSchedulerService`, `MedicationNotificationService`, `NotificationService`, `DailyResetService`, the boot path in `main.dart`, and the Android manifest.
**Method:** code read only. No on-device or simulator verification. All severities and failure modes below are reasoned from the source; some are theoretical until reproduced.

---

## TL;DR

The architecture shows real care — singleton services, debounce, deterministic notification IDs, boot recovery on Android, restore-on-init for iOS, exact/inexact-alarm fallback exists. But several gaps mean **notifications can silently fail to fire** for users with several daily meds, on Android 12+ without `SCHEDULE_EXACT_ALARM`, on aggressive-OEM Android devices, or after DST transitions. For a wellness app this is acceptable; for clinical-grade reliability (insulin schedules, post-transplant immunosuppressants) it is not yet there.

The two highest-leverage fixes are **#1 (iOS 64-pending-notification cap)** and **#2 (the main scheduling path bypasses the inexact-alarm fallback)**. Both are silent failure modes — users won't get an error, the reminder just doesn't arrive.

---

## Update — what's been resolved since the audit

Branch `feat/notifications-hardening` (commits `fad9d68`, `ebd85ff`, `1e2d823`, `524afd1`) addresses the four lowest-risk items:

- **#7 — Stable FNV-1a notification IDs with a one-time migration.** Old `String.hashCode`-based IDs are cancelled on first launch after upgrade so they don't fire as duplicates.
- **#8 — Hive-backed dedupe state.** `_notifiedMedicationIds` now persists in a new `notification_tracking` box, keyed per day, restored on init and pruned. Survives iOS process recreation.
- **#9 — Removed unused `BIND_NOTIFICATION_LISTENER_SERVICE` permission.** Eliminates a Play-policy snag.
- **#10 — "Send test reminder (30s)" diagnostic tile.** Lets users verify on-device that scheduled notifications actually fire.

Plus a small follow-up on `feat/notifications-hardening` to: route the new `notification_tracking` box through the existing "Delete All Data" flow, switch the test-reminder ID to a negative value (truly outside the deterministic-hash range), and update this doc.

**Issues 1–6 are still open and call for design discussion before code.**

---

## What's already solid (so we don't accidentally regress it)

- **Boot survival on Android.** `AndroidManifest.xml:5,48-56` declares `RECEIVE_BOOT_COMPLETED` and wires up `ScheduledNotificationBootReceiver`, so reminders survive a device reboot.
- **iOS rescue on cold start.** `_restoreScheduledNotifications` (`lib/features/treatment/services/medication_scheduler_service.dart:411`) re-arms the system queue from Hive on every init. Essential because iOS clears scheduled notifications when the app is force-killed.
- **Deterministic notification IDs.** `(medicationId.hashCode ^ scheduledTimeMs.hashCode).abs() % 2147483647` at `medication_scheduler_service.dart:738-755` means re-scheduling the same dose replaces rather than duplicates. Good design.
- **Action buttons** (Snooze / Mark as Taken) configured on both iOS (`DarwinNotificationCategory`, `push_notifications.dart:60-78`) and Android (`AndroidNotificationAction`, `push_notifications.dart:300-313, 369-382`).
- **Treatment delete cancels** its in-flight notifications (`treatment_manager.dart:441`).
- **Debounce on scheduling** prevents thrashing when multiple call sites fire near-simultaneously (`medication_notification_service.dart:36, 133-147`).
- **Exact/inexact alarm fallback exists** as a wrapper in `NotificationService.zonedSchedule` (`push_notifications.dart:437-471`) — though see issue #2 about whether it's actually reached.

---

## Severity overview

| # | Issue | Severity | Status |
|---|---|---|---|
| 1 | iOS 64-pending-notification cap not enforced | **High** | Open |
| 2 | Main scheduling path bypasses the inexact-alarm fallback | **High** | Open |
| 3 | No `SCHEDULE_EXACT_ALARM` permission request UI on Android 12+ | **High** | Open |
| 4 | DST / timezone changes break already-scheduled notifications | **High** | Open |
| 5 | Daily reset is a Dart `Timer`, only runs while app is alive | **Medium–High** | Open |
| 6 | OEM battery optimization (Xiaomi, OnePlus, Huawei, Samsung) unaddressed | **Medium** | Open |
| 7 | `String.hashCode` not guaranteed stable across SDK versions | **Medium** | **Fixed** (`ebd85ff`) |
| 8 | In-memory dedupe state evaporates on process recreation | **Medium** | **Fixed** (`1e2d823`) |
| 9 | `BIND_NOTIFICATION_LISTENER_SERVICE` declared but unused | **Low** | **Fixed** (`fad9d68`) |
| 10 | No "send test notification" UI for users to self-verify | **Low** | **Fixed** (`524afd1`) |

---

## Issue 1 — iOS 64-pending-notification cap not enforced

**Severity:** High.
**Where:** `lib/features/treatment/services/medication_scheduler_service.dart:116` (60-day rolling window), `:88-256` (the main scheduling loop), `:734` (`_scheduleNotification`).

**Current behavior.** `scheduleMedicationNotifications` schedules one local notification per dose-time per active day, capped only by a 60-day rolling window. With two treatments at three doses each, that is `2 × 3 × 60 = 360` pending notifications.

**Why it's risky.** iOS enforces a hard limit of **64 pending local notifications per app**. Anything past 64 is silently dropped by the OS — no exception, no callback. Which 64 win is OS-defined (in practice, the earliest scheduled). On a multi-med user this means most reminders never fire, and the app has no way to detect it.

**Suggested fix.** On iOS, treat scheduling as a sliding window of **~50 notifications** (leave 14 slots of headroom for snooze re-schedules and edge cases). On every foreground / midnight reset, recompute "the next 50 doses across all treatments, ordered by time," cancel anything outside that set, and ensure those 50 are scheduled. Android can keep the 60-day window as-is.

Implementation sketch:
```dart
if (Platform.isIOS) {
  final upcoming = _flattenDoseTimes(treatments)
    .where((t) => t.isAfter(now))
    .toList()
    ..sort();
  final keep = upcoming.take(50).toList();
  // cancel anything else, schedule the keep set
}
```

---

## Issue 2 — Main scheduling path bypasses the inexact-alarm fallback

**Severity:** High.
**Where:** `lib/features/journal/domain/push_notifications.dart:346-425` (`schedulePillReminder`), `lib/features/treatment/services/medication_scheduler_service.dart:716-733` (`_scheduleNotification`).

**Current behavior.** The scheduler service calls `_notificationService.schedulePillReminder(...)`, which calls `_notificationsPlugin.zonedSchedule(...)` **directly** with `AndroidScheduleMode.exactAllowWhileIdle` (`push_notifications.dart:414-422`). No try/catch. If the call throws (e.g. `exact_alarms_not_permitted` on Android 12+ after permission revocation), the exception bubbles up to `_scheduleNotification`'s try/catch at `medication_scheduler_service.dart:730-732`, which just `devPrint`s and returns.

The fallback to `AndroidScheduleMode.inexactAllowWhileIdle` lives in `NotificationService.zonedSchedule` (`push_notifications.dart:437-471`) — but **nothing in the codebase calls that wrapper**. It's effectively dead code.

**Why it's risky.** When exact-alarm permission is revoked (which happens silently on Android 12+ for various OEM and OS reasons), every subsequent scheduling call fails silently. The stored Hive record at `_saveScheduledNotifications` (line 792) still claims the notification is scheduled. Restore-on-init reads that record and re-tries — also silently fails. The user sees nothing in the UI; reminders just never fire.

**Suggested fix.** Route `schedulePillReminder` through the existing `zonedSchedule` wrapper (or inline the same try/catch fallback into `schedulePillReminder`). Additionally, when fallback is triggered, persist a flag and surface it in the UI ("Reminders may arrive late — tap to grant exact-alarm permission").

---

## Issue 3 — No `SCHEDULE_EXACT_ALARM` permission request UI on Android 12+

**Severity:** High.
**Where:** `android/app/src/main/AndroidManifest.xml:3-4`, profile screen (no request site exists).

**Current behavior.** The manifest declares both `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`, but the runtime never requests them. `SCHEDULE_EXACT_ALARM` on Android 12+ is a **special app access permission** — not a runtime permission. The user has to grant it via `Settings → Apps → PinkRain → Alarms & reminders`. There is no in-app intent to deep-link them there.

**Why it's risky.** Without exact alarms, scheduled notifications fall under Doze restrictions and can be delayed by **hours**. For medication reminders, "your 9 AM dose fired at 1 PM" is functionally the same as a miss.

**Suggested fix.** On first launch and after permission denial, check `AlarmManager.canScheduleExactAlarms()` via the plugin and prompt the user with a dialog that opens the system settings page:
```dart
final intent = AndroidIntent(
  action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
  data: Uri(scheme: 'package', path: packageName).toString(),
);
await intent.launch();
```
Show this prompt next to the existing notification-permission flow in `profile.dart`.

---

## Issue 4 — DST / timezone changes break already-scheduled notifications

**Severity:** High.
**Where:** `lib/features/journal/domain/push_notifications.dart:411-422` (uses `tz.TZDateTime.from(scheduledTime, tz.local)`), no DST-change listener anywhere.

**Current behavior.** `tz_data.initializeTimeZones()` runs once at init. Notifications are scheduled as `TZDateTime` in `tz.local`. After that, nothing watches for system timezone changes or DST transitions.

**Why it's risky.** A 9 AM dose scheduled today, with spring-forward happening this weekend, will fire at the wrong wall-clock time after the transition. The user gets either an hour-early or hour-late ping — and worse, it stays wrong until the app re-runs `scheduleMedicationNotifications`, which only happens on next foreground (or at midnight if the app is open — see #5).

This also bites users who travel across timezones: scheduled "9 AM home time" notifications fire at home-time UTC, not destination-time wall clock.

**Suggested fix.**
1. Listen for the OS broadcast `Intent.ACTION_TIMEZONE_CHANGED` on Android (and the equivalent `NSSystemTimeZoneDidChangeNotification` on iOS) via a small platform channel, and trigger a full re-schedule.
2. On app foreground, compare the timezone observed at last schedule with the current timezone; if different, re-schedule.
3. Consider scheduling against **wall-clock** time (`DateTimeComponents.time` is already passed in the unused wrapper at `push_notifications.dart:446`) so the daily recurrence at "9 AM local" follows the device clock — but this only works for daily-recurring notifications, not the per-day notifications the current code produces.

---

## Issue 5 — Daily reset is a Dart `Timer`, only runs while app is alive

**Severity:** Medium–High.
**Where:** `lib/features/treatment/services/daily_reset_service.dart:40` (`Timer(timeUntilMidnight, ...)`).

**Current behavior.** `DailyResetService.initialize()` schedules a Dart `Timer` to fire at midnight, which then calls `_performDailyReset` (re-runs `getMedicationsForTheDay` and `showUntakenMedicationNotifications`). After firing, it re-schedules itself.

**Why it's risky.** Dart `Timer`s only run while the app process is alive. If the user closes the app at 11 PM, the midnight timer is discarded with the process. The "rolling 60-day window" comment in `medication_scheduler_service.dart:115` implies the window refreshes daily, but in reality it only refreshes when the user re-opens the app (the startup path in `main.dart:42-58` re-runs the same logic).

For users who open the app daily this is fine. For users who go a week without opening it, the trailing edge of the 60-day window stops sliding, and on day 60 they run out of pre-scheduled reminders entirely until they re-open the app.

**Suggested fix.** The midnight Timer is fundamentally the wrong mechanism. Either:
1. **Schedule a no-op self-wake notification** at 3 AM every few days that, when the system fires it, triggers a re-schedule via the notification response handler. (Survives app being killed because the OS owns the schedule.)
2. **Schedule a much further-out window** (e.g. 180 days) so the trailing edge is irrelevant in practice — accepting the iOS-cap tradeoff (see #1).
3. **Use Android `WorkManager` / iOS background fetch** for a true daily wake. Heaviest lift but most correct.

---

## Issue 6 — OEM battery optimization unaddressed

**Severity:** Medium.
**Where:** No code path addresses this.

**Current behavior.** None — the app does not detect or message about OEM-specific background kills.

**Why it's risky.** Xiaomi (MIUI), OnePlus (OxygenOS pre-13), Huawei (EMUI), Samsung (One UI's "Sleeping apps"), and others **aggressively kill backgrounded apps regardless of `SCHEDULE_EXACT_ALARM`**. Reminders stop firing after the app has been backgrounded for a few days. There's no error, just silence — the user often blames themselves for forgetting their pills.

**Suggested fix.** Code-side this is mostly a UX problem. Detect the manufacturer via `device_info_plus` and, for known-aggressive OEMs, show a one-time onboarding card pointing the user at the right settings page (e.g. MIUI: "Settings → Battery & performance → Manage apps' battery usage → PinkRain → No restrictions"). The [`dontkillmyapp.com`](https://dontkillmyapp.com) docs have per-OEM instructions worth linking.

---

## Issue 7 — `String.hashCode` not guaranteed stable across SDK versions

**Status:** Fixed in commit `ebd85ff` on `feat/notifications-hardening`.
**Severity:** Medium.
**Where:** `lib/features/treatment/services/medication_scheduler_service.dart:744` (`medicationId.hashCode ^ scheduledTimeMs.hashCode`).

**Current behavior.** Notification IDs are derived from `String.hashCode`. They are persisted to Hive and re-used to cancel previously-scheduled notifications.

**Why it's risky.** Dart's specification only guarantees `hashCode` consistency within the same Dart isolate's lifetime — it does not promise stability across SDK versions, and in practice `String.hashCode` has changed between Dart releases before. After a Flutter SDK upgrade, the ID produced by `_generateNotificationId` for a given input may differ from the ID previously persisted, which would orphan whatever the OS still has scheduled under the old ID. The cleanup paths (`cancelNotificationsForTreatment`, `_cleanupPassedNotifications`) read IDs from Hive rather than recomputing, so existing cancels still work — but new schedules end up creating a duplicate alongside the orphan.

**Suggested fix.** Stop using `hashCode`. Use a stable hash:
```dart
import 'package:crypto/crypto.dart';
final bytes = utf8.encode('$medicationId|$scheduledTimeMs');
final digest = sha1.convert(bytes);
return digest.bytes.fold<int>(0, (a, b) => ((a << 8) | b) & 0x7FFFFFFF);
```
Or, since IDs are 32-bit signed ints anyway, just adopt a sequential counter persisted in Hive keyed by the `${medicationId}_${scheduledTimeMs}` composite — slower but deterministic across SDK upgrades.

---

## Issue 8 — In-memory dedupe state evaporates on process recreation

**Status:** Fixed in commit `1e2d823` on `feat/notifications-hardening`.
**Severity:** Medium.
**Where:** `lib/features/treatment/services/medication_notification_service.dart:31-36` (`_notifiedMedicationIds`, `_lastScheduleTime`, `_lastMedicationCount`).

**Current behavior.** The "have we already notified for this medication today?" set lives in instance memory on a singleton. iOS aggressively recreates app processes under memory pressure, and singletons don't survive that — the set comes back empty even though the OS still holds the scheduled notifications.

**Why it's risky.** When the process is recreated mid-day, the next call to `scheduleMedicationNotifications` may treat already-notified medications as fresh and add immediate "you missed it" notifications for doses the user has already taken (or already been notified for). Result: duplicate or stale notifications.

**Suggested fix.** Persist `_notifiedMedicationIds` to Hive, keyed by date. Read on init, write on each addition. The set naturally clears at midnight via the existing `resetDailyNotifications` call — just point it at the Hive box instead of the in-memory set.

---

## Issue 9 — `BIND_NOTIFICATION_LISTENER_SERVICE` declared but unused

**Status:** Fixed in commit `fad9d68` on `feat/notifications-hardening`.
**Severity:** Low.
**Where:** `android/app/src/main/AndroidManifest.xml:7`.

**Current behavior.** Manifest declares `<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />`. No code in the app implements `NotificationListenerService` or references this permission.

**Why it's risky.** This is the heavyweight permission used by apps that need to **read other apps' notifications** (typically wearable companions, accessibility tools, automation apps). Google Play's policy team flags it as a sensitive permission and may require additional review and justification on each app submission. Declaring it without using it is gratuitous risk.

**Suggested fix.** Remove the line. Confirm no plugin transitively requires it (`flutter pub deps | grep notification_listener` or similar).

---

## Issue 10 — No "send test notification" UI for users to self-verify

**Status:** Fixed in commit `524afd1` on `feat/notifications-hardening`.
**Severity:** Low.
**Where:** `lib/features/profile/presentation/profile.dart` (no such button exists). The plumbing already exists at `push_notifications.dart:212-248` (`showImmediateNotification`).

**Current behavior.** Users have no way to verify that notifications actually fire on their device without waiting for a real dose time.

**Why it matters.** Combined with #1, #2, #3, #6 — most ways notifications silently fail are invisible to the user. A "send test notification in 30 seconds" button is the cheapest possible diagnostic: if the test fires, the OS-side plumbing works; if it doesn't, the user knows to check permissions before they miss a real dose.

**Suggested fix.** Add a `ListTile` in the Profile → Notifications section: "Send test reminder (30s)". On tap, schedule a one-shot notification via `_schedulerService.scheduleMedicationNotifications` (or directly via `NotificationService.schedulePillReminder`) for `DateTime.now().add(Duration(seconds: 30))`. Cleaner UX than the existing dev-only `showImmediateNotification`.

---

## Suggested verification approach

For any of the fixes above, the realistic verification path without a clinical-grade test rig:

1. **Static / unit:** add tests against the iOS-cap windowing logic (#1), the inexact fallback (#2), and the hashCode replacement (#7). These are pure functions and trivially testable.
2. **Smoke on a real iPhone:** add 5+ treatments with 2 doses each, observe via Xcode's Console for `UNNotificationRequest` actually being scheduled (the OS will report when it drops over-cap notifications).
3. **Smoke on a real Android:** install on a Xiaomi or OnePlus device, leave backgrounded for 3 days, observe whether scheduled reminders fire.
4. **Permission revocation:** in Android system settings, toggle off "Alarms & reminders" mid-session, then trigger a reschedule from the app, and observe whether the inexact fallback engages (#2/#3).
5. **DST:** advance the device clock past a DST boundary and observe whether wall-clock time of pending notifications shifts correctly (#4).

None of this requires more than a few hours per platform.
