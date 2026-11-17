# Consoles et émulateurs sur Raspberry Pi 3B+

Les ROM vont dans `~/RetroPie/roms/<dossier>` (partage réseau `\\RETROPIE\roms`).
Les BIOS vont dans `~/RetroPie/BIOS` (partage `\\RETROPIE\bios`), sauf mention contraire.

Après avoir copié des jeux, **redémarrez EmulationStation** (Start > Quit > Restart EmulationStation) pour qu'ils apparaissent.

| Console | Dossier | Émulateur conseillé sur Pi 3 | BIOS | Fluidité |
|---|---|---|---|---|
| NES / Famicom | `nes` | lr-fceumm | — | ★★★ parfait |
| Super Nintendo | `snes` | lr-snes9x2010 | — | ★★★ (quelques jeux à puce SuperFX/SA-1 ralentissent) |
| Mega Drive / Genesis | `megadrive` | lr-genesis-plus-gx | — | ★★★ parfait |
| Master System | `mastersystem` | lr-genesis-plus-gx | — | ★★★ parfait |
| Game Gear | `gamegear` | lr-genesis-plus-gx | — | ★★★ parfait |
| Game Boy / Color | `gb` / `gbc` | lr-gambatte | — | ★★★ parfait |
| Game Boy Advance | `gba` | lr-gpsp (ou lr-mgba si un jeu bugue) | `gba_bios.bin` (recommandé) | ★★★ |
| PC Engine | `pcengine` | lr-beetle-pce-fast | `syscard3.pce` pour les jeux CD | ★★★ |
| Atari 2600 | `atari2600` | lr-stella2014 | — | ★★★ |
| Neo Geo Pocket | `ngp` / `ngpc` | lr-beetle-ngp | — | ★★★ |
| PlayStation 1 | `psx` | lr-pcsx-rearmed | `scph1001.bin` (fortement conseillé) | ★★★ la grande majorité des jeux |
| Arcade | `arcade` | lr-fbneo, sinon lr-mame2003-plus | `neogeo.zip` pour la Neo Geo | ★★★ jusqu'au CPS2 / Neo Geo |
| Neo Geo | `neogeo` | lr-fbneo | `neogeo.zip` dans le dossier `neogeo` | ★★★ |
| Mega-CD | `segacd` | lr-genesis-plus-gx | `bios_CD_E.bin`, `bios_CD_U.bin`, `bios_CD_J.bin` | ★★☆ |
| Nintendo 64 | `n64` | mupen64plus (GLideN64 ou rice) | — | ★☆☆ au cas par cas |
| Dreamcast | `dreamcast` | lr-flycast (optionnel) | `dc_boot.bin`, `dc_flash.bin` | ☆☆☆ quelques jeux seulement |

## Points importants

**Arcade : la version des ROM compte.** Une ROM d'arcade doit correspondre à la version de l'émulateur (« romset »). Pour lr-fbneo, il faut un romset FBNeo récent. Pour lr-mame2003-plus, il faut un romset « MAME 2003-Plus ». Une ROM qui ne se lance pas est presque toujours un problème de romset, pas de configuration.

**PlayStation 1.** Les formats `.chd` (compressé) et `.pbp` font gagner beaucoup de place, et un jeu multi-CD tient en un seul `.pbp`. Les couples `.bin` + `.cue` fonctionnent aussi : copiez les deux fichiers.

**Nintendo 64 sur Pi 3.** Mario 64, Mario Kart 64, Star Fox 64 et Zelda Ocarina of Time sont jouables (avec quelques ralentissements). GoldenEye, Conker et Perfect Dark le sont beaucoup moins. Pour changer d'émulateur ou de résolution sur un jeu précis, appuyez sur **A** pendant l'écran de lancement (menu « runcommand »).
- *Select default emulator for ROM* : essayer `mupen64plus-GLideN64` puis `mupen64plus-gles2rice`.
- *Select video mode* : une résolution plus basse (ex. 640x480) peut rendre un jeu fluide.

**BIOS : vérifiez les sommes MD5.** Un BIOS mal nommé ou d'une mauvaise région est ignoré sans message. Les noms de fichier exacts et les sommes MD5 attendues sont dans la doc officielle : https://retropie.org.uk/docs/ (une page par console).

## Ajouter un émulateur

Ajoutez son identifiant dans `config/packages.list`, puis relancez :

```bash
./install.sh
```

Le script ignore ce qui est déjà installé et n'installe que les nouveautés. Vous pouvez aussi passer par le menu officiel : `sudo ~/RetroPie-Setup/retropie_setup.sh` > *Manage packages*.
