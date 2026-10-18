# flutter_map_interactive demo

[Open the live demo](https://mkidv.github.io/flutter_map_interactive/).

Explore three independent scenes: collision-aware marker labels and popups,
editable polylines, and image overlays with transformation handles. Each scene
has add/delete, edit mode, undo/redo, a save checkpoint, discard, and reset controls.
Scene changes preserve edits. Reloading the page clears all changes; there is
no backend or browser persistence.

## Run locally

From `example/`:

```sh
flutter pub get
flutter run -d chrome
```

## Validate

```sh
flutter analyze --fatal-infos
flutter test
flutter build web --release --base-href /flutter_map_interactive/
```

Serve `build/web` under `/flutter_map_interactive/` to check the project-site
build. For a server rooted directly in `build/web`, build with `--base-href /`.

## GitHub Pages

In the repository settings, choose **Pages → Build and deployment → GitHub
Actions**. The `Deploy interactive demo` workflow tests and builds the demo,
then deploys it on relevant pushes to `main` or a manual workflow dispatch.
The base path comes from GitHub Pages configuration, including custom domains.

The map uses standard OpenStreetMap tiles and includes attribution. It requires
an internet connection. Automated widget tests substitute a local tile provider.
