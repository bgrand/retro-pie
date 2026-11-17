# Manettes

## Premier démarrage

Au premier lancement, EmulationStation affiche **« Welcome — No gamepads detected »**.

1. Branchez la manette en USB (le plus simple pour la configuration).
2. **Maintenez un bouton** jusqu'à ce que l'écran de configuration apparaisse.
3. Appuyez sur chaque bouton demandé. Pour un bouton absent de la manette, **maintenez n'importe quel bouton** pour passer.
4. **Hotkey Enable** : choisissez **Select**. C'est le bouton des raccourcis (tableau ci-dessous).
5. Validez sur **OK**.

Cette configuration est automatiquement reportée dans RetroArch, donc valable pour toutes les consoles.

Pour reconfigurer plus tard : **Start** > *Configure Input*.

> Conseil : désignez **A = bas** et **B = droite** (disposition Nintendo), quelle que soit votre manette. RetroPie associe les boutons par position, pas par nom.

## Raccourcis en jeu (Hotkey = Select)

| Combinaison | Action |
|---|---|
| **Select + Start** | Quitter le jeu, retour au menu |
| **Select + R** | Sauvegarder l'état (save state) |
| **Select + L** | Charger l'état |
| **Select + ← / →** | Changer d'emplacement de sauvegarde |
| **Select + X** | Menu RetroArch (options, shaders, triches…) |
| **Select + B** | Réinitialiser le jeu (reset) |

Ces raccourcis concernent les émulateurs RetroArch (`lr-*`), c'est-à-dire presque toutes les consoles. Pour **mupen64plus** (N64 autonome), seul **Select + Start** pour quitter est garanti.

## Manettes Bluetooth

1. Sur le Pi : **RetroPie** (dans le menu principal) > **Bluetooth** > *Register and Connect to Bluetooth Device*.
2. Mettez la manette en mode appairage :
   - **DualShock 4 / DualSense** : maintenir *Share* + *PS* jusqu'au clignotement rapide.
   - **8BitDo** : voir la notice. En général *Start* + un bouton de mode (X = mode X-input, B = Switch…), puis le bouton d'appairage.
   - **Manette Switch Pro** : maintenir le petit bouton de synchronisation sur la tranche.
3. Sélectionnez-la dans la liste et choisissez *DisplayYesNo* si une méthode de sécurité est demandée.
4. Configurez-la ensuite comme au premier démarrage (maintenir un bouton).

Le Bluetooth 4.2 du Pi 3B+ partage son antenne avec le Wi-Fi 2,4 GHz. Si la manette **décroche ou a du lag** :
- branchez le Pi en **Ethernet** ou passez le Wi-Fi en **5 GHz** ;
- ou utilisez une manette avec **dongle USB 2,4 GHz** (8BitDo avec récepteur, manettes Logitech F710) : c'est la solution la plus fiable.

## Deux joueurs ou plus

Chaque manette se configure une fois (maintenir un bouton sur la nouvelle manette dans *Configure Input*). L'ordre des joueurs suit l'ordre de branchement ou de connexion. Pour le fixer : **RetroPie** > **RetroArch** > *Settings* > *Input* > *Port 1/2 Controls*.

## Manette HutoPi USB SNES

Manette filaire USB au style Super Nintendo (réf. fabricant `kubsnes`). Elle est reconnue directement par le Pi, sans pilote. C'est la manette idéale pour les consoles 8 et 16 bits.

### Configuration

1. Branchez-la sur un port USB du Pi **avant** de l'allumer, ou à tout moment dans *Configure Input*.
2. Maintenez un bouton, puis associez les touches comme ci-dessous. La disposition est la même que sur une vraie SNES, donc les boutons portent les bons noms.

| Demandé par EmulationStation | Bouton de la manette |
|---|---|
| D-pad haut / bas / gauche / droite | Croix directionnelle |
| Start / Select | Start / Select |
| A / B / X / Y | A / B / X / Y |
| Left Shoulder / Right Shoulder | L / R |
| Left Trigger, Right Trigger, Left/Right Thumb, sticks analogiques | **absents** : maintenir un bouton pour passer |
| Hotkey Enable | **Select** |

Selon les séries, la croix est vue comme des boutons ou comme un axe : ça n'a pas d'importance, il suffit d'appuyer sur la direction demandée.

### Ce qu'elle permet de jouer

| Console | Résultat |
|---|---|
| NES, SNES, Master System, Game Gear, Game Boy / Color / Advance, PC Engine, Atari 2600 | Parfait |
| Mega Drive | Très bien : les 6 boutons tombent sur A, B, X, Y, L, R |
| Arcade, Neo Geo | Bien pour la grande majorité des jeux |
| PlayStation 1 | Jouable pour les jeux qui n'utilisent ni L2/R2 ni les sticks analogiques |
| Nintendo 64 | Déconseillée : pas de stick analogique, pas de boutons C ni de gâchette Z |

Pour la PS1 et la N64, ajoutez une manette à deux sticks (DualShock 4, 8BitDo Pro 2…). Chaque manette garde sa propre configuration.

### Conseils

- **Câble court** (environ 1,2 à 1,4 m) : prévoyez une **rallonge USB 2.0 de 2 à 3 m** pour jouer depuis le canapé.
- **À deux** : branchez une deuxième manette identique et configurez-la de la même façon (maintenir un bouton sur la nouvelle manette dans *Configure Input*). Le joueur 1 est la première manette branchée. Pour fixer l'ordre, voir la section *Deux joueurs ou plus*.
- **Une touche ne répond plus ou est mal placée** : **Start** > *Configure Input* et refaites la configuration. Elle remplace l'ancienne.

## Manette HutoPi USB NES

Manette filaire USB au style NES (réf. fabricant `KUBNES`). Elle est reconnue directement par le Pi, sans pilote. Elle n'a que **4 boutons** (A, B, Select, Start) et une croix : idéale pour les consoles 8 bits, trop limitée au-delà.

### Configuration

1. Branchez-la sur un port USB du Pi **avant** de l'allumer, ou à tout moment dans *Configure Input*.
2. Maintenez un bouton, puis associez les touches comme ci-dessous.

| Demandé par EmulationStation | Bouton de la manette |
|---|---|
| D-pad haut / bas / gauche / droite | Croix directionnelle |
| Start / Select | Start / Select |
| A / B | A / B |
| X, Y, Left/Right Shoulder, Triggers, Thumbs, sticks analogiques | **absents** : maintenir un bouton pour passer |
| Hotkey Enable | **Select** |

### Raccourcis : ce qui change

Sans boutons X, L et R, la plupart des raccourcis par défaut ne sont pas disponibles :

| Raccourci | Avec cette manette |
|---|---|
| Select + Start (quitter) | ✅ fonctionne |
| Select + B (reset) | ✅ fonctionne |
| Select + ← / → (emplacement de sauvegarde) | ✅ fonctionne |
| Select + R / Select + L (sauvegarder / charger) | ❌ pas de bouton R ni L |
| Select + X (menu RetroArch) | ❌ pas de bouton X |

**Solution recommandée : ouvrir le menu RetroArch avec Select + A.** Depuis ce menu, on peut sauvegarder et charger l'état (*Quick Menu* > *Save State* / *Load State*). Une fois la manette configurée, sur le Pi en SSH :

```bash
cd /opt/retropie/configs/all/retroarch-joypads/
ls                        # repérer le fichier de la manette NES
grep input_a_btn "NOM DU FICHIER.cfg"     # ex. : input_a_btn = "1"
echo 'input_menu_toggle_btn = "1"' >> "NOM DU FICHIER.cfg"   # même numéro que input_a_btn
```

Le changement ne concerne que cette manette. Si vous refaites *Configure Input* pour elle, le fichier est régénéré et la ligne doit être ajoutée de nouveau.

### Ce qu'elle permet de jouer

| Console | Résultat |
|---|---|
| NES / Famicom | Parfait, c'est fait pour |
| Master System, Game Boy / Color, PC Engine, Atari 2600, Neo Geo Pocket | Parfait (2 boutons suffisent) |
| Game Gear | Parfait |
| Game Boy Advance | Limité : L et R manquent, gênant dans beaucoup de jeux |
| Mega Drive | Limité : 2 boutons sur 3 (C manque) |
| SNES | Limité : X, Y, L, R manquent ; seuls quelques jeux restent jouables |
| Arcade, Neo Geo | Seulement les jeux à 1 ou 2 boutons |
| PlayStation 1, Nintendo 64 | Non |

Pour les consoles 16 bits, la [manette HutoPi USB SNES](#manette-hutopi-usb-snes) est le complément naturel : les deux peuvent rester branchées en même temps.

### Conseils

- **Câble court** : prévoyez une **rallonge USB 2.0 de 2 à 3 m** pour jouer depuis le canapé.
- **Diagonales** : comme sur la NES d'origine, la croix carrée rend les diagonales moins précises qu'une croix SNES. C'est sans conséquence sur les jeux NES, mais peut gêner sur les jeux de combat.
- **À deux** : branchez une deuxième manette et configurez-la de la même façon (voir *Deux joueurs ou plus*).

## Manette Xbox

- **Filaire (Xbox 360 / One / Series en USB)** : fonctionne directement.
- **Sans fil (Xbox One / Series en Bluetooth)** : nécessite le pilote *xpadneo*. Sur le Pi, lancez `sudo ~/RetroPie-Setup/retropie_setup.sh` > *Manage packages* > *driver* > *xpadneo*, puis appairez-la comme ci-dessus.
