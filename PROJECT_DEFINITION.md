# Magical Community – Project Definition & Technical Overview

## 1. Project Summary
+-

## 2. Core Value Proposition
- Unified dashboard for member lifecycle (visitor → trial → active member)
- Subscription + payment tracking with dues and payable calculations
- Shake consumption & nutrition tracking per user/day (consumption + due counts)
- Attendance logging & membership status insight (active/expiring/expired)
- Inventory logging and reporting
- Centralized error + session handling for reliability in production contexts

## 3. Architecture Overview
The project follows a layered & feature-oriented structure:

```
lib/
  core/        → Cross-cutting concerns (config, network, error, services, storage, theme, utils)
  data/        → Secondary/shared raw model fragments (support models referenced by domain models)
  models/      → Domain entities persisted with Hive + runtime-only enrichments
  screens/     → UI feature modules (auth, splash, member mgmt, etc.)
  widgets/     → Reusable UI components
```

### 3.1 Application Entry
- `main.dart` initializes Flutter bindings, Hive storage, and launches `MyApp`.
- Global navigation handled via `NavigationService` using a `navigatorKey` (supports dialog + route control outside widget tree).

### 3.2 State Management
- Uses `flutter_bloc` (BLoC pattern) for predictable event → state flow (files not scanned individually here; assumed pattern given dependency). Recommended to document each feature bloc in a future appendix.

### 3.3 Data & Persistence Layer
- Local persistence: Hive (`hive` + `hive_flutter`) for offline caching of user + model entities.
- Adapters (commented registration hints in `main.dart`) indicate planned/generated type adapters for each domain entity (e.g., `UserModelAdapter`, `PaymentModelAdapter`, etc.). Generated `*.g.dart` files exist confirming code-gen via `build_runner`.
- Runtime-only composite fields (e.g., `upcomingSubscription`, `attendanceSummary`) deliberately excluded from Hive to keep storage lean.

### 3.4 Networking Layer
- HTTP client: `dio` with layered interceptors:
  - `AuthInterceptor` (not opened here, expected for token injection + 401 handling)
  - Retry-on-timeout interceptor `_RetryOnTimeoutInterceptor` (single retry for connection/receive timeouts)
  - `PrettyDioLogger` for structured logging (request/response bodies in dev & possibly prod — consider gating by environment).
- Environment resolution via `Env`:
  - `ENVIRONMENT` (`dev` | `prod`), overrideable with `API_BASE_URL`.
  - Timeout parameters configurable via `--dart-define`.

### 3.5 Error & Session Handling
- Central `ErrorHandler` prevents duplicate dialogs and manages session expiry with:
  - 401 → force logout (token cleared) + redirect to `LoginScreen`.
  - Timeout aggregation: 2 timeouts inside rolling 60s triggers forced session reset.
  - Dialog hygiene: prevents stacking, resets counters.

### 3.6 Theming & UI
- `AppTheme` (not opened here) defines color palette + typography. Light mode enforced (ThemeMode.light) – scope for dark mode extension.
- Uses Material 3 icons + `cupertino_icons` where appropriate.
- Widgets likely use global snackbars + dialogs through `NavigationService` for non-context-specific messaging.

### 3.7 Security & Tokens
- `TokenStorage` (file not opened here) inferred for secure persistence of auth credentials (likely Hive or SharedPreferences). Recommend optional migration to `flutter_secure_storage` for sensitive tokens if not already encapsulated.

## 4. Domain Model Highlights
### 4.1 UserModel (Excerpt)
Captures full member lifecycle & operational metrics:
- Identity: `id`, `name`, `mobileNumber`, optional `email`
- Role & type: `UserType (visitor/trial/member)`, `UserRole (member/coach/seniorCoach)`
- Lifecycle dates: visit, trial, membership start/end
- Financials: `totalPaid`, `pendingDues`, `totalPayable`, `dueAmount`
- Subscription state: `subscription`, `upcomingSubscription`, `activeMembership`
- Operational analytics: shake due vs consumed (`totalDueShake`, `totalConsumedShake`)
- Status helpers: derived Booleans + `statusText` for UI classification

Other models present (based on filenames):
- `attendance_model`, `inventory_model`, `payment_model`, `settings_model`, `shake_entry_model`, `consumption_model`, `consumption_group_model`, `api_product_model` – representing attendance logs, inventory operations, payment records, configuration/settings, and shake/nutrition grouping.

## 5. Environment & Build Configuration
| Aspect | Mechanism |
|--------|-----------|
| Environment Selection | `--dart-define=ENVIRONMENT=prod|dev` |
| API Override | `--dart-define=API_BASE_URL=...` |
| Timeouts | `--dart-define=API_CONNECT_TIMEOUT_MS`, `API_RECEIVE_TIMEOUT_MS` |
| Versioning | `pubspec.yaml` → `version: 1.0.6+9` |
| Icons | Managed via `flutter_launcher_icons` (multi-platform config) |
| Assets | Declared under `assets/icons/` |
| Min Android SDK | 21 (launcher icons config) |

## 6. Tooling & Code Generation
- Hive adapters + model serialization via `build_runner`.
- Icon generation via `flutter_launcher_icons` CLI.
- Potential future additions: Freezed / JsonSerializable to reduce manual model code duplication.

## 7. Error Handling Strategy Summary
| Scenario | Behavior |
|----------|----------|
| 401 Unauthorized | Clear token → show session expired dialog → navigate to login |
| Duplicate Error (within 2s) | Suppressed |
| 2 Timeouts / 60s window | Force logout (assumed network instability) |
| Single Timeout | Soft ignored (UI layer may show inline loader) |

## 8. Navigation Strategy
- Centralized imperative navigation via a singleton `NavigationService` (suitable for events triggered from BLoC, interceptors, async layers).
- Provides: push, replace, clear stack, dialogs, and snackbars.
- Future improvement: typed route registry or `go_router` migration.

## 9. Performance Considerations
Current optimizations observed / inferred:
- Limited retry (avoids cascading API storms)
- Hive for fast local reads
- Derived/computed getters instead of recomputation heavy logic
Potential enhancements:
- Cache invalidation strategy documentation for network→Hive sync
- Background prefetching for high-traffic lists
- Fine-grained state segmentation in BLoCs to reduce rebuilds

## 10. Testing Status
- Present: default `widget_test.dart` (scaffold template). No evident custom unit/integration tests yet.
Recommended next steps:
1. Add domain-level unit tests (UserModel helpers, error handling edge cases).
2. Integrate golden tests for critical UI flows (login, dashboard, shake entry).
3. Mock `Dio` client for repository-layer tests.

## 11. Release & Deployment
Artifacts in root (e.g., `MagicalCommunity-PlayStore-v20250918-0052.aab`) indicate Play Store-ready signed bundles. Scripts & docs:
- `build_appbundle.ps1`, `build_release.ps1` – automated build pipelines
- Fastlane directory present for potential iOS/App Store automation
- Release notes: versioned file `RELEASE_NOTES_v1.0.4.md` (semantic doc practice – advisable to update for 1.0.6+9).

## 12. Scripts & Automation
| Script | Purpose |
|--------|---------|
| `build_appbundle.ps1` | Produces production AAB with env define |
| `cleanup_project.ps1/.sh` | Cross-platform cleanup (likely flutter clean + cache prune) |
| `generate_icon.dart / create_simple_icon.dart` | Programmatic icon asset generation |
| Fastlane (`fastlane/`) | CI/CD pipeline scaffolding |

## 13. Logging & Observability
- Network logging via `PrettyDioLogger` (JSON bodies + headers except response headers)
- Missing: crash reporting (Sentry/Firebase Crashlytics) – candidate enhancement
- Missing: analytics events (user behavior / funnel tracking)

## 14. Security & Privacy Considerations
Current:
- Session/Auth token handling via interceptor + centralized invalidation.
Gaps / Suggestions:
- Secure storage for tokens (if not already in `TokenStorage`)
- PII minimization audit (mobileNumber, health-related fields like disease)
- Add app-level privacy policy reference within settings screen

## 15. Pending / Potential Enhancements
| Area | Recommendation |
|------|----------------|
| Navigation | Consider declarative routing (`go_router`) for deep links & web support |
| Testing | Establish CI with test + `flutter analyze` + formatting gate |
| Dark Mode | Add `ThemeMode.system` option with persistent user preference |
| Error UX | Inline error surfaces (less modal reliance) for list/data screens |
| Offline Mode | Add network reachability + retry queueing |
| Performance | Memoize expensive list transformations in BLoCs |
| Security | Add crash + analytics + secure token storage |
| Documentation | Per-feature README in each `screens/<feature>` folder |

## 16. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Overuse of global navigation | Harder deep-linking & test mocking | Abstract behind interface / adopt declarative router |
| Lack of tests | Regression risk | Introduce incremental test coverage per release |
| Direct logger in prod | Potential PII exposure | Gate logs by `Env.isProd` flag |
| Timeout-based forced logout | False positives on slow networks | Track success events to reset counters sooner |

## 17. Suggested Next Actions (Actionable Backlog)
1. Add `PROJECT_DEFINITION.md` (this file) to version control and keep updated each release.
2. Create `ARCHITECTURE_DECISIONS.md` and start logging ADRs (routing strategy, persistence choices, error model).
3. Introduce `Makefile` or unified `tooling.dart` script for build/test/lint tasks.
4. Implement test harness for `ErrorHandler` edge cases.
5. Add environment banner (e.g., a subtle dev ribbon when not prod).
6. Automate CHANGELOG generation from tagged commits.

## 18. Glossary
| Term | Definition |
|------|------------|
| Visitor | A first-time or non-trial user without active membership |
| Trial | User in temporary evaluation period (trialStartDate–trialEndDate) |
| Member | Active subscription holder with paid membership window |
| Upcoming Subscription | Purchased but not yet active membership plan |
| Shake | Nutritional item tracked for due vs consumed balance |

## 19. Maintenance Guidelines
- Run `flutter pub upgrade --major-versions` quarterly with regression tests.
- Keep Hive typeIds stable—never reorder or reuse removed IDs.
- When adding models: define adapters, register before `runApp`.
- Validate all network additions with timeout + error surfaces through `ErrorHandler`.

## 20. Metadata
| Field | Value |
|-------|-------|
| Current App Version | 1.0.6+9 |
| Primary API (Prod) | https://api.magicalcommunity.in/api/rest |
| Default Dev API | https://mgc-api-dev.onrender.com/api/rest |
| SDK Constraint | Dart ^3.8.1 |

---
Maintained as a living document. Update sections 3–5 & 14–17 with each material architectural or dependency change.
