# WasteWise

**A smart waste disposal assistant.** WasteWise tells you how to dispose of an item properly and finds the nearest place to take it, using your live location.

Many people don't know how to dispose of things like old phones, batteries, plastic or clothing, or where to take them. WasteWise connects the answer to the next step: pick an item, see how to dispose of it, find the nearest drop-off point, and get directions.

## Features

- **Disposal guide:** choose Electronics, Batteries, Plastic or Clothing and get clear, step-by-step guidance.
- **Nearby drop-off points:** real collection points shown on a map and in a list, sorted nearest first from your GPS position.
- **Get directions:** open the route to any point in Google Maps with one tap.
- **Eco Points and badges:** mark an item as disposed to earn points and achievement badges. Progress is saved on the phone.

## Tech stack

| Area | What we used | Why |
|---|---|---|
| Framework | Flutter (Dart) | One codebase for Android and iOS, fast iteration with hot reload |
| Local database | SQLite via `sqflite` | Free, works offline, needs no account or billing |
| GPS / location | `geolocator` | Reads the device position and handles the location permission |
| Map | `flutter_map` + `latlong2` with OpenStreetMap tiles | Free, no API key or billing card (Google Maps required one) |
| Directions | `url_launcher` | Hands the destination over to Google Maps |
| Paths | `path` | Builds the database file location |

## How it works

**Database.** SQLite holds three tables: `categories`, `disposal_points` and `eco_points_log`. On first launch the tables are created and filled with the bundled data. The database has a version number, so when the data changes, categories and points reload without erasing the user's Eco Points. The Eco Points balance is the sum of the log, so the history and the total can't get out of sync, and the total never goes below 0.

**Location.** The app asks for location permission, reads the phone's position, and calculates the distance to each disposal point to sort the list nearest first.

**Data sources.** The 18 disposal points (Colombo and the Western Province) come from the official [e-Kunu](https://ekunu.lk) e-waste programme and from Google Maps. Each record has a `source` field.

## Project structure

```
lib/
├── main.dart            # app entry point and bottom navigation
├── data/                # SQLite helper and bundled seed data
├── models/              # WasteCategory, DisposalPoint, EcoBadge
├── screens/             # category, guide, map and points screens
└── services/            # location service
```

## Getting started

Requirements: Flutter SDK and an Android phone or emulator.

```bash
git clone https://github.com/AAKP03/WasteWise.git
cd WasteWise
flutter pub get
flutter run
```

Notes:
- Run it on an **Android phone or emulator**. `sqflite` doesn't work on Flutter web, so Chrome won't work.
- Allow location access when the app asks.
- Internet is needed for the map tiles and for Get Directions.
- Tested on a physical Android phone (Pixel 6). iOS hasn't been tested.

## Team

| Member | Role | Area |
|---|---|---|
| Member 1 | Backend / database | SQLite schema, seed data, data access functions, Eco Points data |
| Member 2 | Maps / GPS | Location service, map, directions |
| Member 3 | Disposal UI | Category and guide screens |
| Member 4 | Points UI | Eco Points screen and badges |
| Member 5 | Integration / QA | Navigation, merging, testing |

## Limitations and future work

- Data is stored per device, so Eco Points don't sync between phones.
- Crowdsourced verification ("this centre no longer accepts batteries") isn't built. It would need a shared back end such as Firebase.
- Coverage is limited to the Colombo area, and clothing has only two collection points.
- Listings should be rechecked regularly, since collection points change.

