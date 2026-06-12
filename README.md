# ByteLoc

ByteLoc is a simple Flutter GPS tracker that reads device location and sends it as JSON every second to a configurable HTTP endpoint.  
It is designed for demos, testing, and learning, not for production tracking.

Developed by **Ko Byte (Zay Yar Min)**.

---

## Features

- Continuous GPS tracking while the app is open.
- Detects real internet connectivity (Wi‑Fi or mobile data).
- Sends JSON payloads every 1 second to a user-defined HTTP URL.
- Editable `tid` and `deviceId` identifiers (saved on device).
- Sending automatically pauses while editing URL/tid/deviceId and resumes after saving.
- Clear “Online / Waiting for network…” status banner.
- Quit confirmation dialog when using the back button.
- Help screen explaining how to use the app.
- About dialog with version, credits, and portfolio link.

---

## JSON format

ByteLoc sends a HTTP `POST` request with `Content-Type: application/json`.

Example JSON body:

```json
{
  "lat": 16.794438,
  "lon": 94.759969,
  "tid": "te",
  "deviceId": "01",
  "tst": 1717760000,
  "mode": "http"
}
```

Fields:

- `lat` – Latitude (double).
- `lon` – Longitude (double).
- `tid` – Tracker ID (string, short ID like `te`).
- `deviceId` – Device ID (string, e.g. `01`).
- `tst` – Unix timestamp (seconds since epoch, UTC).
- `mode` – Always `"http"` (for documentation / debugging).

Your backend (for example, a PHP endpoint) can parse `php://input` as JSON and use these fields to update a database record.

---

## How to use ByteLoc

### Requirements

- Android device with:
  - Location (GPS) enabled.
  - Internet access via mobile data or Wi‑Fi.
- Flutter SDK installed (for building from source).

### Steps

1. **Run/install the app**

   ```bash
   flutter pub get
   flutter run
   ```

   Or build an APK and install it on your device.

2. **Allow permissions**

   - When ByteLoc starts, grant **Location** permission.
   - The top panel should start showing latitude and longitude.

3. **Check network status**

   - A colored banner at the top shows:
     - **Online – connected to internet** (green) when internet is available.
     - **Waiting for network…** (red) when there is no internet.
   - Without internet, sending is paused.

4. **Configure URL, TID, Device ID**

   - Tap the **URL** line to set your HTTP endpoint (e.g. your PHP script).
   - Tap **TID** to set the tracker ID (default `te`).
   - Tap **Device ID** to set the device ID (default `01`).
   - Each time you tap Save:
     - The value is stored on the device.
     - Sending will restart automatically if all conditions are met.

5. **Sending behavior**

   ByteLoc sends JSON **once per second** only when:

   - Internet is available.
   - GPS has a valid position.
   - URL is non-empty.
   - The user is **not editing** URL/TID/Device ID.

   While editing URL/TID/Device ID:

   - Sending is paused.
   - After tapping Save, sending resumes automatically with the new value(s).

6. **Quitting the app**

   - Pressing Android’s back button shows a confirmation dialog:
     - **No** → Stay in the app, continue sending.
     - **Yes** → Stop sending and close the app.

---

## Help & About (inside the app)

- Tap the **? icon** in the app bar to open the **Help** screen:
  - Overview of how ByteLoc works.
  - Requirements.
  - Step-by-step usage.
  - Notes about battery and privacy.

- Tap the **“i” icon** in the app bar to open the **About** dialog:
  - App name and version (e.g. `0.1.2`).
  - “Developed by Ko Byte”.
  - A clickable link to the developer portfolio.

---

## Backend example (PHP)

A typical PHP endpoint for ByteLoc might:

- Read raw JSON:

  ```php
  $json = file_get_contents('php://input');
  $data = json_decode($json, true);
  ```

- Validate required fields (`lat`, `lon`, `tst`).
- Use `tid` and `deviceId` to build an identifier.
- Update a row in the `truck` table with new coordinates.

This allows ByteLoc to update a specific truck/vehicle row every second.

---

## License

This project is licensed under the **MIT License**.

See the [`LICENSE`](./LICENSE) file for details.

```text
Copyright (c) 2026 Zay Yar Min (Ko Byte)
```
