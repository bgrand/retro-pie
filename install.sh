#!/usr/bin/env bash
# =============================================================================
#  retro-pie — installation automatisée de RetroPie sur Raspberry Pi 3B+
#  Usage : console de salon branchée en HDMI sur une TV.
#
#  À lancer sur le Raspberry Pi, en utilisateur normal (pas en root) :
#      ./install.sh            installation complète
#      ./install.sh --help     options
#
#  Le script est idempotent : on peut le relancer sans risque, par exemple
#  après avoir modifié un fichier du dossier config/.
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="${SETUP_DIR:-$HOME/RetroPie-Setup}"
SETUP_REPO="https://github.com/RetroPie/RetroPie-Setup.git"
LOG_FILE="$REPO_DIR/install.log"

# Chemins surchargeables (utile pour les tests hors Raspberry Pi)
BOOT_CONFIG="${BOOT_CONFIG:-}"
RETROARCH_CFG="${RETROARCH_CFG:-/opt/retropie/configs/all/retroarch.cfg}"

PACKAGES_FILE="$REPO_DIR/config/packages.list"
BOOT_BLOCK_FILE="$REPO_DIR/config/boot-config.txt"
RETROARCH_OVERRIDES="$REPO_DIR/config/retroarch.overrides"

MARK_BEGIN="# >>> retro-pie (github.com/bgrand/retro-pie) >>>"
MARK_END="# <<< retro-pie <<<"

DO_INSTALL=1
DO_PACKAGES=1
DO_CONFIG=1
DO_SAMBA=1
FORCE=0

# --- Affichage ---------------------------------------------------------------
c_info="\033[1;34m"; c_ok="\033[1;32m"; c_warn="\033[1;33m"; c_err="\033[1;31m"; c_off="\033[0m"
info() { echo -e "${c_info}==>${c_off} $*"; }
ok()   { echo -e "${c_ok}✔${c_off}  $*"; }
warn() { echo -e "${c_warn}!${c_off}  $*" >&2; }
die()  { echo -e "${c_err}✘${c_off}  $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage : $(basename "$0") [options]

Installe RetroPie et applique la configuration « console de salon » pour
Raspberry Pi 3B+.

Options :
  --config-only     N'installe rien : applique seulement les fichiers de
                    config/ (config.txt, RetroArch). Rapide.
  --skip-packages   N'installe pas les émulateurs de config/packages.list
  --no-samba        Ne crée pas les partages réseau (roms, bios…)
  --force           Ignore la vérification de version de l'OS
  -h, --help        Affiche cette aide

Variables d'environnement :
  SETUP_DIR         Dossier de RetroPie-Setup (défaut : ~/RetroPie-Setup)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --config-only)   DO_INSTALL=0; DO_PACKAGES=0; DO_SAMBA=0 ;;
        --skip-packages) DO_PACKAGES=0 ;;
        --no-samba)      DO_SAMBA=0 ;;
        --force)         FORCE=1 ;;
        -h|--help)       usage; exit 0 ;;
        *)               usage; die "Option inconnue : $1" ;;
    esac
    shift
done

# =============================================================================
#  Fonctions de configuration (pures, testables hors Pi)
# =============================================================================

# Remplace (ou ajoute) le bloc balisé retro-pie dans un fichier config.txt.
# $1 = fichier cible, $2 = fichier contenant le bloc à insérer
apply_boot_block() {
    local target="$1" block="$2" tmp
    tmp="$(mktemp)"
    # Supprime un éventuel bloc précédent, puis ajoute le nouveau à la fin
    # (dans config.txt, la dernière valeur lue l'emporte).
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip
    ' "$target" > "$tmp"
    # Retire les lignes vides finales pour éviter qu'elles s'accumulent
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$tmp"
    {
        echo ""
        echo "$MARK_BEGIN"
        # Repart d'une section valable pour tous les modèles : si le fichier
        # se termine par [pi4], [cm4]… nos réglages s'y appliqueraient seuls.
        echo "[all]"
        grep -v '^[[:space:]]*$' "$block" | grep -v '^[[:space:]]*#' || true
        echo "$MARK_END"
    } >> "$tmp"
    cat "$tmp" > "$target"
    rm -f "$tmp"
}

# Fusionne des réglages « clé = "valeur" » dans un fichier retroarch.cfg.
# Une clé existante (même commentée) est remplacée ; sinon elle est ajoutée.
# $1 = retroarch.cfg cible, $2 = fichier de surcharges
apply_retroarch_overrides() {
    local target="$1" overrides="$2" tmp
    tmp="$(mktemp)"
    awk '
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        NR == FNR {
            if ($0 ~ /^[ \t]*($|#)/) next
            eq = index($0, "=")
            if (!eq) next
            k = trim(substr($0, 1, eq - 1))
            v = trim(substr($0, eq + 1))
            val[k] = v; order[++n] = k
            next
        }
        {
            line = $0
            probe = line
            sub(/^[ \t]*#[ \t]*/, "", probe)
            eq = index(probe, "=")
            if (eq) {
                k = trim(substr(probe, 1, eq - 1))
                if ((k in val) && !(k in done)) {
                    print k " = " val[k]; done[k] = 1; next
                }
            }
            print line
        }
        END {
            hdr = 0
            for (i = 1; i <= n; i++) {
                k = order[i]
                if (k in done) continue
                if (!hdr) { print ""; print "# --- ajouts retro-pie ---"; hdr = 1 }
                print k " = " val[k]
            }
        }
    ' "$overrides" "$target" > "$tmp"
    cat "$tmp" > "$target"
    rm -f "$tmp"
}

# Permet de sourcer le script dans les tests sans rien exécuter
if [[ "${RETRO_PIE_SOURCE_ONLY:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi

# =============================================================================
#  Vérifications
# =============================================================================
preflight() {
    [[ $EUID -ne 0 ]] || die "Ne pas lancer en root. Lancez : ./install.sh (sudo sera demandé si besoin)."
    command -v sudo >/dev/null || die "sudo est requis."

    local model=""
    [[ -r /proc/device-tree/model ]] && model="$(tr -d '\0' < /proc/device-tree/model)"
    if [[ "$model" != *"Raspberry Pi"* ]]; then
        [[ $FORCE -eq 1 ]] || die "Ce n'est pas un Raspberry Pi (modèle : '${model:-inconnu}'). --force pour passer outre."
        warn "Matériel non reconnu, on continue (--force)."
    elif [[ "$model" != *"Raspberry Pi 3"* ]]; then
        warn "Détecté : $model. Ce projet est réglé pour un Pi 3B+, ça devrait fonctionner mais n'est pas testé."
    else
        ok "Matériel : $model"
    fi

    # shellcheck disable=SC1091
    . /etc/os-release
    case "${VERSION_CODENAME:-}" in
        buster|bullseye|bookworm)
            ok "Système : ${PRETTY_NAME:-$VERSION_CODENAME}" ;;
        *)
            if [[ $FORCE -eq 1 ]]; then
                warn "Système ${VERSION_CODENAME:-inconnu} non validé par RetroPie, on continue (--force)."
            else
                die "Système '${VERSION_CODENAME:-inconnu}' non supporté. Utilisez Raspberry Pi OS Lite (Legacy, 32-bit) — Bookworm. Voir README."
            fi ;;
    esac

    if [[ "$(uname -m)" == "aarch64" ]]; then
        warn "OS 64 bits détecté. Sur Pi 3, l'OS 32 bits est recommandé (plus d'émulateurs précompilés, moins de RAM utilisée)."
    fi

    local free_mb
    free_mb=$(df -Pm "$HOME" | awk 'NR==2 {print $4}')
    if (( free_mb < 4000 )); then
        warn "Seulement ${free_mb} Mo libres. Prévoir au moins 4 Go pour RetroPie, plus la place des jeux."
    fi
}

find_boot_config() {
    if [[ -n "$BOOT_CONFIG" ]]; then echo "$BOOT_CONFIG"; return; fi
    if [[ -f /boot/firmware/config.txt ]]; then echo /boot/firmware/config.txt
    elif [[ -f /boot/config.txt ]]; then echo /boot/config.txt
    else die "config.txt introuvable (ni /boot/firmware ni /boot)."
    fi
}

# =============================================================================
#  Étapes
# =============================================================================
step_prerequisites() {
    info "Mise à jour de la liste des paquets et installation de git…"
    sudo apt-get update
    sudo apt-get install -y git dialog
}

step_retropie_setup() {
    if [[ -d "$SETUP_DIR/.git" ]]; then
        info "Mise à jour de RetroPie-Setup…"
        git -C "$SETUP_DIR" pull --ff-only || warn "Mise à jour de RetroPie-Setup impossible, on garde la version actuelle."
    else
        info "Téléchargement de RetroPie-Setup…"
        git clone --depth=1 "$SETUP_REPO" "$SETUP_DIR"
    fi
}

rp() { sudo "$SETUP_DIR/retropie_packages.sh" "$@"; }

step_basic_install() {
    if [[ -x /opt/retropie/supplementary/emulationstation/emulationstation ]]; then
        ok "RetroPie est déjà installé : installation de base ignorée."
        return
    fi
    info "Installation de base de RetroPie (EmulationStation + émulateurs principaux)."
    info "C'est l'étape la plus longue : comptez une bonne heure sur Pi 3, ne coupez pas le courant."
    rp setup basic_install
    ok "Installation de base terminée."
}

step_packages() {
    [[ -f "$PACKAGES_FILE" ]] || { warn "$PACKAGES_FILE absent, étape ignorée."; return; }
    local pkg failed=()
    # Lecture sur le descripteur 3 : les installations ne doivent pas
    # consommer la liste des paquets via l'entrée standard.
    while read -r pkg <&3; do
        pkg="${pkg%%#*}"; pkg="${pkg//[[:space:]]/}"
        [[ -z "$pkg" ]] && continue
        if [[ -d "/opt/retropie/libretrocores/$pkg" || -d "/opt/retropie/emulators/$pkg" ]]; then
            ok "$pkg déjà installé"
            continue
        fi
        info "Installation de $pkg…"
        if rp "$pkg"; then ok "$pkg installé"; else warn "Échec de $pkg"; failed+=("$pkg"); fi
    done 3< "$PACKAGES_FILE"
    if (( ${#failed[@]} )); then
        warn "Paquets en échec : ${failed[*]} — à réessayer via : sudo $SETUP_DIR/retropie_setup.sh"
    fi
}

step_samba() {
    info "Partages réseau Samba (roms, bios, configs, splashscreens)…"
    rp samba depends
    rp samba install_shares
    ok "Partages créés : \\\\$(hostname)\\roms depuis Windows, smb://$(hostname).local/roms depuis macOS/Linux."
}

step_autostart() {
    info "Démarrage automatique sur EmulationStation…"
    if command -v raspi-config >/dev/null; then
        # B2 = console, connexion automatique de l'utilisateur
        sudo raspi-config nonint do_boot_behaviour B2
    fi
    rp autostart enable
    ok "La console démarrera directement sur le menu des jeux."
}

step_boot_config() {
    local cfg; cfg="$(find_boot_config)"
    info "Réglages HDMI/TV dans $cfg…"
    [[ -f "$cfg.retro-pie.bak" ]] || sudo cp "$cfg" "$cfg.retro-pie.bak"
    local tmp; tmp="$(mktemp)"
    sudo cat "$cfg" > "$tmp"
    apply_boot_block "$tmp" "$BOOT_BLOCK_FILE"
    sudo cp "$tmp" "$cfg"
    rm -f "$tmp"
    ok "config.txt mis à jour (sauvegarde d'origine : $cfg.retro-pie.bak)."
}

step_retroarch() {
    if [[ ! -f "$RETROARCH_CFG" ]]; then
        warn "$RETROARCH_CFG absent (RetroPie pas encore installé ?). Réglages RetroArch ignorés."
        return
    fi
    info "Réglages RetroArch communs à toutes les consoles…"
    [[ -f "$RETROARCH_CFG.retro-pie.bak" ]] || cp "$RETROARCH_CFG" "$RETROARCH_CFG.retro-pie.bak"
    apply_retroarch_overrides "$RETROARCH_CFG" "$RETROARCH_OVERRIDES"
    ok "retroarch.cfg mis à jour."
}

# =============================================================================
#  Programme principal
# =============================================================================
main() {
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo; info "retro-pie — $(date '+%F %T')"

    preflight

    if [[ $DO_INSTALL -eq 1 ]]; then
        step_prerequisites
        step_retropie_setup
        step_basic_install
        step_autostart
    fi
    if [[ $DO_PACKAGES -eq 1 ]]; then step_packages; fi
    if [[ $DO_SAMBA -eq 1 ]]; then step_samba; fi
    if [[ $DO_CONFIG -eq 1 ]]; then
        step_boot_config
        step_retroarch
    fi

    echo
    ok "Terminé. Journal complet : $LOG_FILE"
    info "Redémarrez pour appliquer : sudo reboot"
    info "Au premier démarrage, EmulationStation vous demandera de configurer la manette (voir docs/manettes.md)."
}

main
