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
