# Bannaa Forem Image Build

This directory keeps Bannaa-specific changes as a small overlay instead of vendoring the full Forem source tree.

Build flow:

1. Clone upstream Forem.
2. Copy files from `build/overlays/`.
3. Patch small upstream integration points with `build/scripts/apply-bannaa-overlays.sh`.
4. Build Forem's `production` container target.
5. Publish:

   ```text
   ghcr.io/moeghashim/bannaa-club:production
   ```

This keeps future Forem updates cleaner: update the upstream ref in `.github/workflows/build-forem-image.yml`, run the overlay script, fix only the small patch surface if upstream changed, then build a new image.

Current overlay scope:

- Arabic locale files.
- Arabic Devise/Kaminari starter translations.
- Arabic language display names.
- Arabic locale allowlist in `ApplicationController`.
- Dynamic `<html lang>` and `dir`.
- RTL helper, RTL stylesheet, and Bannaa brand-theme stylesheet.
- Keeps `app/assets/builds` present before Rails boots during image build.
- Asset manifest links for the Bannaa stylesheets and Forem home feed bundles.
- Admin default-locale selector support for Arabic.
