# DragWheel

A macOS menu bar app for converting files with a drag. Hold **⇧ Shift** while dragging a file and a radial menu opens around it. Drop on a format to convert, or drop on the ✕ in the middle to cancel.

The original file is never modified or moved. The converted file is saved as a new file in the same folder and placed right next to the original.

Requires **macOS 13 (Ventura) or later**.

---

## Supported conversions

| Type | From | To |
|---|---|---|
| 🖼️ Images | jpg, png, webp, heic, tiff, avif, bmp, gif, svg | jpg, png, webp, tiff, avif, bmp, pdf |
| 🎵 Audio | mp3, m4a, wav, flac, ogg, opus, aiff, wma | mp3, m4a, wav, flac, ogg, opus, aiff, wma |
| 🎬 Video | mp4, mov, mkv, webm, avi, wmv | mp4, mov, mkv, webm, avi, wmv, gif, mp3 |
| 📄 PDF | pdf | docx, jpg, png, epub, txt, md |
| 📝 Documents | docx, doc, odt, rtf, md, txt, epub, html | docx, md, txt, epub, html, pdf, jpg, png |
| 📊 Presentations | pptx, ppt, odp | pdf, jpg, png |
| 📈 Spreadsheets | xlsx, xls, ods, csv, tsv | xlsx, ods, csv, tsv, pdf |
| 💬 Subtitles | srt, vtt | srt, vtt, txt |
| 🗜️ Archives | zip, tar, tar.gz, rar | zip, tar, tar.gz |
| 📁 Folders | any folder | zip, tar, tar.gz |

---

## Installation

### 1. Install Xcode Command Line Tools

Skip this if you already have them. In Terminal, run:

```bash
xcode-select --install
```

### 2. Download the project

Download the ZIP from GitHub (green **Code** button → **Download ZIP**) and unzip it, or clone it:

```bash
git clone https://github.com/YOUR-USERNAME/DragWheel.git
```

### 3. Build and install

Open Terminal (⌘ Space → type `Terminal`) and go into the project folder:

```bash
cd ~/Downloads/DragWheel
```

> Tip: type `cd ` (with a space), drag the DragWheel folder into the Terminal window, then press Return.

Then build:

```bash
chmod +x build.sh
./build.sh --install
```

The first build takes a minute or two. When it's done you'll see:

```
Built build/DragWheel.app
Installed to /Applications and launched.
```

A ◎ icon appears in your menu bar.

> Run `./build.sh` without `--install` to only build the app into `build/DragWheel.app`.

---

## Helper tools (optional but recommended)

Images, PDFs, most documents, subtitles, archives and folders work out of the box using macOS's built-in tools. Some formats need free helper tools. Until they're installed, those wedges on the wheel are greyed out and say things like **"needs FFmpeg"**.

| Helper | Unlocks |
|---|---|
| **FFmpeg** | all video, most audio (wav/aiff/m4a work without it) |
| **ImageMagick** | webp and avif output (macOS can read these but can't create them) |
| **Pandoc** | epub input/output, better Markdown conversion |
| **LibreOffice** | presentations, xlsx/xls/ods |
| **unar** | fallback for rar archives |

### Install Homebrew

If running `brew` in Terminal says `command not found`, install Homebrew first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

It will ask for your Mac password. Nothing appears while you type, which is normal. When it finishes, it prints a few commands under **"Next steps"** (starting with `echo` and `eval`). Run those too.

### Install the helpers

```bash
brew install ffmpeg imagemagick pandoc unar
brew install --cask libreoffice
```

You don't need to restart DragWheel. Greyed-out wedges become active on your next drag.

The menu bar icon → **Helper Tools** shows what's installed and can copy the install command for anything missing.

---

## Usage

1. Start dragging any file (or folder) in Finder.
2. Hold **⇧ Shift**. The wheel appears around your cursor.
3. Move onto a format and let go to convert.
4. To cancel, let go on the **✕** in the center. Nothing happens to the file.

The converted file appears next to the original. If a file with that name already exists, the new one is named `name 2.ext`.

### First-run permissions

The first time you convert, macOS asks for a few permissions. Click **Allow** / **OK**:

- **"DragWheel wants to control Finder"**: lets it position the new file next to the original. If you decline, conversions still work; the file just goes wherever Finder puts it.
- **Desktop / Documents / Downloads access**: needed to save the converted file there.
- **Notifications**: only used to report errors.

---

## Settings

Click the ◎ icon in the menu bar:

- **Trigger Key**: use Shift, Option, Control, Command, fn, or record a custom key.
- **Place Converted File Next to Original**: turn Finder positioning on or off.
- **Launch at Login**: start DragWheel automatically.
- **Helper Tools**: see which helpers are installed.

> A custom non-modifier trigger key (like Space) may require **Input Monitoring** permission in System Settings → Privacy & Security. Modifier keys need no extra permission.

---

## Notes and limitations

- Converting a multi-page PDF, document or presentation to jpg/png creates a folder named `name (png)` with one image per page.
- PDF → docx / md / txt / epub extracts text only; the original layout isn't preserved.
- Placing the file beside the original only works in Finder's **icon view**. List and column views sort by name, which keeps the new file next to the original anyway.
- When dragging several files at once, the wheel shows only formats that all of them can convert to.

---

## Updating

After changing the code or pulling new changes, rebuild:

```bash
./build.sh --install
```

macOS may ask for the Finder permission again after a rebuild. This is normal for locally built apps.

## Uninstalling

Quit DragWheel from the menu bar, then:

```bash
rm -rf /Applications/DragWheel.app
rm -rf ~/Library/Application\ Support/DragWheel
```
