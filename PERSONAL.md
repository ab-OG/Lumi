# Our personal AI project

This is Ankit's personal fork of [Lumi](https://github.com/CofficLab/Lumi).
The aim is to keep the app we already like and improve it through small,
reviewable changes. The first milestone is a complete English interface and a
verified local-model conversation on an M4 MacBook Air with 16 GB RAM.

This file describes the fork's direction. The upstream README and license remain
in place; this fork is based on Lumi, not an app built from scratch.

## First milestone

- Audit the app and bundled plugins for untranslated interface text.
- Translate visible text, including Settings, plugin management, providers,
  tools, errors, and permission prompts, while keeping localization support.
- Verify an English local-model conversation and a small file task in a test
  folder. Record the exact model and observed result.
- Establish a development app identity and separate storage before running the
  custom build, so testing cannot alter the installed Lumi app's data.

Only project documentation has been added so far. These are planned outcomes,
not claims that the features have been implemented or tested.

## How we work

- Keep `main` as the reference branch; make focused changes on topic branches.
- Open draft pull requests early and describe what changed and how it was checked.
- Keep commits small enough to understand and reverse.
- Retain `upstream` as CofficLab/Lumi and `origin` as ab-OG/Lumi.
- Follow the repository's AGENTS.md and any more specific instructions.
- Preserve upstream attribution and the repository's GPLv3 license.
- Keep API keys, tokens, chats, personal documents, models, and build products out
  of Git. Use synthetic examples when documenting a test.
- Keep this project's configuration separate from ChatGPT and other AI apps.

REA may help investigate unclear runtime behavior. Since Lumi publishes its
source, ordinary source inspection and focused changes are our starting point.

## Local setup

Local checkout: `~/Documents/GitHub/Lumi`.

The initial clone is shallow and sparse to defer downloading large bundled
source dependencies. Before a full build, populate the rest of the checkout:

```bash
cd ~/Documents/GitHub/Lumi
git sparse-checkout disable
```

Older history can be fetched later if a change needs it:

```bash
git fetch --unshallow origin
```

Upstream currently requires **Xcode 27.0 or newer**, macOS 14 or newer, and Swift
6 or newer. Xcode 26 does not support this repository's JSON project format.
After installing and opening Xcode to finish its first-run setup, check:

```bash
xcode-select -p
xcodebuild -version
```

If the selected path still points to CommandLineTools, select the installed
Xcode in Xcode > Settings > Locations > Command Line Tools, or use:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

Use the actual app path if Xcode is installed under a different name.

## First build checklist

1. Verify the Xcode version and populate the complete checkout.
2. Review signing, bundle identifiers, storage paths, update behavior, and
   launch/login helpers before running a development build.
3. Build the unchanged baseline using the checked-in package resolutions.
4. Record the build result before starting localization changes.
5. Run the custom app only after its data is isolated from the installed app.

The upstream build command is documented in README.md. Start with a build rather
than Run until the development identity and storage behavior have been checked.
A successful Git setup does not establish that the app builds.

## Current status — November 10, 2026

- GitHub fork created: https://github.com/ab-OG/Lumi
- Upstream source and attribution preserved.
- Topic branch created for project setup.
- Installed Lumi is unchanged by the repository setup.
- Full Xcode installation is being handled by Ankit.
- No custom app build, English translation, or local-model task is verified yet.
