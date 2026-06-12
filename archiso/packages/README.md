# ISO Package Notes

Packages required by the live ISO should go in one of two places:

1. Official Arch packages: add the package name to
   `archiso/profile/packages.x86_64`.
2. AUR or locally built packages: build them into `archiso/localrepo/`, then add
   the package name to `archiso/profile/packages.x86_64`.

For Calamares, prefer building the AUR package into the local repository:

```bash
./archiso/build-aur-package.sh calamares
```

Then add this to `archiso/profile/packages.x86_64`:

```text
calamares
```

The ISO build wrapper automatically exposes `archiso/localrepo/` as the
`[solace-local]` pacman repository when local packages are present.
