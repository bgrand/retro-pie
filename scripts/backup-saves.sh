#!/usr/bin/env bash
# =============================================================================
#  Sauvegarde des parties et de la configuration RetroPie
#
#  À lancer sur le Pi :   ./scripts/backup-saves.sh [-d dossier] [-k nombre]
#    -d  dossier de destination  (défaut : ~/RetroPie/backups)
#    -k  nombre d'archives gardées (défaut : 10, les plus anciennes sont effacées)
#
#  Contenu de l'archive :
#    - sauvegardes de jeu (.srm, .sav, .eep, .fla, .mpk…) et états (.state*)
#      trouvés dans ~/RetroPie/roms
#    - toute la configuration /opt/retropie/configs (manettes, RetroArch,
#      listes de jeux d'EmulationStation…)
#
#  Récupérer les archives sur un PC :
#    scp 'pi@retropie.local:RetroPie/backups/*.tar.gz' .
# =============================================================================
set -euo pipefail

DEST="$HOME/RetroPie/backups"
KEEP=10
ROMS_DIR="${ROMS_DIR:-$HOME/RetroPie/roms}"
CONFIGS_DIR="${CONFIGS_DIR:-/opt/retropie/configs}"

while getopts "d:k:h" opt; do
    case "$opt" in
        d) DEST="$OPTARG" ;;
        k) KEEP="$OPTARG" ;;
        *) sed -n '2,20p' "$0"; exit 0 ;;
    esac
done

[[ "$KEEP" =~ ^[0-9]+$ && "$KEEP" -ge 1 ]] || { echo "-k doit être un entier ≥ 1" >&2; exit 1; }
mkdir -p "$DEST"

stamp="$(date '+%Y%m%d-%H%M%S')"
archive="$DEST/retropie-backup-$stamp.tar.gz"
list="$(mktemp)"
trap 'rm -f "$list"' EXIT

# Fichiers de sauvegarde à côté des ROM
if [[ -d "$ROMS_DIR" ]]; then
    find "$ROMS_DIR" -type f \( \
        -iname '*.srm' -o -iname '*.sav' -o -iname '*.eep' -o -iname '*.fla' \
        -o -iname '*.mpk' -o -iname '*.sra' -o -iname '*.mcr' -o -iname '*.rtc' \
        -o -iname '*.state' -o -iname '*.state[0-9]*' -o -iname '*.state.auto' \
        -o -iname '*.nv' -o -iname '*.hi' \
        \) -print > "$list"
fi
saves=$(wc -l < "$list")

# Configuration complète
[[ -d "$CONFIGS_DIR" ]] && echo "$CONFIGS_DIR" >> "$list"

if [[ ! -s "$list" ]]; then
    echo "Rien à sauvegarder (ni $ROMS_DIR ni $CONFIGS_DIR)." >&2
    exit 1
fi

# --ignore-failed-read : certains fichiers de config peuvent appartenir à root
tar --ignore-failed-read -czf "$archive" -T "$list" 2> >(grep -v 'Removing leading' >&2)

echo "✔ $archive ($(du -h "$archive" | cut -f1)) — $saves fichier(s) de sauvegarde + configuration"

# Rotation : ne garder que les $KEEP plus récentes
mapfile -t old < <(ls -1t "$DEST"/retropie-backup-*.tar.gz 2>/dev/null | tail -n +"$((KEEP + 1))")
if (( ${#old[@]} )); then
    rm -f -- "${old[@]}"
    echo "  ${#old[@]} ancienne(s) archive(s) supprimée(s) (on en garde $KEEP)."
fi
