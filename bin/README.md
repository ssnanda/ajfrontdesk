# bin/

Build and release scripts for **AJ Front Desk** (`ssnanda/ajfrontdesk`). Same scheme as `ajopsios/bin`.

| script | purpose | output |
|---|---|---|
| `1-bump-version.sh` | resolve next version, write `pubspec.yaml`, commit `Release AJ Front Desk X.Y.Z+B` | none |
| `2a-ajfrontdesk-ipa.sh` | build and publish the iOS IPA to the rolling `ios-latest` release, update `altstore.json` | `~/Documents/GitHub/ipa/ajfrontdesk.ipa` |
| `2b-sim-iphone.sh` | run the app in the configured iPhone simulator | none |
| `2c-sim-ipad.sh` | run the app in the configured iPad simulator (the real target) | none |
| `2d-device-run.sh` | run the app on a physical iOS device | none |

No Android script: this app only has an iOS project.

```bash
./bin/1-bump-version.sh            # interactive menu, bump and commit
./bin/2a-ajfrontdesk-ipa.sh        # bump if dirty, build, push, publish, update AltStore
./bin/2a-ajfrontdesk-ipa.sh --local  # build only; do not push or publish
./bin/2c-sim-ipad.sh
```

The app has no server URL baked in: the site URL and device key are entered on the iPad at first launch
(device keys come from AJ Core > Client Portal > Reception), so there are no `--prod` / `--local` switches.

AltStore source: `https://raw.githubusercontent.com/ssnanda/ajfrontdesk/main/altstore.json`. Bundle id `com.itspector.frontdesk`.
Before the first release replace the app icon (it is still the old default) and run `git init`, add the
`origin` remote and push once so the scripts have a repository to commit to.
