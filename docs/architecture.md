# Architecture

## Current flow

```text
Bundled synthetic JSON → transactional SQLite seed → local search and route planner → Flutter UI
```

The app opens a local database and seeds it once from `assets/sample_dataset.json`. Search and journey calculations read only this database. The passenger screens do not make network requests or ask for location access.

## Local schema

- `routes` holds route labels and provenance.
- `stops` holds stop names, context, and provenance.
- `route_stops` stores ordered stops for each route.
- `landmarks` holds canonical names, associated stops, and provenance.
- `aliases` holds searchable alternate names and an approval flag.
- `fares` is reserved for sourced, effective-dated fare records. The sample dataset intentionally contains no fare claims.
- `metadata` records the bundled dataset version and date.

SQLite foreign keys and a transaction protect the initial seed. The current app does not yet implement remote dataset checks, package validation, atomic replacement, migration upgrades, or rollback. Do not add real dataset releases until those controls exist.

## Search and route calculation

Search normalizes case and repeated whitespace, searches canonical names before aliases, and keeps the canonical name as the result title. Alias matches carry the matched text so the UI can show `Also called: …`.

The journey planner checks ordered route patterns for a direct trip, then looks for one shared stop that can serve as a transfer. It does not estimate duration, guarantee service, calculate fares, or include walking directions.

## Platform boundary

The SQLite plugin in this build targets Android and iOS. Generated desktop runner files are Flutter scaffolding only and are not a supported build target. A desktop application needs its own storage, authentication, and packaging review.

## Sample data boundary

Every included route, stop, place, and alias is fictional. The dataset is for UI and algorithm demonstration only; it must not be used for navigation. No user-specific or location data is bundled.
