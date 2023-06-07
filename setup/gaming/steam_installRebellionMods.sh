#!/usr/bin/env bash
set -euxo pipefail
cd '/home/'$USER'/.steam/steam/steamapps/compatdata/204880/pfx/drive_c/users/steamuser/Documents/My Games/Ironclad Games/Sins of a Solar Empire Rebellion/Mods-Rebellion v1.85'
scp cygnus:/zdata/repo/install/games/sins/mods/e4x.7z .
7z x e4x.7z
rm e4x.7z
