# Node / npx install checklists (skills sync)

English default. Shown when `/build` HITL chooses **Open setup** and Node/`npx` is missing. Detect the OS and print **only** the matching block. Never auto-install.

Canonical source for tone: `.scratch/skills-auto-provisioning-v2/assets/prototype-node-gate-messages.md`.

## Linux

```text
Node.js (including `npx`) is required to sync skills.

1) sudo apt update
2) sudo apt install nodejs npm

Check: `node -v` and `npx -v`
Then run /build again (or say “open setup” again).
```

## macOS

```text
Node.js (including `npx`) is required to sync skills.

1) Install Homebrew (if needed):
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

2) Homebrew prints “Next steps” with two commands to add Brew to your PATH.
   Copy and run them in the terminal (the agent cannot reliably do this for you).

3) brew install node

Check: `node -v` and `npx -v`
Then run /build again (or say “open setup” again).
```

## Windows

```text
Node.js (including `npx`) is required to sync skills.

1) winget install OpenJS.NodeJS.LTS
2) Close and reopen the terminal (to refresh PATH)

Check: `node -v` and `npx -v`
Then run /build again (or say “open setup” again).
```

## OS unknown

```text
Node.js + npx are required to update skills.
Install the LTS build from https://nodejs.org and run /build again.
```
