#!/usr/bin/env bash
# =============================================================================
#  État de santé du Raspberry Pi : température, alimentation, fréquence,
#  stockage (total et libre par support) et nombre de jeux par console.
#
#  À lancer sur le Pi :   ./scripts/check-health.sh
#  À distance depuis un PC :
#    ssh pi@retropie.local 'bash -s' < scripts/check-health.sh
#
#  Le plus utile après une session de jeu qui a ramé : si « limité » ou
#  « sous-tension » apparaît, le problème vient de l'alimentation ou de la
#  chauffe, pas de l'émulateur.
# =============================================================================
set -uo pipefail

ROMS_DIR="${ROMS_DIR:-$HOME/RetroPie/roms}"
red="\033[1;31m"; green="\033[1;32m"; yellow="\033[1;33m"; off="\033[0m"

have_vc=0; command -v vcgencmd >/dev/null && have_vc=1

echo "=== Température ==="
if [[ $have_vc -eq 1 ]]; then
    t=$(vcgencmd measure_temp | grep -oE '[0-9]+\.[0-9]+')
else
    t=$(awk '{printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "")
fi
if [[ -n "$t" ]]; then
    ti=${t%.*}
    if   (( ti >= 80 )); then c=$red;    msg="TROP CHAUD : le Pi ralentit (limite 80 °C). Ajouter dissipateur/ventilateur."
    elif (( ti >= 70 )); then c=$yellow; msg="Chaud. Un dissipateur est conseillé."
    else                      c=$green;  msg="OK"
    fi
    echo -e "  ${c}${t} °C${off} — $msg"
else
    echo "  indisponible"
fi

echo "=== Alimentation et bridage (throttling) ==="
if [[ $have_vc -eq 1 ]]; then
    raw=$(vcgencmd get_throttled | cut -d= -f2)
    val=$((raw))
    if (( val == 0 )); then
        echo -e "  ${green}Aucun problème depuis le démarrage${off}"
    else
        declare -A bits=(
            [0]="Sous-tension EN COURS (alimentation trop faible)"
            [1]="Fréquence CPU plafonnée EN COURS"
            [2]="Bridage EN COURS"
            [3]="Limite de température atteinte EN COURS"
            [16]="Sous-tension détectée depuis le démarrage"
            [17]="Fréquence plafonnée depuis le démarrage"
            [18]="Bridage survenu depuis le démarrage"
            [19]="Limite de température atteinte depuis le démarrage"
        )
        for b in 0 1 2 3 16 17 18 19; do
            if (( (val >> b) & 1 )); then
                (( b < 16 )) && c=$red || c=$yellow
                echo -e "  ${c}• ${bits[$b]}${off}"
            fi
        done
        if (( val & 0x10001 )); then
            echo "  → Utilisez l'alimentation officielle 5,1 V / 2,5 A et un câble court."
        fi
    fi
    echo "  Fréquence CPU actuelle : $(( $(vcgencmd measure_clock arm | cut -d= -f2) / 1000000 )) MHz"
else
    echo "  vcgencmd indisponible"
fi

echo "=== Stockage ==="
# Affiche total / utilisé / libre d'un système de fichiers, avec une alerte
# colorée quand il se remplit. Chaque support n'est affiché qu'une fois.
human() { (( $1 == 0 )) && { echo "0 o"; return; }; numfmt --to=iec --suffix=o --format="%.1f" "$1" 2>/dev/null || echo "$1 o"; }
seen_devs=" "
show_fs() {
    local label="$1" path="$2" dev total used avail pct c note
    [[ -e "$path" ]] || return 0
    read -r dev total used avail < <(df -PB1 "$path" 2>/dev/null | awk 'NR==2 {print $1, $2, $3, $4}')
    [[ -n "${dev:-}" && "${total:-0}" -gt 0 ]] || return 0
    [[ "$seen_devs" == *" $dev "* ]] && return 0
    seen_devs+="$dev "
    pct=$(( avail * 100 / total ))
    # Moins de 10 % libre = alerte. Sur la carte SD système, moins de 1 Go
    # libre aussi : RetroPie, les mises à jour et les sauvegardes en ont besoin.
    if (( pct < 10 )) || { [[ "$path" == "/" ]] && (( avail < 1073741824 )); }; then
        c=$red; note="presque plein !"
    elif (( pct < 20 )); then
        c=$yellow; note="à surveiller"
    else
        c=$green; note=""
    fi
    # Remplissage calculé en caractères (et non en octets) pour aligner
    # les libellés accentués
    local pad=$(( 22 - ${#label} )); (( pad < 1 )) && pad=1
    printf "  %s%*s total %9s   utilisé %9s   ${c}libre %9s (%3d %%)${off} %s\n" \
        "$label" "$pad" "" "$(human "$total")" "$(human "$used")" "$(human "$avail")" "$pct" "$note"
}

show_fs "Carte SD (système)" /
if mountpoint -q /boot/firmware 2>/dev/null; then
    show_fs "Démarrage" /boot/firmware
elif mountpoint -q /boot 2>/dev/null; then
    show_fs "Démarrage" /boot
fi
# Jeux stockés ailleurs que sur la carte SD (clé ou disque USB monté sur roms)
show_fs "Dossier des jeux" "$ROMS_DIR"
for m in /media/* /media/*/* /mnt/*; do
    mountpoint -q "$m" 2>/dev/null && show_fs "USB $(basename "$m")" "$m"
done

if [[ -d "$ROMS_DIR" ]]; then
    echo "  Place prise par les jeux : $(du -sh "$ROMS_DIR" 2>/dev/null | cut -f1)"
fi

echo "=== Jeux par console ==="
if [[ -d "$ROMS_DIR" ]]; then
    total=0
    for d in "$ROMS_DIR"/*/; do
        [[ -d "$d" ]] || continue
        n=$(find "$d" -maxdepth 2 -type f \
            ! -iname '*.srm' ! -iname '*.sav' ! -iname '*.state*' ! -iname '*.txt' \
            ! -iname '*.cfg' ! -iname '*.xml' ! -name '.*' | wc -l)
        if (( n > 0 )); then
            printf "  %-16s %5d\n" "$(basename "$d")" "$n"
            total=$((total + n))
        fi
    done
    (( total == 0 )) && echo "  Aucun jeu. Copiez vos ROM via \\\\$(hostname)\\roms"
else
    echo "  $ROMS_DIR introuvable"
fi
