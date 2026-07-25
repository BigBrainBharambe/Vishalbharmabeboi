# Codemagic setup — build an `.ipa`

This project is configured with `codemagic.yaml` for Flutter iOS builds.

**Bundle ID:** `com.vishalbharambe.expensetracker`  
**App display name:** Expense Tracker

## Workflows

| Workflow | Purpose | Output |
|----------|---------|--------|
| `ios-unsigned` | Verify CI compiles (no Apple account needed) | `.app` (debug) |
| `ios-ipa` | Signed App Store IPA | `.ipa` download / TestFlight-ready |
| `ios-ipa-adhoc` | Signed Ad Hoc IPA for registered devices | `.ipa` download |

Start with **`ios-unsigned`**. When that is green, set up signing and run **`ios-ipa`**.

---

## 1. Connect the repo in Codemagic

1. Go to [codemagic.io](https://codemagic.io) and sign in (GitHub).
2. **Add application** → select `BigBrainBharambe/Vishalbharmabeboi`.
3. Project type: **Flutter App**.
4. Open the app → scan branch `cursor/expense-tracker-a654` for `codemagic.yaml`.

---

## 2. Apple Developer prerequisites

You need an **Apple Developer Program** membership ($99/year).

### Create the App ID

1. [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Add App ID → Bundle ID: `com.vishalbharambe.expensetracker`
3. (Optional) Create the app in [App Store Connect](https://appstoreconnect.apple.com) with the same bundle ID

### Create an App Store Connect API key

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**
2. Generate a key with **App Manager** access
3. Download the `.p8` file (once only)
4. Note **Issuer ID** and **Key ID**

### Add the API key in Codemagic

1. Codemagic → **Team settings** → **Team integrations** → **Developer Portal** → **Manage keys**
2. **Add key**
   - **Name:** `ExpenseTracker` (must match `integrations.app_store_connect` in `codemagic.yaml`)
   - Enter Issuer ID + Key ID
   - Upload the `.p8` file

---

## 3. Code signing files

Codemagic → **Team settings** → **codemagic.yaml settings** → **Code signing identities**

### Certificate

1. Open **iOS certificates**
2. Prefer **Generate certificate** → type **Apple Distribution** → use the `ExpenseTracker` API key  
   **or** upload an existing `.p12` Distribution certificate

### Provisioning profile

1. Open **iOS provisioning profiles**
2. **Fetch profiles** (or create in Apple Developer Portal and upload)
3. For `ios-ipa`: use an **App Store** profile for `com.vishalbharambe.expensetracker`
4. For `ios-ipa-adhoc`: use an **Ad Hoc** profile that includes your iPhone’s UDID

---

## 4. Build the `.ipa`

1. In Codemagic, open the app → **Start new build**
2. Select branch `cursor/expense-tracker-a654`
3. Select workflow **`ios-ipa`**
4. When the build finishes, download **`*.ipa`** from Artifacts (also emailed on success)

### Install on iPhone

- **App Store IPA** → upload to TestFlight (uncomment publishing in `codemagic.yaml`) or use transporter / Codemagic App Store Connect publishing
- **Ad Hoc IPA** → install via Apple Configurator, Xcode Devices, or a tool like Diawi / Firebase App Distribution (device must be in the Ad Hoc profile)

---

## 5. Optional: auto-upload to TestFlight

1. Create the app in App Store Connect and note its numeric **Apple ID**
2. In `codemagic.yaml` under `ios-ipa` → `environment.vars`, set:
   ```yaml
   APP_STORE_APPLE_ID: "YOUR_NUMERIC_ID"
   ```
3. Uncomment the `publishing.app_store_connect` block in `ios-ipa`

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Integration not found | API key name in Codemagic UI must be exactly `ExpenseTracker` |
| No matching profile | Upload/fetch an App Store (or Ad Hoc) profile for `com.vishalbharambe.expensetracker` |
| Certificate limit | Apple allows max 3 Distribution certs — revoke an unused one or upload an existing `.p12` |
| Pod install fails | Ensure `ios/Podfile` is in the repo (it is) and CocoaPods is `default` in the workflow |
| Bundle ID mismatch | Xcode project and Codemagic `bundle_identifier` must both be `com.vishalbharambe.expensetracker` |

## Docs

- [Codemagic Flutter apps](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/)
- [Signing iOS apps](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
- [First signed build](https://docs.codemagic.io/yaml-quick-start/first-signed-build/)
