# Call-To-The-Faithful

A simple Apple Watch companion that calls the faithful to Mass in the same way the church bells of old did.

## Current MVP experience

The watch app boots directly into a **Quick Actions** list that highlights the most common bell-ringing flows:

- **Ring Bells** – prompts for confirmation before triggering the placeholder flow.
- **Schedule Next Mass** – shows a friendly reminder that scheduling will arrive soon.
- **Update Profile** – indicates that parish profile import is on the roadmap.
- **Manage Volunteers** – confirms with the user before showing a placeholder message.

Each item currently surfaces a short message after selection so testers understand that the action is a no-op while we wire up the real integrations. Confirm-required actions (`Ring Bells`, `Manage Volunteers`) present a lightweight confirmation dialog before showing their placeholder message so early testers can experience the intended flow without side effects.

## Follow-up tasks

1. **Parish profile import** – Add an import pipeline that syncs parish location, contact data, and bell schedules from the diocesan directory so the watch app stays current without manual entry.
2. **Enhanced quick action behavior** – Replace the placeholder alerts with functional flows (call service trigger, scheduling UI, volunteer notifications) and persist user choices for faster repeat actions.

## Development

The project is organised as a Swift Package targeting watchOS with SwiftUI views so it can be embedded in an Xcode watchOS app target.

```sh
swift build
```

The package exposes `CallToTheFaithfulApp` as the app entry point, which renders the `QuickActionsView` used throughout the MVP.
