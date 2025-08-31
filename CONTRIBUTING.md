# 🤝 Contributing to PinkRain

Thank you for your interest in contributing to PinkRain! This document provides guidelines and information for contributors to help make the development process smooth and consistent.

## 📋 Table of Contents

- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [Development Setup](#-development-setup)
- [Contributing Guidelines](#-contributing-guidelines)
- [Coding Standards](#-coding-standards)
- [Testing Requirements](#-testing-requirements)
- [Commit Guidelines](#-commit-guidelines)
- [Pull Request Process](#-pull-request-process)
- [Areas We Need Help](#-areas-we-need-help)
- [Project Structure](#-project-structure)
- [Privacy & Security Guidelines](#-privacy--security-guidelines)

## 🤲 Code of Conduct

This project and everyone participating in it is governed by our commitment to creating a welcoming, inclusive, and harassment-free environment. By participating, you are expected to uphold these values:

- Be respectful and considerate in all interactions
- Focus on what's best for the community and users
- Show empathy towards other community members
- Respect differing viewpoints and experiences
- Give and accept constructive feedback gracefully

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Flutter**: Version 3.3.4 or higher
- **Dart**: Version 3.0 or higher
- **Git**: For version control
- **IDE**: Android Studio, VS Code, or your preferred editor
- **Device/Emulator**: For testing

### First-Time Contributors

1. **Star and Fork** the repository
2. **Read** the README.md for project overview
3. **Browse** existing issues labeled `good first issue`
4. **Join** our discussions in GitHub Discussions
5. **Ask questions** - we're here to help!

## 🛠️ Development Setup

### 1. Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/pillow-health-journal-app.git
cd pillow-health-journal-app
```

### 2. Set Up Upstream Remote

```bash
git remote add upstream https://github.com/rudi-q/pillow-health-journal-app.git
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
# Standard mode (no experimental features)
flutter run

# With experimental AI features
flutter run --dart-define=EXPERIMENTAL=true
```

### 5. Run Tests

```bash
# Run all tests
flutter test

# Run integration tests
flutter drive --target=integration_test/app_test.dart
```

## 📝 Contributing Guidelines

### Issue First Approach

- **Check existing issues** before creating new ones
- **Create an issue** for bugs, feature requests, or improvements
- **Get issue assigned** before starting work on major features
- **Reference issues** in your commits and PRs

### Branch Naming Convention

```bash
feature/issue-number-brief-description    # New features
bugfix/issue-number-brief-description     # Bug fixes
docs/brief-description                    # Documentation updates
refactor/brief-description                # Code refactoring
test/brief-description                    # Test improvements
```

**Examples:**
```bash
feature/123-medication-reminder-snooze
bugfix/456-chart-data-loading-error
docs/api-documentation-update
```

## 🎯 Coding Standards

### Dart/Flutter Standards

- **Follow** [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- **Use** `flutter analyze` to check for issues
- **Format** code with `dart format .`
- **Avoid** `print()` statements - use proper logging
- **Use** meaningful variable and function names
- **Add** documentation for public APIs

### Architecture Guidelines

PinkRain follows clean architecture principles:

```
lib/
├── core/           # Shared core functionality
├── features/       # Feature-specific modules
└── main.dart       # App entry point
```

- **Separate** UI, business logic, and data layers
- **Use** dependency injection where appropriate
- **Follow** existing patterns in the codebase
- **Keep** widgets focused and reusable

### Privacy-First Development

**CRITICAL**: All contributions must maintain our privacy-first approach:

- ✅ **NO** data collection or analytics
- ✅ **NO** network requests for personal data
- ✅ **Keep** all user data on-device
- ✅ **Use** local storage only (Hive)
- ✅ **Encrypt** sensitive data locally

## 🧪 Testing Requirements

### Required Tests

All contributions must include appropriate tests:

- **Unit tests** for business logic
- **Widget tests** for UI components
- **Integration tests** for user flows (when applicable)

### Test Guidelines

```bash
# Run tests before submitting
flutter test

# Check test coverage
flutter test --coverage
```

- **Write** tests for new features
- **Update** existing tests for changes
- **Mock** external dependencies
- **Test** error scenarios
- **Include** accessibility tests for UI changes

### Testing Experimental Features

```bash
# Test with experimental features enabled
flutter test --dart-define=EXPERIMENTAL=true
```

## 📦 Commit Guidelines

### Commit Message Format

```
type(scope): brief description

More detailed description if needed

Fixes #issue-number
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
feat(medication): add snooze functionality for reminders

Add ability to snooze medication reminders for 10, 30, or 60 minutes
with persistent notification actions.

Fixes #123

fix(charts): resolve data loading error in mood trends

Fixes null pointer exception when loading mood data with missing entries.

Fixes #456
```

## 🔄 Pull Request Process

### Before Submitting

1. **Update** your fork from upstream:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   git push origin main
   ```

2. **Rebase** your feature branch:
   ```bash
   git checkout your-feature-branch
   git rebase main
   ```

3. **Run** all checks:
   ```bash
   flutter analyze
   flutter test
   dart format . --set-exit-if-changed
   ```

### PR Requirements

- [ ] **Clear title** describing the change
- [ ] **Detailed description** of what was changed and why
- [ ] **Link** to related issue(s)
- [ ] **Screenshots** for UI changes
- [ ] **Tests** pass locally
- [ ] **No breaking changes** (or clearly documented)
- [ ] **Documentation** updated if needed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (please describe)

## Testing
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Privacy-first principles maintained
- [ ] Documentation updated

Fixes #(issue number)
```

## 🎯 Areas We Need Help

### High Priority

- 🌐 **Internationalization**: Add multi-language support
- ♿ **Accessibility**: Improve screen reader support and contrast
- 🧪 **Testing**: Increase test coverage across all features
- 📚 **Documentation**: API docs and developer guides

### Feature Areas

- 🧠 **AI/ML**: Enhance symptom prediction models
- 📊 **Analytics**: Improve wellness insights and visualizations
- 🎵 **Audio**: Expand meditation and breathing exercise content
- 💊 **Medication**: Advanced reminder and adherence features
- 🔒 **Security**: Enhanced encryption and data protection

### Code Quality

- 🏗️ **Architecture**: Refactor large files into smaller components
- ⚡ **Performance**: Optimize animations and memory usage
- 🎨 **UI/UX**: Improve user experience and design consistency
- 🐛 **Bug Fixes**: Check our issue tracker for reported bugs

## 📁 Project Structure

Understanding the codebase structure:

```
pillow-health-journal-app/
├── lib/
│   ├── core/
│   │   ├── models/          # Data models
│   │   ├── services/        # Core services (Hive, Navigation)
│   │   ├── theme/           # App theming
│   │   ├── util/            # Utilities and helpers
│   │   └── widgets/         # Reusable widgets
│   ├── features/
│   │   ├── journal/         # Mood tracking and journaling
│   │   ├── pillbox/         # Medication management
│   │   ├── wellness/        # Analytics and insights
│   │   ├── breathing/       # Breathing exercises
│   │   ├── meditation/      # Guided meditation
│   │   └── profile/         # User settings
│   └── main.dart
├── test/                    # Unit and widget tests
├── integration_test/        # Integration tests
├── assets/                  # Images, icons, audio, ML models
├── docs/                    # Project documentation
└── web/                     # Web-specific files
```

### Key Technologies

- **State Management**: Riverpod
- **Local Database**: Hive (NoSQL)
- **AI/ML**: TensorFlow Lite
- **Charts**: FL Chart
- **Audio**: Just Audio
- **Notifications**: Flutter Local Notifications
- **Navigation**: Go Router

## 🛡️ Privacy & Security Guidelines

### Privacy Requirements

All contributions must adhere to our privacy-first principles:

1. **No Data Collection**: Never collect or transmit user data
2. **Local Storage Only**: Use Hive for all data persistence
3. **No Analytics**: Don't track user behavior
4. **Transparent Code**: All functionality must be open source

### Security Guidelines

- **Encrypt** sensitive data stored locally
- **Validate** all user inputs
- **Use** secure coding practices
- **Avoid** hardcoded secrets or keys
- **Review** third-party dependencies for security

### Medical Disclaimer Compliance

Remember that PinkRain is an experimental research project:

- **Never** make medical claims
- **Include** appropriate disclaimers
- **Encourage** consulting healthcare providers
- **Maintain** educational/research focus

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and community chat
- **Email**: pillow@doubl.one for direct contact
- **Code Review**: Get feedback on draft PRs

### Documentation Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Project README](README.md)

## 🙏 Recognition

Contributors will be recognized in:

- GitHub contributors list
- Release notes for significant contributions
- Project documentation
- Community showcases

## ⚠️ Important Notes

### Experimental Features

When working with experimental features:
- Use `--dart-define=EXPERIMENTAL=true` flag
- Understand features are disabled by default
- Test both enabled and disabled states
- Document experimental functionality clearly

### Medical Context

Always remember:
- This is a research project, not medical software
- Include appropriate disclaimers
- Never replace professional medical advice
- Focus on educational and research applications

---

## 🎉 Thank You!

Your contributions help make PinkRain a better tool for mental health awareness and privacy-preserving wellness tracking. Every contribution, no matter how small, makes a difference!

**Happy coding! 🛏️💙**

---

*Made with ❤️ for mental health awareness and privacy-first development*
