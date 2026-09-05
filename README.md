# PineDev Weather

An open-source iPhone weather app for forecasts, animated radar, live lightning, and aviation briefings. Built with SwiftUI. No API keys.

**[github.com/PineDev1/PineDev-Weather](https://github.com/PineDev1/PineDev-Weather)**

## What it does

PineDev Weather is a native iOS app that pulls live weather for your location (or any saved place) and shows it across four tabs:

- **Weather** — current conditions, hourly and 10-day outlook, rain timing, thunderstorms, air quality, moon, pollen, and going-out / driving advice
- **Radar** — animated precipitation radar with a live satellite lightning overlay you can toggle
- **Aviation** — nearby METARs and TAFs with decoded flight category
- **Settings** — Dark, Live Weather, PineDev Classic, and Light themes, plus °F / °C

Search cities or zip codes, save places, and pull to refresh.

## Open source

This project is **public and open source** under the [MIT License](LICENSE).

That means you can use, copy, modify, and share the app and its source code, including in your own projects, as long as you keep the copyright and license notice.

The whole app lives in this repository. There is no private backend and no paid weather key to hide — forecasts, radar, lightning, and aviation data all come from public sources listed below.

Issues and pull requests are welcome. Day-to-day work happens on the `dev` branch; `main` is the stable release line.

## Data sources

| What | Source |
| --- | --- |
| Forecasts, geocoding, air quality | [Open-Meteo](https://open-meteo.com) |
| Radar tiles | [RainViewer](https://www.rainviewer.com) |
| Lightning | NOAA GOES GLM via [SSEC RealEarth](https://realearth.ssec.wisc.edu) |
| METARs and TAFs | [NOAA Aviation Weather Center](https://aviationweather.gov) |

Lightning coverage is the Americas (GOES GLM). Radar is global.

## Requirements

- A Mac with [Xcode](https://developer.apple.com/xcode/) (this project targets iOS 26.5)
- An iPhone on iOS 26.5 or later
- A free Apple ID (enough for personal installs)

## Install on your iPhone

The app is not on the App Store. Install it from Xcode onto a phone you own.

### 1. Get the code

```bash
git clone https://github.com/PineDev1/PineDev-Weather.git
cd PineDev-Weather
```

Open `Weather.xcodeproj` in Xcode.

### 2. Connect the iPhone

1. Unlock the phone and plug it into the Mac with a **data** cable (charge-only cables will not work).
2. Tap **Trust** on the phone if asked, and enter your passcode.
3. In Xcode, choose **Window → Devices and Simulators** and wait until your iPhone appears.

### 3. Turn on Developer Mode

Apple hides this until Xcode has seen the phone.

1. On the iPhone, open **Settings → Privacy & Security**.
2. Scroll to the **bottom**. **Developer Mode** should now be listed (under Lockdown Mode).
3. Turn it on, restart when asked, then tap **Turn On** and enter your passcode.

### 4. Sign and run

1. In Xcode, select the **Weather** target.
2. Open **Signing & Capabilities**.
3. Enable **Automatically manage signing**.
4. Set **Team** to your Apple ID (add the account under Xcode → Settings → Accounts if needed).
5. In the toolbar destination menu, pick **your iPhone** (not a simulator).
6. Click the Play button.

If macOS asks **codesign wants to access a key in your keychain**, that password is your **Mac login password** (the one that unlocks the Mac), not your Apple ID. Choose **Always Allow**.

### 5. Trust the app

If the app installs but will not open:

1. On the iPhone, go to **Settings → General → VPN & Device Management**.
2. Tap your Apple ID / developer certificate → **Trust**.

Allow location when prompted so forecasts, radar, and the nearest METAR can use where you are.

### How long it lasts

- **Free Apple ID:** the install expires after about **7 days**. Plug the phone back in and click Play in Xcode to renew it.
- **[Apple Developer Program](https://developer.apple.com/programs/)** ($99/year): about a year per build, and you can distribute through TestFlight.

## License

[MIT](LICENSE) © 2026 PineDev / Riley Starkey
