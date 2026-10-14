# OEM Battery & Notification Optimization Guide

This guide documents the exact OEM settings required on the owner's Android device to guarantee real-time push notification delivery and audible alerts when the app is killed, the screen is turned off, or the device enters deep Doze mode.

---

## 1. Context & Architecture Requirements

Per `PRD.md` §3.6 (A-35) and `TASKS.md` Task **Push-4**:
- The Slice & Serve Admin app relies on high-priority Firebase Cloud Messages (FCM) and the custom `sns_new_orders` notification channel (`order_alert.wav` custom audio asset).
- Many Android OEMs (particularly Samsung, Xiaomi, OnePlus, and Oppo) implement aggressive proprietary task killers and battery management systems on top of standard AOSP Doze. If unconfigured, these systems can:
  1. Freeze or terminate background message receivers.
  2. Throttle network socket connections while the screen is locked.
  3. Demote or silence notifications when the app has not been manually opened for several hours or days ("Sleeping apps").

---

## 2. Samsung Galaxy / One UI (Tested Target: Samsung Galaxy S21 FE 5G, Android 16 / API 36)

The primary testing device is the **Samsung Galaxy S21 FE 5G** (`SM-G990B2`, Android 16 / One UI). Follow these steps to ensure order alerts are never delayed or suppressed:

### Step 1: Set App Battery Usage to "Unrestricted"
1. Open **Settings** on the Samsung device.
2. Tap **Apps** (or **Application Manager**).
3. Scroll to and tap **Slice & Serve Admin** (`com.example.adminapp`).
4. Tap **Battery**.
5. Select **Unrestricted** (the default is *Optimized*).
   > **Effect:** Allows the app to run background network and notification operations without Samsung power throttling.

### Step 2: Prevent Samsung from Putting the App to Sleep or Archiving
1. Open **Settings** > **Battery** (or **Device Care** > **Battery**).
2. Tap **Background usage limits**.
3. Tap **Never auto-sleeping apps**.
4. Tap the **+** (Add) icon in the top right corner.
5. Search for and select **Slice & Serve Admin**, then tap **Add**.
   > **Effect:** Samsung's Adaptive Battery will never move the app into "Sleeping apps" or "Deep sleeping apps" regardless of how long the phone sits idle.

### Step 3: Turn Off "Manage app if unused"
1. In **Settings** > **Apps** > **Slice & Serve Admin**, tap **Permissions**.
2. Scroll to the bottom to find **Manage app if unused** (or **Pause app activity if unused**).
3. Toggle this setting **OFF**.
   > **Critical for Kitchen Operation:** By default, Samsung One UI enables this toggle, which explicitly states it will *"stop notifications and archive the app"* if the app is not manually opened for a certain period. Keeping this OFF guarantees notifications will never be silenced during quiet business hours or seasonal lulls.

### Step 4: Configure Notification Channel Priority & Pop-up
1. Open **Settings** > **Notifications** > **App notifications**.
2. Tap **Slice & Serve Admin**.
3. Ensure **Allow notifications** is toggled **ON**.
4. Tap **Notification categories** at the bottom.
5. Tap **New Orders** (the channel ID `sns_new_orders` created by the app).
6. Verify:
   - **Alert:** Selected (sound and vibration).
   - **Pop-up (Heads-up banner):** Toggled **ON**.
   - **Sound:** Set to `order_alert` (custom sound bundled in the APK).
   - **Lock screen:** Set to **Show content**.
   - *(Optional for night/kitchen operation)* **Ignore Do Not Disturb:** Toggle **ON** if the restaurant operates during scheduled DND hours.

---

## 3. Xiaomi / Redmi / POCO (MIUI / HyperOS)

1. **Autostart:**
   - Go to **Settings** > **Apps** > **Permissions** > **Autostart**.
   - Turn **ON** for **Slice & Serve Admin**.
2. **Battery Saver:**
   - Go to **Settings** > **Apps** > **Manage apps** > **Slice & Serve Admin** > **Battery saver**.
   - Select **No restrictions** (do not use *MIUI Battery saver*).
3. **Lock in Recents:**
   - Open Recent Apps tray, press and hold **Slice & Serve Admin**, and tap the **Lock** icon.

---

## 4. OnePlus / Oppo / Realme (OxygenOS / ColorOS / Realme UI)

1. **Background Activity:**
   - Go to **Settings** > **Battery** > **More battery settings** > **Optimize battery use**.
   - Select **Slice & Serve Admin** > **Don't optimize**.
2. **App Auto-Launch:**
   - Go to **Settings** > **Apps** > **Auto-launch** (or **App management** > **Slice & Serve Admin** > **Battery usage**).
   - Enable **Allow background activity** and **Allow auto-launch**.

---

## 5. Stock Android / Google Pixel

1. **Battery Optimization:**
   - Go to **Settings** > **Apps** > **Slice & Serve Admin** > **App battery usage**.
   - Select **Unrestricted**.
2. **Notifications:**
   - Ensure the **New Orders** notification channel is set to **Default / High** (not Silent).

---

## 6. Developer & Acceptance Verification Commands (ADB)

To verify the app's resilience under power-saving modes during development and QA:

```bash
# Check current standby bucket (20 = WORKING_SET, 10 = ACTIVE)
adb -s <DEVICE_ID> shell am get-standby-bucket com.example.adminapp

# Whitelist app in battery optimization via adb
adb -s <DEVICE_ID> shell dumpsys deviceidle whitelist +com.example.adminapp

# Force device into deep Doze mode while app is killed and screen off
adb -s <DEVICE_ID> shell am force-stop com.example.adminapp
adb -s <DEVICE_ID> shell input keyevent KEYCODE_POWER
adb -s <DEVICE_ID> shell dumpsys deviceidle force-idle deep

# Confirm device is in IDLE state
adb -s <DEVICE_ID> shell dumpsys deviceidle get deep

# Trigger notification launch intent
adb -s <DEVICE_ID> shell am start -n com.example.adminapp/.MainActivity -a SELECT_NOTIFICATION --es payload "order_new"

# Unforce Doze and restore normal power state
adb -s <DEVICE_ID> shell dumpsys deviceidle unforce
adb -s <DEVICE_ID> shell input keyevent KEYCODE_WAKEUP
adb -s <DEVICE_ID> shell wm dismiss-keyguard
```
