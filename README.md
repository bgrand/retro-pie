# retro-pie

Console rétro de salon sur **Raspberry Pi 3B+**, branchée en HDMI sur la TV, avec **RetroPie**.

L'installation est automatisée : on flashe un Raspberry Pi OS minimal, on clone ce dépôt sur le Pi, on lance `./install.sh`, et la console démarre directement sur le menu des jeux.

```
retro-pie/
├── install.sh               ← installation + configuration (relançable sans risque)
├── config/
│   ├── packages.list        ← émulateurs ajoutés à l'installation de base
│   ├── boot-config.txt      ← réglages HDMI/TV ajoutés à config.txt
│   └── retroarch.overrides  ← réglages RetroArch communs à toutes les consoles
├── scripts/
│   ├── backup-saves.sh      ← sauvegarde des parties et de la config
│   └── check-health.sh      ← température, alimentation, stockage, jeux
└── docs/
    ├── emulateurs.md        ← consoles, dossiers, BIOS, performances sur Pi 3
    └── manettes.md          ← configuration, raccourcis, Bluetooth
```

---

## Ce qu'il faut

| Élément | Remarque |
|---|---|
| Raspberry Pi 3B+ | 1 Go de RAM : parfait jusqu'à la PS1, N64 au cas par cas (voir [docs/emulateurs.md](docs/emulateurs.md)) |
| **Alimentation officielle 5,1 V / 2,5 A** | La cause n°1 des ralentissements et plantages. Un chargeur de téléphone ne suffit pas toujours. |
| Carte microSD 32 à 128 Go, classe A1/A2 | Samsung EVO, SanDisk Extreme… |
| Dissipateur (+ petit ventilateur idéalement) | Sans dissipateur, le Pi ralentit de lui-même au-delà de 80 °C |
| Câble HDMI | vers la TV |
| Manette USB ou Bluetooth | voir [docs/manettes.md](docs/manettes.md) |
| Câble Ethernet (conseillé) | installation et copie des jeux plus rapides, Bluetooth plus stable |
| Un PC | pour flasher la carte SD et copier les jeux |

---

## Installation

### 1. Préparer la carte SD

Avec **[Raspberry Pi Imager](https://www.raspberrypi.com/software/)** sur votre PC :

1. **Appareil** : *Raspberry Pi 3*
2. **Système** : *Raspberry Pi OS (other)* > **Raspberry Pi OS Lite (Legacy, 32-bit)**. C'est la version Bookworm, sans bureau.
   > ⚠️ Ne prenez pas la version standard (Trixie) : RetroPie ne la prend pas encore officiellement en charge. Évitez aussi le 64 bits sur Pi 3 : moins d'émulateurs précompilés et plus de RAM consommée.
3. **Modifier les réglages** (roue dentée / « Personnalisation ») :
   - Nom d'hôte : `retropie`
   - Nom d'utilisateur et mot de passe : par exemple `pi` / un mot de passe de votre choix
   - Wi-Fi : seulement si vous n'utilisez pas d'Ethernet
   - Fuseau horaire `Europe/Paris`, clavier `fr`
   - Onglet **Services** : **activer SSH** (authentification par mot de passe)
4. Écrivez la carte, insérez-la dans le Pi, branchez la TV, l'Ethernet, puis l'alimentation **en dernier**.

### 2. Lancer l'installation

Depuis votre PC, connectez-vous au Pi (sous Windows : PowerShell ou Terminal) :

```bash
ssh pi@retropie.local
```

Puis, sur le Pi :

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/bgrand/retro-pie.git
cd retro-pie
./install.sh
```

Le script :
1. vérifie le matériel, la version de l'OS et l'espace disque ;
2. télécharge [RetroPie-Setup](https://github.com/RetroPie/RetroPie-Setup) et fait l'installation de base (EmulationStation et les émulateurs principaux) ;
3. configure le démarrage automatique sur le menu des jeux ;
4. installe les émulateurs de [`config/packages.list`](config/packages.list) ;
5. crée les partages réseau pour copier les jeux depuis le PC ;
6. ajoute les réglages HDMI à `config.txt`. Une copie de l'original est gardée à côté, en `.retro-pie.bak` ;
7. applique les réglages RetroArch.

⏱️ **Comptez une bonne heure**, surtout pour l'étape 2. Ne coupez pas le courant. Si la connexion SSH coupe, relancez simplement `./install.sh` : les étapes déjà faites sont ignorées. Pour ne pas dépendre de la connexion, vous pouvez lancer l'installation dans `tmux` :

```bash
sudo apt-get install -y tmux && tmux new -s install './install.sh'
# en cas de déconnexion : ssh pi@retropie.local puis  tmux attach -t install
```

Un journal complet est écrit dans `install.log`.

### 3. Redémarrer et configurer la manette

```bash
sudo reboot
```

Le Pi démarre sur EmulationStation. Maintenez un bouton de la manette et suivez [docs/manettes.md](docs/manettes.md). Choisissez **Select** comme *Hotkey*.

### 4. Copier les jeux

Depuis le PC, ouvrez le partage réseau :

- **Windows** : dans l'Explorateur, tapez `\\RETROPIE` (ou `\\retropie.local`)
- **macOS** : Finder > Aller > Se connecter au serveur > `smb://retropie.local`
- **Linux** : `smb://retropie.local` dans le gestionnaire de fichiers

Déposez chaque ROM dans le dossier de sa console (`roms/snes`, `roms/psx`…) et les BIOS dans `bios`. Le tableau complet est dans [docs/emulateurs.md](docs/emulateurs.md).

Redémarrez ensuite EmulationStation (**Start** > *Quit* > *Restart EmulationStation*) pour voir les jeux.

> 📜 **Côté légal** : télécharger la ROM d'un jeu que vous ne possédez pas est illégal. Utilisez des copies de vos propres cartouches et disques, ou les nombreux homebrews gratuits et libres.

---

## Options du script

```bash
./install.sh                  # tout : installation + émulateurs + partages + config
./install.sh --config-only    # réapplique uniquement config/ (rapide, après modification)
./install.sh --skip-packages  # sans les émulateurs supplémentaires
./install.sh --no-samba       # sans partages réseau
./install.sh --force          # ignore la vérification de l'OS (à vos risques)
./install.sh --help
```

**Personnaliser** : modifiez les fichiers de `config/`, poussez sur GitHub, puis sur le Pi :

```bash
cd ~/retro-pie && git pull && ./install.sh --config-only && sudo reboot
```

Les réglages de `config.txt` sont placés entre deux balises `# >>> retro-pie` / `# <<< retro-pie`. Relancer le script remplace ce bloc, sans jamais créer de doublon.

---

## Entretien

**Sauvegarder les parties** (sauvegardes de jeu, états et toute la configuration) :

```bash
~/retro-pie/scripts/backup-saves.sh           # → ~/RetroPie/backups, garde les 10 dernières
```

Pour rapatrier les archives sur le PC :

```bash
scp 'pi@retropie.local:RetroPie/backups/*.tar.gz' .
```

Pour une sauvegarde automatique chaque nuit à 3 h, ajoutez une tâche planifiée avec `crontab -e` :

```
0 3 * * * $HOME/retro-pie/scripts/backup-saves.sh >/dev/null 2>&1
```

**Un jeu rame ?** Vérifiez d'abord la santé du Pi :

```bash
~/retro-pie/scripts/check-health.sh
```

« Sous-tension » ou « bridage » ⇒ le problème vient de l'alimentation ou de la chauffe, pas de l'émulateur.

Le script affiche aussi le **stockage** : total, utilisé et libre de la carte SD, de la partition de démarrage et d'un éventuel disque ou clé USB, ainsi que la place prise par les jeux. Le libre passe en jaune sous 20 % et en rouge sous 10 % (ou sous 1 Go sur la carte SD système). Une carte pleine peut empêcher les sauvegardes de parties et les mises à jour.

**Mettre à jour RetroPie** : `sudo ~/RetroPie-Setup/retropie_setup.sh` > *Update*. Faites une sauvegarde avant.

---

## Dépannage

| Problème | Solution |
|---|---|
| Écran noir si la TV est allumée après le Pi | Déjà corrigé par `hdmi_force_hotplug=1`. Sinon, vérifiez que `./install.sh` est allé au bout. |
| Pas de son sur la TV | `hdmi_drive=2` est appliqué. Vérifiez aussi **RetroPie** > *Audio* > *HDMI*. |
| Image qui déborde de l'écran | Réglez la TV en mode « Just Scan / Plein écran / 1:1 » (réglages image). |
| Éclair jaune en haut à droite | Sous-tension : changez d'alimentation ou de câble USB. |
| Les jeux n'apparaissent pas | Mauvais dossier ou extension, ou EmulationStation pas redémarré. |
| Un jeu d'arcade ne se lance pas | Mauvaise version du romset pour l'émulateur (voir [docs/emulateurs.md](docs/emulateurs.md)). |
| `ssh: Could not resolve hostname retropie.local` | Utilisez l'adresse IP du Pi (visible sur votre box, ou **RetroPie** > *Show IP*). |
| Revenir au `config.txt` d'origine | `sudo cp /boot/firmware/config.txt.retro-pie.bak /boot/firmware/config.txt` |

Documentation officielle : https://retropie.org.uk/docs/
