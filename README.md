# Vintage Grunge Fitness

Zepp OS watchface for Amazfit Bip Max (432 × 514). Version 1.4.5.

![Preview](previews/watchface-preview.png)

![Always-on display](previews/watchface-aod-preview.png)

## Project layout

- `assets/`: generated assets used by the watch.
- `watchface/`: watchface runtime.
- `artwork/`: source images and design references.
- `previews/`: rendered previews and visual checks.
- `scripts/`: asset generation, preview and build helpers.
- `references/`: display contour and revision baselines.
- `releases/`: original versioned Zepp packages.

## Build

Install Node.js and the official Zepp Zeus CLI, then run from the repository root:

```sh
zeus build -t "Amazfit Bip Max"
```

Asset generation uses Windows PowerShell and System.Drawing. Generated assets are already included. To regenerate them, run `./scripts/make-assets.ps1`. Run preview and validation commands from the repository root. Local Zeus wrappers require a configured local tool installation; the standard CLI command above works with an installed Zeus CLI.

## Releases

Published packages are available on the repository’s Releases page. Existing packages remain unchanged. GitHub publication is separate from Zepp store approval and installation. Preserve the registered numeric Zepp ID in `app.json` for in-place upgrades.


## License

Copyright © 2026 Aniruddha DuttaChowdhury.

Original project material is licensed under the **PolyForm Noncommercial License 1.0.0**. Personal, academic, research, educational and other qualifying noncommercial uses, modifications and redistribution are permitted in accordance with its terms. Commercial uses outside those permissions require separate authorization from the copyright holder.

Anyone redistributing covered software, including within another application, must pass along the license terms or their URL and all applicable Required Notices identifying the original author, project and source repository. This license does not require publication of the modified application's source code.

For complete terms, see [LICENSE.md](LICENSE.md). Third-party software, libraries, fonts, data and artwork remain subject to their respective licenses; see [third-party notices and unresolved permissions](THIRD-PARTY-NOTICES.md).

### Redistribution attribution example

For an application derived from `vintage-grunge-fitness-watchface`, accompany the distributed software with the license terms or their URL and these notices, for example in licensing documents or an attribution file:

```text
Based on: vintage-grunge-fitness-watchface
Required Notice: Copyright © 2026 Aniruddha DuttaChowdhury.
Required Notice: Original Author: Aniruddha DuttaChowdhury.
Required Notice: Original Project: vintage-grunge-fitness-watchface.
Required Notice: Original Source: https://github.com/aniruddhaKol/vintage-grunge-fitness-watchface
License: PolyForm Noncommercial License 1.0.0
License terms: https://polyformproject.org/licenses/noncommercial/1.0.0
```

An About screen acknowledgment is encouraged. The standard license does not impose separate app-store attribution or UI-branding requirements, or require public disclosure of modified source code.
