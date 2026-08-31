# Security policy

Mac Cleaner Pro deletes files on your Mac and runs a privileged helper for
system-level cleanup, so security issues here are taken seriously.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security reports. Instead,
email **abdul.hakeem5764@gmail.com** with:

- A description of the issue and its impact.
- Steps to reproduce (a minimal repro is very helpful).
- Which version/build you tested against.

You should get a response within a few days — this is a solo-maintained
project, so please be patient. I'll credit reporters (unless you'd rather
stay anonymous) once a fix ships.

## Scope

Particularly interested in reports involving:

- The Ed25519 rule-pack signature verification (`Core/RulesEngine`).
- The privileged XPC helper's authorization checks (`PrivilegedHelper`,
  `Shared/HelperProtocol.swift`).
- Keychain-stored license/trial data (`Core/Licensing`).
- Anything that could cause the app to delete files outside the paths a user
  explicitly targeted.

## Out of scope

- Bypassing the license/trial gate — the app is free and open source, so this
  isn't a security issue.
- Issues that require physical access to an already-unlocked Mac.
