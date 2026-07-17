# Contributing to ParkiWell

Thank you for your interest in contributing to ParkiWell.

## Development Setup

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or Xcode
- Git

### Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/parkiwell.git
   cd parkiwell
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/Jc-965/parkiwell.git
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run \
     --dart-define=BACKEND_PROVIDER=supabase \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
     --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.parkiwell.app://login-callback/
   ```

## Branch Strategy

We use a simplified Git Flow:

- `main` - Production-ready code
- `staging` - Pre-production testing
- `develop` - Development integration branch
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Production hotfixes

### Creating a Branch

```bash
# For features
git checkout develop
git pull upstream develop
git checkout -b feature/your-feature-name

# For bug fixes
git checkout develop
git pull upstream develop
git checkout -b bugfix/issue-description
```

## Code Standards

### Formatting

- Run `dart format lib/` before committing
- Use 2-space indentation
- Maximum line length of 80 characters

### Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `camelCase` or `SCREAMING_SNAKE_CASE`
- Private members: `_prefixedWithUnderscore`

### Code Organization

```
lib/
├── config/          # Environment/backend configuration
├── Main/            # Main tab screens
├── Manage/          # Symptom + medication flows
├── Recovery/        # Recovery exercise flows
├── screens/         # Intro/splash and shared entry screens
├── services/        # Cloud backend, logging, moderation, state services
├── theme/           # Theme and color system
├── utils/           # Utility functions
└── widgets/         # Reusable UI components
```

## Pull Request Process

1. Ensure your code passes all checks:
   ```bash
   flutter analyze
   flutter test
   dart format --set-exit-if-changed lib/
   ```

2. Update documentation if needed
   - Backend changes: update `docs/BACKEND_SETUP.md` and `supabase/schema.sql`
   - Content source updates: update `docs/CONTENT_SOURCES.md`

3. Create a pull request with:
   - Clear title describing the change
   - Description of what and why
   - Link to related issues
   - Screenshots for UI changes

4. Wait for CI checks to pass

5. Request review from maintainers

## Commit Messages

Use clear, descriptive commit messages:

```
type: short description

Longer description if needed.

Closes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

## Testing

- Write tests for new features
- Ensure existing tests pass
- Run tests locally before pushing:
  ```bash
  flutter test
  ```

## Questions?

Open an issue for questions or discussions about contributing.
