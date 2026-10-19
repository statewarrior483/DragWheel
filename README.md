# DragWheel

Menu bar app for macOS 13+. Hold **⇧ Shift** (or your chosen key) while dragging a file and a conversion wheel opens around it. Drop on a format to convert, or drop in the middle ✕ to cancel. The original is never touched; the new file lands in the same folder, placed beside the original.

## Build & install

```bash
xcode-select --install        # once, if you don't have Swift
cd DragWheel
chmod +x build.sh
./build.sh --install          # builds, copies to /Applications, launches
```

## Helper tools (optional)

Images, PDFs, documents, subtitles, archives and folders work out of the box using macOS itself. Some formats need free helpers, and the wheel greys those wedges out ("needs FFmpeg") until they're installed:

```bash
brew install ffmpeg pandoc imagemagick unar
brew install --cask libreoffice
```

| Helper | Unlocks |
|---|---|
| FFmpeg | all video, most audio (wav/aiff/m4a work without it) |
| Pandoc | epub in/out, better Markdown |
| LibreOffice | presentations, xlsx/xls/ods |
| ImageMagick | webp/avif output if your macOS can't encode them |

The menu bar → Helper Tools shows what's installed and copies the install command for whatever's missing.

## Permissions you'll see

- **Finder automation** (first conversion): lets DragWheel position the new file next to the original. Decline it and conversions still work; the file just goes wherever Finder puts it. You can turn placement off in the menu.
- **Desktop / Documents / Downloads access**: needed to write the converted file there.
- **Notifications**: only used to report failures.
- A **custom non-modifier trigger key** (e.g. Space) may also need Input Monitoring in System Settings → Privacy & Security. Modifier keys need nothing.

## Notes

- Multi-page PDFs/decks/docs → jpg/png create a folder `name (png)` with one image per page.
- PDF → docx/md/txt/epub extracts text only (layout isn't preserved).
- Placement only works in icon view; list/column views sort by name so the new file sits next to the original anyway.
- Dragging several files shows only formats all of them can convert to.
