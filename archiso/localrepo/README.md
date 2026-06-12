# Solace Local Package Repository

Put locally built pacman packages for the ISO here.

This is the right place for AUR-built packages such as Calamares. The package
files and repository database are ignored by git; this README is kept so the
directory exists in fresh checkouts.

After placing packages here, refresh the repo database:

```bash
repo-add archiso/localrepo/solace-local.db.tar.gz archiso/localrepo/*.pkg.tar.*
```

When packages exist in this directory, `archiso/build.sh` automatically builds
from a temporary profile copy with this local repository appended to
`pacman.conf`.
