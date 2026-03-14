# ClearSkies

> A 14-day clear sky forecast app designed for amateur astronomers, telescope observers, and astrophotographers.

---

## Overview

Planning a telescope session means more than just checking the weather — you need to know whether the skies will be truly clear, how stable the atmosphere is, what the Moon is doing, and exactly how long you have between dusk and dawn. ClearSkies brings all of that together in a single, beautifully designed dark-themed app.

Enter your UK postcode or any city name and ClearSkies gives you a rolling 14-day forecast covering every dark-sky window. Each night is scored 0–100 based on cloud cover, atmospheric seeing, transparency, moon phase, humidity, and wind — so you can plan your best observing sessions days in advance, at a glance.

---

## Screenshots

_(Coming soon — Windows and Android builds in progress)_

---

## Features

### Forecast
- **14-day rolling forecast** starting from today, one tile per night
- Each day tile shows: dusk time, moon phase, best cloud cover, dark-sky duration, and an overall **ClearSky Score**
- Tap any tile to expand and see hour-by-hour conditions throughout the night
- Colour-coded scores: Excellent (green) → Good → Fair → Poor (red)
- Pull-to-refresh to update all data

### Hour-by-Hour Detail
- Cloud cover breakdown (total, low, mid, high)
- **Atmospheric seeing** (1–5 scale, sourced from 7timer.info ASTRO product)
- **Atmospheric transparency** (1–5 scale)
- Humidity with dew-risk warning
- Wind speed (knots) with gusty-conditions flag
- Moon altitude throughout the night
- Hourly cloud cover trend chart

### Astronomy Engine
- Astronomical dusk and dawn times (sun 18° below horizon)
- Moon phase (New → Full → New), illumination percentage, and emoji indicator
- Moonrise and moonset times
- All computed in pure Dart — no external astronomy package required

### Location
- UK postcode geocoding via [postcodes.io](https://postcodes.io/) (no API key required)
- City name geocoding worldwide via [Nominatim / OpenStreetMap](https://nominatim.org/) (no API key required)
- Location persisted across sessions
- Quick-pick shortcuts for common UK cities

### Settings
- Optional Met Office DataPoint API key — when provided, Met Office data is used as the primary source in place of Open-Meteo
- Data source status display

---

## ClearSky Score

Each hour within dark-sky window receives a score 0–100 using a weighted formula:

| Component         | Weight | Source          |
|-------------------|--------|-----------------|
| Cloud cover       | 40%    | Open-Meteo      |
| Atmospheric seeing| 25%    | 7timer.info ASTRO|
| Transparency      | 20%    | 7timer.info ASTRO|
| Moon interference | 10%    | Computed (SunCalc)|
| Humidity          | 3%     | Open-Meteo      |
| Wind speed        | 2%     | Open-Meteo      |

The daily score is the average of all dark-hour slot scores. A cloudless night with steady atmosphere, new moon, and low humidity targets 90+.

---

## Data Sources

| Source | Product | Key required |
|--------|---------|-------------|
| [Open-Meteo](https://open-meteo.com/) | 16-day hourly weather (cloud, humidity, wind, dew point, temperature) | No |
| [7timer.info](http://www.7timer.info/) | ASTRO — astronomy seeing & transparency | No |
| [postcodes.io](https://postcodes.io/) | UK postcode → latitude/longitude | No |
| [Nominatim (OSM)](https://nominatim.org/) | City/place → latitude/longitude | No |
| [Met Office DataPoint](https://www.metoffice.gov.uk/services/data/datapoint) | High-resolution UK forecast (premium upgrade) | Optional |

The app is architected around a `WeatherDataSource` interface so Met Office can be enabled as a drop-in replacement once an API key is provided in settings.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| Platforms | Android (Google Play compatible), Windows desktop |
| State management | Riverpod 2.x |
| HTTP & caching | Dio 5.x + dio_cache_interceptor (1-hour TTL) |
| Charts | fl_chart |
| Animations | flutter_animate + AnimatedCrossFade |
| Local storage | shared_preferences |
| Astronomy | Pure Dart port of SunCalc (Vladimir Agafonkin) |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point + bottom nav shell
├── theme/
│   └── app_theme.dart                 # Deep-space dark colour palette + typography
├── models/
│   ├── location.dart                  # AppLocation (lat, lon, displayName, postcode)
│   ├── day_forecast.dart              # DayForecast + computed properties
│   └── hourly_slot.dart               # HourlySlot + clearSkyScore formula
├── features/
│   ├── location/
│   │   ├── location_search_screen.dart
│   │   └── geocoding_service.dart     # postcodes.io + Nominatim routing
│   ├── forecast/
│   │   ├── forecast_screen.dart       # Main scrollable list + pull-to-refresh
│   │   ├── day_forecast_tile.dart     # Expandable tile with animations
│   │   ├── hourly_conditions_grid.dart
│   │   ├── clear_sky_score_badge.dart
│   │   ├── forecast_providers.dart    # Riverpod providers (location + forecast)
│   │   └── settings_screen.dart
│   └── astronomy/
│       └── astronomy_service.dart     # Pure Dart: dusk/dawn, moon phase, moonrise/set
└── services/
    ├── forecast_repository.dart       # Merges Open-Meteo + 7timer + astronomy
    └── weather/
        ├── weather_data_source.dart   # Abstract interface
        ├── open_meteo_source.dart
        ├── seven_timer_source.dart
        └── met_office_source.dart     # Stub — ready for API key integration
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x
- Android Studio / Android SDK (for Android builds)
- Visual Studio 2022 with "Desktop development with C++" workload (for Windows builds)

### Run

```bash
# Clone the repository
git clone https://github.com/david-william-johns/clearskies.git
cd clearskies

# Install dependencies
flutter pub get

# Run on Windows desktop
flutter run -d windows

# Run on connected Android device or emulator
flutter run -d android
```

### Build

```bash
# Android release bundle (for Google Play)
flutter build appbundle --release

# Android debug APK
flutter build apk --debug

# Windows release
flutter build windows --release
```

---

## Roadmap

- [ ] Met Office DataPoint full integration (stub ready, needs API key)
- [ ] Notification support — alert when a clear window opens for a saved location
- [ ] Light pollution overlay (Bortle scale, per location)
- [ ] Object visibility panel — which DSOs are above the horizon tonight
- [ ] Multiple saved locations
- [ ] Widget support (Android home screen)
- [ ] iOS target (Swift/Xcode dependencies permitting)

---

## Acknowledgements

- Astronomical dusk/dawn and moon calculations adapted from [SunCalc](https://github.com/mourner/suncalc) by Vladimir Agafonkin (BSD-2-Clause)
- Weather data courtesy of [Open-Meteo](https://open-meteo.com/) and [7timer.info](http://www.7timer.info/)
- Geocoding by [postcodes.io](https://postcodes.io/) and [OpenStreetMap Nominatim](https://nominatim.org/)

---

## Licence

MIT — see [LICENSE](LICENSE) for details.
