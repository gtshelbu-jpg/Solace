# Solace Archiso Workspace

This directory contains the ISO installer work for Solace.

The existing repository bootstrap path stays unchanged:

```bash
./install.sh
```

The archiso path should build on top of that bootstrap installer instead of
replacing it. The intended shape is:

1. Start from Arch's `releng` archiso profile.
2. Add Solace live ISO packages, branding, and installer entrypoints.
3. Install a base Arch system from the live environment.
4. Run the existing Solace bootstrap installer inside the target system.

Suggested local-only layout:

```text
archiso/
├── README.md
├── upstream/
│   └── README.md
├── profile/
│   └── Solace-owned archiso profile files
├── work/
│   └── mkarchiso work directory, ignored by git
└── out/
    └── generated ISO files, ignored by git
```

Do not commit downloaded Arch ISO files, copied upstream releng dumps, or
generated build output. Keep only Solace-owned profile changes in git.

## Derivative interface 1

The builder remains the shared engine. `interface.json` describes the optional
extra-source and target-staging contract. A derivative composes a temporary copy
of this profile; it does not replace or edit the checked-in base profile.

`build.sh --embed-source PATH --extra-source solace-NAME PATH` embeds a reviewed
base and optional derivative under `/opt`. Clean Git trees are archived by default,
so ignored/untracked data is not silently shipped. `--allow-dirty-sources` is only
for explicit development; it is not a release or a reproducibility guarantee.

The optional live `/usr/share/solace/variant-stage-target` hook runs only after an
explicitly confirmed base install/staging action. It receives the mounted target
root and selected login user. A root-owned `/etc/solace/bootstrap` file on the
target can select an embedded `/opt/*/install.sh` first-login entry point. Neither
extension exists on standard Solace images by default.

Local package repositories now require signatures and an explicitly populated
`--gpg-dir`. No TrustAll fallback exists. Configure/sign artifacts in a disposable
build environment, not by importing package keys into the daily-driver host.
The AUR helper requires a full `--sign-key` fingerprint and signs both package and
repository artifacts. It still tracks upstream AUR source unless separately
pinned; that convenience workflow is not an immutable release recipe.

`--clean` accepts only an existing builder-marked work directory. Old unmarked
work trees require manual review rather than automatic deletion. Use separate work
directories per variant. No actual ISO build or cryptographic verification is
implied by the mocked tests in `tests/test_archiso_interface.py`.
