# Turnable Page playground

The live demo embedded in the docs site (`docs/index.html`, section "Live playground"). It depends on the package through `path: ../`, so it always shows the current code.

## Rebuild after changing the package

From this folder, in Git Bash:

```bash
flutter build web --release --base-href /turnable_page/demo/
rm -rf ../docs/demo && mkdir -p ../docs/demo && cp -r build/web/. ../docs/demo/
# CanvasKit loads from Google's CDN, and the playground never opens a PDF.
rm -rf ../docs/demo/canvaskit ../docs/demo/assets/packages/pdfrx
# A relative base lets the demo run both locally and on GitHub Pages.
sed -i 's#<base href="/turnable_page/demo/">#<base href="./">#' ../docs/demo/index.html
```

Build to `build/web` first and copy: building straight into `../docs/demo` fails on Windows while compiling shaders.

To preview locally, serve the docs folder (`python -m http.server 8765 --directory ../docs`) and open `http://localhost:8765/`.
