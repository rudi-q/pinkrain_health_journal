# Changelog

All notable changes to PinkRain will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.4] - 2025-12-12

### Fixed
- **Personalized insights race condition**: Fixed issue where overlapping async calls to generate insights could cause stale data to overwrite newer results by introducing a generation token mechanism
- **Batch medication I/O**: Optimized medication data loading with batched I/O operations for better performance

### Changed
- **Wellness insights loading**: Optimized loading performance for wellness insights
- **Chart descriptions**: Improved chart descriptions and dynamic chart titles
- **Adherence documentation**: Updated adherence-related documentation
- **Retry button styling**: Updated wellness screen retry button and error states to match PinkRain style

---

## [2.3.3] - 2025-11-25

### Fixed
- **Duplicate notifications**: Fixed issue where notifications were being scheduled multiple times, causing duplicate notifications to appear
- **Notification deduplication**: Improved duplicate prevention logic to check storage, system, and current call before scheduling
- **Deterministic notification IDs**: Changed notification ID generation to be deterministic based on medication ID and scheduled time, ensuring rescheduling replaces existing notifications instead of creating duplicates

### Technical Improvements
- Removed redundant notification listener that was causing duplicate scheduling calls
- Enhanced duplicate prevention with multiple layers of checks (storage, system, in-call tracking)
- Improved notification ID generation to prevent system-level duplicates

## [2.3.2] - 2025-11-17

### Added
- **App version display**: Added version number display to profile page for easy reference

### Fixed
- **Profile icon**: Fixed missing profile icon in wellness screen (replaced with HugeIcons.strokeRoundedUser)

## [2.3.1] - 2025-11-07

### Fixed
- **Notification scheduling**: Fixed notifications not working when app wasn't opened during the day
- **Endless scheduling bug**: Fixed bug where notifications were being scheduled for years in the future (2026-2029)
- **Notification window**: Implemented 60-day rolling window for notification scheduling to balance coverage and performance
- **Medicine name in notifications**: Fixed notification titles to display actual medicine names instead of numerical IDs
- **Notification cleanup**: Improved cleanup logic to remove notifications beyond the 60-day window
- **Notification restoration**: Enhanced restore logic to only restore notifications within the 60-day window and correctly extract medicine names

### Changed
- **Notification scheduling strategy**: Changed from scheduling entire treatment duration to a 60-day rolling window with daily refresh
- **Deduplication logic**: Refined notification deduplication to only remove notifications being replaced, preventing unnecessary churn

### Technical Improvements
- Improved notification scheduling service with better date validations and safety limits
- Enhanced restore logic with treatment lookup and fallback mechanisms
- Added comprehensive debug logging for notification scheduling and restoration

## [2.3.0] - 2025-11-02

### Added
- **Multiple doses per day**: Treatments can now have multiple scheduled doses throughout the day
- **Unlimited duration option**: Treatments can be set with unlimited duration (no end date)
- **Delete all data functionality**: Added ability to delete all user data from the app
- **iOS status bar support**: Proper status bar styling across all screens for iOS devices
- **Edit and delete mood notes**: Users can now edit and delete their mood journal notes
- **Dismissible mood prompts**: Mood journal prompts can be dismissed

### Changed
- **24-hour time format**: Standardized time display to 24-hour format across all treatment screens
- **Notification system**: Major refactoring of notification handling with improved separation of concerns
- **ColorPicker enhancements**: Added support for nullable colors and customizable itemSize parameter
- **Month arithmetic**: Improved date calculations for treatment durations
- **Profile screen**: Enhanced profile screen with better data management and UI improvements
- **Pillbox integration**: Enhanced UI/UX for pillbox interactions
- **Disclaimer improvements**: Enhanced disclaimer service and overlay UI

### Fixed
- **Duplicate notifications**: Resolved issues with duplicate medication notifications being sent
- **Notification reliability**: Enhanced notification scheduling
- **Notification response handling**: Improved notification action handling

### Technical Improvements
- Refactored notification response handler with improved architecture
- Enhanced medication scheduler service with better duplicate prevention
- Improved treatment manager to support new treatment features
- Updated journal log handling to support multiple doses per day
- Added comprehensive test coverage for notification handling

## [2.2.0] - 2025-10-29

### Added
- "Today" button in journal date selector for quick navigation back to current date
- Icon to "Add Note" button in journal entry dialog
- Granular delete options for treatments (just this occurrence, from this date onwards, all occurrences)

### Changed
- Replaced custom SVG icons with HugeIcons throughout bottom navigation for better consistency
- Bottom navigation now uses modern HugeIcons with proper color states (primary/secondary)
- Improved journal date navigation to support scrolling backwards to past dates
- Enhanced treatment creation/edit UX with persistent cursor and better form handling
- Updated treatment duration to support different units (days/weeks/months) with proper conversion
- Improved day labels (M/Tu/W/Th/F/Sa/Su) clarity throughout treatment screens
- Journal time ranges updated: Morning (0-12pm), Night (9pm-11:59pm)
- Date picker in edit treatment now allows past dates (removed minimumDate constraint)

### Fixed
- Fixed journal medication display when creating/editing treatments
- Fixed journal log creation to properly add new treatments to dates with existing logs
- Fixed data refresh after treatment deletion to immediately reflect changes
- Fixed navigation to properly close both edit screen and treatment overview modal after deletion
- Fixed treatment duration text field cursor persistence
- Fixed string interpolation linter warnings

### UI/UX Improvements
- Replaced delete treatment AlertDialog with PinkRain-styled bottom modal
- Adjusted bottom navigation icon sizing and spacing to prevent overflow
- Improved visual feedback in date selector
- Better alignment and spacing throughout treatment management screens