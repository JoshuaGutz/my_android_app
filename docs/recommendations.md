# Recommendations for the Twitch Companion App

> A friend-of-a-friend review of this repo, written for Joshua. Goal: help you
> understand what you've built, what's worth changing, and how to make working with
> AI on this project a lot more productive.

## What you've built

A Flutter Android app that wraps Twitch chat popouts and a specific extension panel
in a tabbed WebView UI, with persistent tab storage and a left-handed mode. It works.
That's the hard part — most "I want to build an app" projects never get this far.

It's roughly **334 lines, all in `lib/main.dart`**, plus the auto-generated Flutter
scaffolding for six platforms (only Android is realistically targeted).

## Why it feels hard to modify

Not because you did anything wrong — because of how it's structured:

- **One file does everything.** UI, state, data model, URL building, persistence,
  dialog logic all live in `_TwitchAppState`. To change one thing you have to scroll
  through everything.
- **The same value is hardcoded in multiple places.** `"deemonrider"` appears as a
  default in three different spots (`lib/main.dart:303`, `:314`, plus the abbreviation
  hack at `:214`). Change it once, miss the other two, and you get inconsistent
  behavior.
- **Some logic is duplicated.** The `PageController` is recreated in `initState`, in
  `_addTab`, and in `_closeTab`. The "if channel is empty, default to deemonrider"
  pattern is copy-pasted instead of being one helper function.
- **The test file is broken.** `test/widget_test.dart` is the default Flutter counter
  test from project creation; it doesn't match your app and would fail if you ran it.
- **No comments explaining *why*.** The index math in `_reorderTabs` is correct but
  unreadable without staring at it. A two-line comment would save future-you (and
  future-AI-assistant) a lot of time.

None of this is broken — it just means every change is riskier than it needs to be.

## The two changes I'd actually recommend

### 1. Switch from copy-paste-with-Claude to a code-aware AI tool

This is the biggest available win and it costs nothing structural. Copy-pasting code
into ChatGPT or Claude.ai is the slowest way to use AI on a real project:

- The model loses your project context every conversation.
- It can't see how files relate to each other.
- It gives you code that doesn't compile because it doesn't know your imports or
  versions.
- You have to manually paste the answer back in the right spot, which is exactly where
  bugs get reintroduced.

**Recommended: [Claude Code](https://claude.com/claude-code)**

It's a terminal-based assistant from Anthropic. You open it inside your project, and
it can read every file, edit multiple files at once, run commands like
`flutter run`, see error output, and explain code in context. Importantly it has a
**plan mode** that forces it to *propose* before it changes — so you can read the plan,
understand it, and approve. That's a great way to learn while building.

It runs on Windows, works with your existing Claude subscription (Pro is enough for
normal use), and pairs naturally with the conversational style you already use.

**Alternative: [Cursor](https://cursor.sh)**

A GUI editor (it's a fork of VS Code) with similar capabilities. If you prefer
clicking over typing commands, this is the friendlier on-ramp. Subscription-based.

Either is roughly a 10× improvement over copy-paste. Pick one and commit to it for
two weeks before deciding.

### 2. Consider rewriting in React Native + Expo + TypeScript

Hear me out — I would not normally recommend a rewrite. The reasons it makes sense
*here* are specific:

**The language matters for AI assistance.** JavaScript and TypeScript have far more
training data than Dart (the language Flutter uses). Every AI tool you use — Claude,
ChatGPT, Cursor, Copilot — is measurably better at JS/TS. Since AI assistance is
central to how you build, this is a real factor, not a small one.

**Expo's dev loop is magical for learning.** You install one app (Expo Go) on your
phone, scan a QR code, and your code runs live on your device. Change a line, the app
updates instantly. No Android Studio, no emulator, no gradle errors. For a learner,
this matters enormously.

**It unblocks the feature you actually want.** The whole reason you went standalone
was background IRC connections that survive when the app isn't focused, plus chat
history. Doing this in Flutter is possible but the libraries are thin. In JS land,
[`tmi.js`](https://github.com/tmijs/tmi.js) is a mature Twitch IRC client, and
combining it with `notifee` + `react-native-background-actions` is a well-trodden
Android path.

**Twitch extensions still work.** `react-native-webview` is a real native WebView, not
an iframe. The thing that blocked your earlier web-app attempt
(`ggutzyy.com/SPA-sDOM`) was iframe restrictions; this isn't that.

**Cross-platform stays cross-platform.** Same codebase covers Android now and iOS
later when you have a device to test on.

#### What the new project shape would look like

```
src/
  App.tsx                    # top-level navigation
  screens/
    MainScreen.tsx           # the tabbed webview screen
    AddTabDialog.tsx
  components/
    TabBar.tsx
    TabChip.tsx
  state/
    tabsStore.ts             # one place for tab state (replaces scattered setState)
    settingsStore.ts         # left-handed mode, defaults
  services/
    twitchUrls.ts            # _generateUrl equivalent, ONE place
    ircClient.ts             # tmi.js wrapper, persistent connection
    backgroundService.ts     # foreground service wiring
  storage/
    persist.ts               # AsyncStorage (replaces SharedPreferences)
  config.ts                  # default channel, extension ID — edit in one place
  types.ts                   # TwitchTab type
```

Three lessons baked into this layout: **one file per concept**, **state lives in one
place not scattered**, and **hardcoded values like `"deemonrider"` and the extension
ID `pm0qkv9g4h87t5y6lg329oam8j7ze9` live in a single config file you can edit**.

### How I'd phase it

Don't try to rewrite in a weekend. That always fails.

1. **Week 1 — Tooling switch.** Install Claude Code (or Cursor). Have it walk you
   through `lib/main.dart` line by line. Don't change any code yet — just understand
   it. Then have it do two small tasks: write a *real* test to replace the broken
   counter test, and extract `TwitchTab` into its own file. Small wins, same
   codebase, you learn the split-file pattern.

2. **Week 2 — Spike the new stack.** Run `npx create-expo-app twitch-companion`.
   Build the smallest possible version: one WebView, one Twitch popout URL. Then —
   and this is the critical test — try loading the extension panel URL
   (`https://www.twitch.tv/popout/deemonrider/extensions/pm0qkv9g4h87t5y6lg329oam8j7ze9/panel`)
   inside that WebView. **If it renders, the rewrite is viable. If it doesn't,
   abort and instead clean up the Flutter code in place.** This is a 1-day spike,
   not a commitment.

3. **Week 3 — Port the UI.** Multiple tabs, reordering, persistence, left-handed
   mode. Feature parity with what you have today.

4. **Week 4+ — Build the new capability.** Add `tmi.js` IRC client + foreground
   service. This is the feature you actually wanted and never built. Building it in a
   clean codebase is much easier than bolting it onto the Flutter version.

5. **Later — multi-streamer settings, iOS testing when you have a device, opening it
   to other streamers.**

### If you'd rather not rewrite

Totally valid. The Flutter app works. To make it maintainable in place:

- Split `lib/main.dart` into ~6 files following the same structure above
  (`lib/models/twitch_tab.dart`, `lib/screens/main_screen.dart`,
  `lib/widgets/tab_bar.dart`, `lib/services/twitch_urls.dart`,
  `lib/state/app_state.dart`, etc.).
- Add a state-management package (Provider or Riverpod) so state isn't scattered
  across `setState` calls.
- Put `"deemonrider"` and the extension ID into a single `lib/config.dart` file.
- Replace the broken counter test with one real test of `_generateUrl`.
- Replace the default Flutter `README.md` with a real description of the app.

This is less learning leverage than the rewrite, but it preserves what works and
removes most of the "scary to change anything" feeling. Either path is honest.

## A note on the README and project name

`README.md` is still the default Flutter template ("A new Flutter project."). Whatever
stack you end up on, replace it with two paragraphs explaining what the app is, who
it's for, and how to run it. If other Twitch streamers might use this someday, this
matters a lot — it's the first thing they'll read.

Also: `my_android_app` is a placeholder name. Naming it something real
(`twitch-tabs`, `streamdeck`, whatever) costs nothing and helps you take the project
seriously.

## TL;DR

1. **Stop copy-pasting code into Claude.ai.** Install [Claude
   Code](https://claude.com/claude-code) and use it on this repo. This alone will
   feel like a different sport.
2. **Spike a React Native + Expo version** for one day. If Twitch extensions load in
   `react-native-webview`, do the rewrite — JS has way more AI training data, Expo's
   dev loop is great for learning, and the IRC libraries you want already exist
   there. If extensions don't load, clean up the Flutter code in place instead.
3. **Either way, split things into smaller files**, put hardcoded values in one
   config, and replace the broken default test. The current single-file structure is
   the main reason changes feel risky.

You built something real that works. Everything above is about making the *next*
year of changes easier, not about anything being wrong with what's there.
