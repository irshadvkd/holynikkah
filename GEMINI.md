# Application Flow Rules

This document outlines the mandatory authentication, registration, and setup flow. The agent must adhere to and respect these rules when modifying onboarding, login, registration, or screen routing in the app.

---

## Authentication & Registration Flow

The user onboarding and onboarding recovery flow is identical for both **Normal** and **VIP** registers.

```mermaid
graph TD
    A[Register / Vip Register Tab - Unauthenticated] --> B[Login Screen - Enter Mobile]
    B --> C[OTP Verification Screen]
    C --> D{Is User Registered?}
    D -->|No| E[Registration Screen]
    E --> F{Category Selected?}
    D -->|Yes| F
    F -->|No| G[Category Selection Screen - Selection Required]
    G -->|Select & Save to DB| H{Template Selected?}
    F -->|Yes| H
    H -->|No| I[Template Selection Screen]
    I -->|Select & Save| J[Profiles View]
    H -->|Yes| J
```

### 1. Direct Login (Unauthenticated State)
- **Behavior**: When unauthenticated users access the Register or Vip Register tab, directly show the Login screen without any initial dummy category preview.
- **Back Button**: When embedded in the main tab navigation, the back button is hidden.

### 2. Login & OTP Verification
- **Login**: User enters their mobile number.
- **OTP Screen**: Verifies the code.
- **Registration check**:
  - If **not registered**: Redirect the user to the Register page.
  - If **already registered**: Check database state to restore/determine progress.

### 3. Onboarding Steps Completion (Mandatory Gatekeeping)
Once registered, the app must sequentially verify and gate the user through the following setup steps before they can view partner profiles:

1. **Category Selection**:
   - Check if a category is selected in the database.
   - If **not selected**: Show the Category Selection screen (with `isSelectionRequired: true`). Once selected, save choice via API.
   - If **selected**: Proceed to template check.
2. **Template Selection**:
   - Check if a profile template is selected.
   - If **not selected**: Show the Template Selection screen. Once selected, save choice.
   - If **selected**: Proceed to the main profiles screen.

---

## App Initialization / App Restart Verification Rule

Whenever the application initializes, restores session, or recovers from a background/restart state:
- The app **must verify** that the complete sequence is fully satisfied (Registered -> Category Selected -> Template Selected) before displaying the Partner Profiles view.
- Until all requirements are met, the corresponding onboarding screen for that step must block the user. This is a mandatory gate.
