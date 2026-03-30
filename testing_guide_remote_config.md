# 🧪 Comprehensive Testing Guide: Remote Config & AI Features

This guide provides step-by-step instructions to verify the implementation of feature-specific API keys and dynamic feature toggling in the Archify app.

---

## 1. 🌐 Remote Config Setup Verification
**Goal:** Ensure the Firebase console is correctly configured to provide feature-specific data.

### **Configuration Checklist**
In the Firebase Console -> Remote Config:
- [ ] **Feature Keys (KIE):** `kie_api_key_interior`, `kie_api_key_exterior`, `kie_api_key_garden`, `kie_api_key_chatbot`, etc.
- [ ] **Feature Keys (APIFree):** `apifree_key_interior`, `apifree_key_video_generation`, `apifree_key_style_transfer`, etc.
- [ ] **Enabled Flags:** `interior_enabled`, `exterior_enabled`, `video_generation_enabled`, etc. (Default: `"1"`)

> [!NOTE]  
> Values can be set as **top-level parameters** or within the `v1_home_decor` JSON blob. The app checks top-level first, then falls back to JSON.

---

## 2. 🏠 Dashboard Feature Visibility
**Goal:** Verify that the "11" flag correctly hides tools.

| Scenario | Action | Expected Result |
| :--- | :--- | :--- |
| **Hide Feature** | Set `image_generation_enabled` to `"11"`. Restart app. | The **Generate Image** card should disappear from the dashboard. |
| **Show Feature** | Set `image_generation_enabled` to `"1"`. Restart app. | The **Generate Image** card should reappear. |
| **Bulk Hide** | Set `interior_enabled` and `exterior_enabled` to `"11"`. | Both cards disappear; the grid should re-arrange smoothly without empty gaps. |

---

## 3. 🔑 API Key Assignment (Log Verification)
**Goal:** Verify that each feature uses its own specific API key from Remote Config.

1.  Connect your device to Android Studio / VS Code.
2.  Open **Logcat** (Android) or **Debug Console**.
3.  Perform the following actions and watch the logs for the specific printouts I added:

| Feature | Action | Log to Look For |
| :--- | :--- | :--- |
| **Interior** | Start an interior redesign | `🤖 Using KIE API Key for interior` (or APIFree depending on selection) |
| **Exterior** | Start an exterior revamp | `🤖 Using KIE API Key for exterior` |
| **Video** | Start video generation | `🎬 Using APIFree Key for video_generation` |
| **Style Transfer**| Start style transfer | `🎨 Using APIFree Key for style_transfer` |

---

## 4. 🛠️ Unit Testing (RemoteConfigService)
**File:** `test/services/remote_config_service_test.dart`

Run the following command to execute unit tests for the configuration logic:
```bash
flutter test test/services/remote_config_service_test.dart
```

**What to verify in tests:**
*   `isFeatureEnabled` returns `false` for `"11"` and `true` for other values.
*   `getKieApiKey` returns the specific key for a feature if it exists, else falls back to the global key.

---

## 5. 🏗️ Dashboard Grid Rendering
**Goal:** Verify the grid re-layout logic.

*   **Test Case (All Active):** Verify exactly 11 items are rendered in the dashboard.
*   **Test Case (Odd Number):** Disable 1 feature (e.g., chatbot). Verify that 10 features are shown in a 2-column grid.
*   **Test Case (Single Item):** Disable all but one feature. Verify the remaining item is rendered alone on the left side of its row.

---

## 6. ⚠️ Error Handling & Fallbacks
**Goal:** Ensure stability when config values are missing.

1.  **Missing Specific Key:** Delete `kie_api_key_interior` from Firebase. 
    *   *Result:* App should automatically fall back to the global `kie_api_key`.
2.  **Missing All Keys:** Delete both specific and global keys. 
    *   *Result:* App should gracefully show an error snackbar "API Key not found" instead of crashing.
3.  **Invalid Status:** Set a status to `"0"` or `"True"`. 
    *   *Result:* App should default to **Visible** (only `"11"` triggers hidden state).

---

## 7. 🚀 Performance Verification
**Goal:** ensure no lag during config retrieval.

*   **Cache Check:** Observe logs; once initialized, calls to `isFeatureEnabled` should not trigger new Firebase fetches (they read from `_cachedJson`).
*   **Render Speed:** Dashboard should load in **<300ms** even with feature calculation logic. UI should be jank-free while scrolling.

---

## 📸 Final Confirmation Screenshot Checklist
When reporting to the team, please attach:
1.  Firebase Console parameter list.
2.  Dashboard with all features enabled.
3.  Dashboard with `image_generation` and `chatbot` hidden.
4.  Logcat snippet showing different API keys for different features.
