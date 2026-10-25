# Shelfwise 🦉📚

A cozy bookshelf and reading to-do app for Android, built with Flutter.

**Download:** grab the latest APK from the [releases page](https://github.com/RajkumarPadmanabhan/update-shelf/releases/latest), or visit the [website](https://rajkumarpadmanabhan.github.io/update-shelf/).

<p align="center">
  <img src="docs/screens/home.png" width="180" alt="Home">
  <img src="docs/screens/library.png" width="180" alt="Library">
  <img src="docs/screens/reader.png" width="180" alt="Reader">
  <img src="docs/screens/todo.png" width="180" alt="To-do">
  <img src="docs/screens/rewind.png" width="180" alt="Rewind">
</p>

## About

Welcome to your reading sanctuary.

Shelfwise is built for people who believe that the books we choose shape the lives we live. Whether you are tracking a towering stack of fantasy epics, organizing cozy beach reads, or sharing how a book left you feeling, Shelfwise turns your personal bookshelf into an interactive home.

### What makes Shelfwise special

- **Your virtual bookshelf.** Build shelves, add sub-shelves, decorate them with plants, lamps, and stickers, and arrange books with tactile drag-and-drop. In the Library, arrange the shelves themselves. Home uses that same order.
- **Posts, not like counts.** On Explore, write a post about up to three books from your shelves. Other readers can tap a book and it pops up with the title, author, and description. Like counts and share counts are not shown. Only you can delete your post, and a post cannot be edited.
- **Connected reading.** Tap a reader’s name to see their shelf names and book titles. Their book files stay on their phone.
- **Quiet to-dos.** A to-do with no date, or a date and no time, does not notify you. Set both a date and a time (and turn on To-do reminders) and Shelfwise shows a popup and sends a phone notification about an hour before, and again at that time.
- **Cozy by design.** A distraction-free interface with light and dark mode, background families, custom shelf materials, and tactile interactions.

### Developer

Shelfwise was designed and built by **R Rajkumar Padmanabhan**, creator and lead developer.

### Get in touch

Feedback, bug reports, and feature requests are welcome.

- Website: https://rajkumarpadmanabhan.github.io/update-shelf/
- Latest release: https://github.com/RajkumarPadmanabhan/update-shelf/releases/latest
- Repository: https://github.com/RajkumarPadmanabhan/update-shelf

## Features

- **Cozy shelves.** Overlapping book spines on pastel glass shelves. Press a book to lift it, long-press to drag it into a new spot, and use the slider to see every book. Each shelf holds 10 spots, with a sub shelf for 10 more. In the Library, tap **Arrange** (or Move up / Move down on a shelf) to change the shelf order. Home follows that order.
- **Decorations you can play with.** Lamps switch on, candles light, the owl flies off and comes back, clocks ring and ducks squeak. All sounds are synthesised in the app.
- **Scan to add.** Point the camera at a barcode and the title, author, description and cover are filled in from Open Library (Google Books as fallback). You can also type the ISBN.
- **Share by QR.** On Home, long-press a book and drop it on the share bag (the book stays on its shelf). Tap the bag to see what's in it and share everything as one QR picture, to any app or saved to Photos.
- **Explore.** A post can include up to 3 books, plus ready-made lines and words. It is shared so other people using Shelfwise can see it. Tap a book on a post and the cover pops up with its details. Like and share counts are not shown. Only the account that posted can delete it, and a post cannot be edited. Tap a reader’s name to see their shelves.
- **Read your own PDFs & EPUBs.** Pages curl over like paper when you drag a corner. Pinch or double-tap to zoom in place; while zoomed, swipe past the edge for the next page. EPUBs are typeset at the text size you choose. Bookmarks, page notes, and Shelfwise remembers where you stopped.
- **Reading time & goals.** Time spent in the reader is counted (it pauses when you're idle), and you can set a yearly book goal. Rate books with stars.
- **Reading to-do list.** Bento-style cards with an optional date, an optional time, stars, hashtags and a linked book. No date or no time means no reminder. A date and a time means a popup and a phone notification, when To-do reminders are on.
- **Stats & Rewind.** See this month, this year or all time. Rewind plays a story-style recap you can share or save as an image, and your stats can be shared as a card.
- **Make it yours.** Light, dark or follow your phone; five accent colours; Nunito, Inter or Lora; three text sizes.
- **Rewards.** Milestones unlock badges, with confetti.
- **On your phone.** No ads. Continue with Google uses the Google account already on the phone. Your book files stay on the device. Shelf names and book titles can be shown when someone taps your name on Explore. The internet is also used to check for updates, to look up books you scan, and to share Explore posts. Use **Settings → Share backup** to save a backup, and **Settings → Import backup** on a new phone. Turn on **Include book files** to put your PDFs and EPUBs in the backup as a `.zip`.
- **Updates.** Shelfwise checks GitHub for new releases and installs them for you. **Settings → About Shelfwise** shows the version, what the app is for, and links to the website and the latest release.

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm,android-arm64
```

Release builds are signed with the key referenced by `android/key.properties`, which is git-ignored. Without that file, the build falls back to the debug key.

## Workflow

Work happens on `dev`. Once a build has been tested on a device, `dev` is merged into `main`. Then a version tag is pushed (for example `git tag v1.2.0 && git push origin v1.2.0`), and the **Release APK** GitHub Action builds the signed APK and publishes the release with `shelfwise.apk` attached. Release notes come from `.github/release-notes/<tag>.md`. The website in `docs/` (GitHub Pages) reads the latest version from GitHub and links to the latest APK.

The Action signs with secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD` and `KEY_ALIAS`, the same key as local builds, so updates install over older versions.

## Credits

The design is based on the "Readers" HTML mockup. The fonts (Nunito, Inter, Lora, Playfair Display and Caveat) are from Google Fonts under the SIL Open Font License.
