# Solace Archiso Profile

This is the tracked Solace archiso profile.

It started as a copy of Arch's installed `releng` profile:

```bash
cp -a /usr/share/archiso/configs/releng archiso/profile
```

Edit this directory for Solace ISO behavior, packages, live environment files,
Calamares configuration, branding, and installer entrypoints.

Build from the repository root with:

```bash
./archiso/build.sh
```

Build from a clean work directory with:

```bash
./archiso/build.sh --clean
```

Generated output belongs in `archiso/out/` and temporary build state belongs in
`archiso/work/`; both are ignored by git.
