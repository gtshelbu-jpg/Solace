# Upstream Archiso Staging

Put downloaded or copied upstream Arch installer material here, usually the
Arch `releng` archiso profile or a downloaded Arch image used as a reference.

This directory is intentionally ignored by git except for this README. Large
ISO images, extracted images, and copied upstream profile dumps should stay
local-only.

Typical use:

```bash
cp -a /usr/share/archiso/configs/releng ./archiso/upstream/releng
```

Then copy only the Solace-owned files you want to keep into `archiso/profile/`.
