# Solace Local Package Repository

Put locally built pacman packages for the ISO here.

This is the right place for AUR-built packages such as Calamares. The package
files and repository database are ignored by git; this README is kept so the
directory exists in fresh checkouts.

Packages must have detached signatures from an explicitly trusted build key.
After placing signed packages here, sign the repo database (use the exact package
paths; do not pass `*.sig` files as package inputs):

```bash
repo-add --sign --key YOUR_FULL_FINGERPRINT archiso/localrepo/solace-local.db.tar.gz archiso/localrepo/*.pkg.tar.zst
```

When packages exist here, `archiso/build.sh --gpg-dir /path/to/build/keyring`
uses a temporary profile with this repository appended and requires trusted package
and database signatures. Missing/invalid signatures fail closed. No private signing
keys belong in this directory or Git; ignored files are not necessarily safe files.
