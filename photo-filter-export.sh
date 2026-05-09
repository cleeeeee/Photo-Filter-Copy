#!/usr/bin/env bash
# ============================================================================
#  Photo-Filter-Export
# ============================================================================
#  Script Bash pour filtrer et exporter des photos selon des critères précis :
#  orientation, dimensions, ratio, format de fichier.
#
#  Auteur  : Lechevlu (Cle)
#  Licence : MIT
#  Dépôt   : https://github.com/cleeeeee/Photo-Filter-Export
#
#  Prérequis :
#    - Bash 3.2+
#    - ImageMagick 7+ (commande `magick`)
#
#  Usage rapide :
#    ./photo-filter-export.sh --orientation portrait DOSSIER_SOURCE DOSSIER_DEST
#
#  Pour l'aide complète :
#    ./photo-filter-export.sh --help
# ============================================================================
set -e

# ============================================================================
#  SECTION 1 — COULEURS & AFFICHAGE
# ============================================================================
# Couleurs ANSI pour un affichage lisible dans le terminal.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Fonctions d'affichage avec préfixes visuels
info()    { echo -e "${BLUE}ℹ${RESET}  $*"; }
success() { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✖${RESET}  $*" >&2; }

# ============================================================================
#  SECTION 2 — AIDE & VERSION
# ============================================================================

VERSION="1.0.0"

show_help() {
  cat <<EOF

${BOLD}Photo-Filter-Export${RESET} v${VERSION}
${DIM}Filtre et exporte des photos selon des critères précis.${RESET}

${BOLD}USAGE${RESET}
  ./photo-filter-export.sh [OPTIONS] DOSSIER_SOURCE DOSSIER_DESTINATION

${BOLD}OPTIONS DE FILTRAGE${RESET}
  ${CYAN}--orientation${RESET} <portrait|landscape|square>
      Filtre par orientation de l'image.
      • portrait  : hauteur > largeur  (photos verticales)
      • landscape : largeur > hauteur  (photos horizontales)
      • square    : largeur == hauteur (photos carrées)

  ${CYAN}--min-width${RESET} <pixels>
      Largeur minimale requise (en pixels).

  ${CYAN}--max-width${RESET} <pixels>
      Largeur maximale autorisée (en pixels).

  ${CYAN}--min-height${RESET} <pixels>
      Hauteur minimale requise (en pixels).

  ${CYAN}--max-height${RESET} <pixels>
      Hauteur maximale autorisée (en pixels).

  ${CYAN}--min-ratio${RESET} <decimal>
      Ratio largeur/hauteur minimum (ex: 0.5 = format très vertical).

  ${CYAN}--max-ratio${RESET} <decimal>
      Ratio largeur/hauteur maximum (ex: 1.0 = pas plus large que carré).

  ${CYAN}--formats${RESET} <ext1,ext2,...>
      Formats de fichiers à inclure, séparés par des virgules.
      Par défaut : jpg,jpeg,png,tif,tiff,webp,heic

${BOLD}OPTIONS GÉNÉRALES${RESET}
  ${CYAN}--copy${RESET}
      Copie les fichiers (comportement par défaut).

  ${CYAN}--move${RESET}
      Déplace les fichiers au lieu de les copier.
      ${YELLOW}⚠ Attention : les originaux seront supprimés du dossier source.${RESET}

  ${CYAN}--flat${RESET}
      Copie tous les fichiers à la racine du dossier de sortie
      (pas de reproduction de l'arborescence).

  ${CYAN}--dry-run${RESET}
      Simule l'opération sans copier/déplacer aucun fichier.
      Utile pour vérifier les critères avant de lancer pour de vrai.

  ${CYAN}--recursive${RESET}
      Parcourt les sous-dossiers récursivement (activé par défaut).

  ${CYAN}--no-recursive${RESET}
      Ne traite que le dossier de premier niveau (pas les sous-dossiers).

  ${CYAN}--verbose${RESET}
      Affiche les détails de chaque fichier analysé (même ceux ignorés).

  ${CYAN}--help${RESET}
      Affiche cette aide.

  ${CYAN}--version${RESET}
      Affiche la version du script.

${BOLD}EXEMPLES${RESET}

  ${DIM}# Exporter uniquement les photos verticales (reels/shorts)${RESET}
  ./photo-filter-export.sh --orientation portrait ./retouches ./reels-prep

  ${DIM}# Exporter les paysages de plus de 3000px de large${RESET}
  ./photo-filter-export.sh --orientation landscape --min-width 3000 ./raw ./export-hd

  ${DIM}# Simuler un export de photos carrées en JPEG uniquement${RESET}
  ./photo-filter-export.sh --orientation square --formats jpg,jpeg --dry-run ./src ./dst

  ${DIM}# Exporter les photos très verticales (ratio < 0.7) pour les reels${RESET}
  ./photo-filter-export.sh --max-ratio 0.7 ./retouches ./vertical-content

  ${DIM}# Déplacer les photos en mode flat (pas de sous-dossiers)${RESET}
  ./photo-filter-export.sh --orientation portrait --move --flat ./src ./dst

EOF
}

show_version() {
  echo "Photo-Filter-Export v${VERSION}"
}

# ============================================================================
#  SECTION 3 — VALEURS PAR DÉFAUT
# ============================================================================
# Ces valeurs sont utilisées si l'utilisateur ne passe pas les options.

ORIENTATION=""           # Pas de filtre d'orientation par défaut
MIN_WIDTH=0              # Pas de largeur minimum
MAX_WIDTH=999999         # Pas de largeur maximum
MIN_HEIGHT=0             # Pas de hauteur minimum
MAX_HEIGHT=999999        # Pas de hauteur maximum
MIN_RATIO=""             # Pas de ratio minimum
MAX_RATIO=""             # Pas de ratio maximum
FORMATS="jpg,jpeg,png,tif,tiff,webp,heic"  # Formats image courants
MODE="copy"              # Copier par défaut (pas déplacer)
FLAT=false               # Reproduire l'arborescence par défaut
DRY_RUN=false            # Exécution réelle par défaut
RECURSIVE=true           # Parcours récursif par défaut
VERBOSE=false            # Mode silencieux par défaut

# ============================================================================
#  SECTION 4 — PARSING DES ARGUMENTS
# ============================================================================
# On parcourt tous les arguments de la ligne de commande pour configurer
# le comportement du script avant de lancer le traitement.

INPUT_DIR=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --version)
      show_version
      exit 0
      ;;
    --orientation)
      ORIENTATION="$2"
      # Validation : seules 3 valeurs sont acceptées
      if [[ "$ORIENTATION" != "portrait" && "$ORIENTATION" != "landscape" && "$ORIENTATION" != "square" ]]; then
        error "Orientation invalide : '$ORIENTATION'"
        error "Valeurs acceptées : portrait, landscape, square"
        exit 1
      fi
      shift 2
      ;;
    --min-width)
      MIN_WIDTH="$2"
      shift 2
      ;;
    --max-width)
      MAX_WIDTH="$2"
      shift 2
      ;;
    --min-height)
      MIN_HEIGHT="$2"
      shift 2
      ;;
    --max-height)
      MAX_HEIGHT="$2"
      shift 2
      ;;
    --min-ratio)
      MIN_RATIO="$2"
      shift 2
      ;;
    --max-ratio)
      MAX_RATIO="$2"
      shift 2
      ;;
    --formats)
      FORMATS="$2"
      shift 2
      ;;
    --copy)
      MODE="copy"
      shift
      ;;
    --move)
      MODE="move"
      shift
      ;;
    --flat)
      FLAT=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --recursive)
      RECURSIVE=true
      shift
      ;;
    --no-recursive)
      RECURSIVE=false
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    -*)
      error "Option inconnue : '$1'"
      error "Utilise --help pour voir les options disponibles."
      exit 1
      ;;
    *)
      # Les arguments positionnels sont le dossier source et le dossier de destination
      if [[ -z "$INPUT_DIR" ]]; then
        INPUT_DIR="$1"
      elif [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$1"
      else
        error "Trop d'arguments positionnels."
        error "Usage : photo-filter-export.sh [OPTIONS] DOSSIER_SOURCE DOSSIER_DEST"
        exit 1
      fi
      shift
      ;;
  esac
done

# ============================================================================
#  SECTION 5 — VALIDATION DES ENTRÉES
# ============================================================================
# On vérifie que tout est en ordre avant de lancer le traitement.

# Vérifier que les deux dossiers sont renseignés
if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
  error "Dossier source et dossier de destination requis."
  echo ""
  echo "  Usage : ./photo-filter-export.sh [OPTIONS] DOSSIER_SOURCE DOSSIER_DEST"
  echo "  Aide  : ./photo-filter-export.sh --help"
  exit 1
fi

# Enlever les slashs finaux (cohérence des chemins relatifs)
INPUT_DIR="${INPUT_DIR%/}"
OUTPUT_DIR="${OUTPUT_DIR%/}"

# Vérifier que le dossier source existe
if [[ ! -d "$INPUT_DIR" ]]; then
  error "Le dossier source n'existe pas : '$INPUT_DIR'"
  exit 1
fi

# Vérifier qu'ImageMagick est installé et accessible
if ! command -v magick &>/dev/null; then
  error "ImageMagick (commande 'magick') introuvable dans le PATH."
  error "Installe-le avec : brew install imagemagick"
  exit 1
fi

# ============================================================================
#  SECTION 6 — CONSTRUCTION DE LA COMMANDE find
# ============================================================================
# On construit dynamiquement la liste des extensions à rechercher
# à partir de l'option --formats.

# Convertir la liste de formats en tableau
IFS=',' read -ra FMT_ARRAY <<< "$FORMATS"

# Construire les arguments -iname pour find
FIND_NAMES=()
for i in "${!FMT_ARRAY[@]}"; do
  ext="${FMT_ARRAY[$i]}"
  # Supprimer les espaces en début/fin du format
  ext="$(echo "$ext" | xargs)"
  if [[ $i -gt 0 ]]; then
    FIND_NAMES+=("-o")
  fi
  FIND_NAMES+=("-iname" "*.${ext}")
done

# Option de profondeur : -maxdepth 1 si pas récursif
DEPTH_ARGS=()
if [[ "$RECURSIVE" == false ]]; then
  DEPTH_ARGS=("-maxdepth" "1")
fi

# ============================================================================
#  SECTION 7 — AFFICHAGE DE LA CONFIGURATION
# ============================================================================
# Résumé visuel de la configuration avant de lancer le traitement.
# Permet à l'utilisateur de vérifier ses paramètres d'un coup d'œil.

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║          📸  Photo-Filter-Export v${VERSION}           ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
info "Source      : ${BOLD}${INPUT_DIR}${RESET}"
info "Destination : ${BOLD}${OUTPUT_DIR}${RESET}"
info "Mode        : ${BOLD}${MODE}${RESET}"
info "Récursif    : ${BOLD}${RECURSIVE}${RESET}"
info "Arborescence: ${BOLD}$(if $FLAT; then echo "flat (racine)"; else echo "miroir"; fi)${RESET}"
info "Formats     : ${BOLD}${FORMATS}${RESET}"

# Affichage conditionnel des filtres actifs
if [[ -n "$ORIENTATION" ]]; then
  info "Orientation : ${BOLD}${ORIENTATION}${RESET}"
fi
if [[ "$MIN_WIDTH" -gt 0 ]]; then
  info "Largeur min : ${BOLD}${MIN_WIDTH}px${RESET}"
fi
if [[ "$MAX_WIDTH" -lt 999999 ]]; then
  info "Largeur max : ${BOLD}${MAX_WIDTH}px${RESET}"
fi
if [[ "$MIN_HEIGHT" -gt 0 ]]; then
  info "Hauteur min : ${BOLD}${MIN_HEIGHT}px${RESET}"
fi
if [[ "$MAX_HEIGHT" -lt 999999 ]]; then
  info "Hauteur max : ${BOLD}${MAX_HEIGHT}px${RESET}"
fi
if [[ -n "$MIN_RATIO" ]]; then
  info "Ratio min   : ${BOLD}${MIN_RATIO}${RESET}"
fi
if [[ -n "$MAX_RATIO" ]]; then
  info "Ratio max   : ${BOLD}${MAX_RATIO}${RESET}"
fi

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  warn "${BOLD}MODE DRY-RUN : aucun fichier ne sera copié/déplacé.${RESET}"
fi

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────${RESET}"
echo ""

# ============================================================================
#  SECTION 8 — TRAITEMENT DES IMAGES
# ============================================================================
# Boucle principale : on parcourt chaque image trouvée par find,
# on lit ses dimensions avec ImageMagick, on applique les filtres,
# et on copie/déplace si l'image passe tous les critères.

# Compteurs pour le résumé final
total=0       # Nombre total de fichiers analysés
exported=0    # Nombre de fichiers exportés
skipped=0     # Nombre de fichiers ignorés (ne passent pas les filtres)
errors=0      # Nombre d'erreurs (fichiers illisibles, etc.)

# Créer le dossier de destination s'il n'existe pas
if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$OUTPUT_DIR"
fi

# Parcourir les fichiers image trouvés par find en utilisant Process Substitution
# pour éviter de créer un sous-shell (ce qui réinitialiserait les compteurs à 0).
while IFS= read -r -d '' filepath; do
  total=$((total + 1))

  # Extraire le nom de fichier pour l'affichage
  filename="$(basename "$filepath")"

  # ---- Lecture des dimensions avec ImageMagick ----
  # magick identify renvoie les dimensions en tenant compte de l'orientation EXIF
  # Format : "largeur hauteur"
  dims=$(magick identify -auto-orient -format "%w %h" "$filepath" 2>/dev/null) || {
    error "Impossible de lire : $filename"
    errors=$((errors + 1))
    continue
  }

  # Séparer largeur et hauteur
  w=$(echo "$dims" | awk '{print $1}')
  h=$(echo "$dims" | awk '{print $2}')

  # Vérification de sécurité : s'assurer que les dimensions sont valides
  if [[ -z "$w" || -z "$h" || "$w" -eq 0 || "$h" -eq 0 ]]; then
    error "Dimensions invalides pour : $filename"
    errors=$((errors + 1))
    continue
  fi

  # ---- FILTRE 1 : Orientation ----
  if [[ -n "$ORIENTATION" ]]; then
    case "$ORIENTATION" in
      portrait)
        # Portrait = hauteur strictement supérieure à la largeur
        if [[ "$h" -le "$w" ]]; then
          if [[ "$VERBOSE" == true ]]; then
            echo -e "  ${DIM}↳ Ignoré (pas portrait) : $filename [${w}x${h}]${RESET}"
          fi
          skipped=$((skipped + 1))
          continue
        fi
        ;;
      landscape)
        # Paysage = largeur strictement supérieure à la hauteur
        if [[ "$w" -le "$h" ]]; then
          if [[ "$VERBOSE" == true ]]; then
            echo -e "  ${DIM}↳ Ignoré (pas paysage) : $filename [${w}x${h}]${RESET}"
          fi
          skipped=$((skipped + 1))
          continue
        fi
        ;;
      square)
        # Carré = largeur exactement égale à la hauteur
        if [[ "$w" -ne "$h" ]]; then
          if [[ "$VERBOSE" == true ]]; then
            echo -e "  ${DIM}↳ Ignoré (pas carré) : $filename [${w}x${h}]${RESET}"
          fi
          skipped=$((skipped + 1))
          continue
        fi
        ;;
    esac
  fi

  # ---- FILTRE 2 : Dimensions minimales et maximales ----
  if [[ "$w" -lt "$MIN_WIDTH" || "$w" -gt "$MAX_WIDTH" ]]; then
    if [[ "$VERBOSE" == true ]]; then
      echo -e "  ${DIM}↳ Ignoré (largeur hors bornes) : $filename [${w}x${h}]${RESET}"
    fi
    skipped=$((skipped + 1))
    continue
  fi

  if [[ "$h" -lt "$MIN_HEIGHT" || "$h" -gt "$MAX_HEIGHT" ]]; then
    if [[ "$VERBOSE" == true ]]; then
      echo -e "  ${DIM}↳ Ignoré (hauteur hors bornes) : $filename [${w}x${h}]${RESET}"
    fi
    skipped=$((skipped + 1))
    continue
  fi

  # ---- FILTRE 3 : Ratio largeur/hauteur ----
  # On utilise awk pour les calculs en virgule flottante (pas de bc nécessaire)
  if [[ -n "$MIN_RATIO" ]]; then
    passes_min=$(awk "BEGIN { print ($w / $h >= $MIN_RATIO) ? 1 : 0 }")
    if [[ "$passes_min" -eq 0 ]]; then
      if [[ "$VERBOSE" == true ]]; then
        ratio_display=$(awk "BEGIN { printf \"%.2f\", $w / $h }")
        echo -e "  ${DIM}↳ Ignoré (ratio ${ratio_display} < ${MIN_RATIO}) : $filename${RESET}"
      fi
      skipped=$((skipped + 1))
      continue
    fi
  fi

  if [[ -n "$MAX_RATIO" ]]; then
    passes_max=$(awk "BEGIN { print ($w / $h <= $MAX_RATIO) ? 1 : 0 }")
    if [[ "$passes_max" -eq 0 ]]; then
      if [[ "$VERBOSE" == true ]]; then
        ratio_display=$(awk "BEGIN { printf \"%.2f\", $w / $h }")
        echo -e "  ${DIM}↳ Ignoré (ratio ${ratio_display} > ${MAX_RATIO}) : $filename${RESET}"
      fi
      skipped=$((skipped + 1))
      continue
    fi
  fi

  # ============================================================
  # L'image passe tous les filtres → on l'exporte
  # ============================================================

  # Calcul du chemin de sortie
  if [[ "$FLAT" == true ]]; then
    # Mode flat : tout à la racine du dossier de sortie
    outpath="$OUTPUT_DIR/$filename"

    # Gestion des doublons en mode flat (ajoute un suffixe numérique)
    if [[ -e "$outpath" ]]; then
      base="${filename%.*}"
      ext="${filename##*.}"
      counter=1
      while [[ -e "$OUTPUT_DIR/${base}_${counter}.${ext}" ]]; do
        counter=$((counter + 1))
      done
      outpath="$OUTPUT_DIR/${base}_${counter}.${ext}"
    fi
  else
    # Mode miroir : reproduire la structure des dossiers source
    rel="${filepath#"$INPUT_DIR"/}"
    outdir="$OUTPUT_DIR/$(dirname "$rel")"
    outpath="$outdir/$filename"

    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$outdir"
    fi
  fi

  # Affichage de la ligne de progression
  ratio_display=$(awk "BEGIN { printf \"%.2f\", $w / $h }")
  orientation_label=""
  if [[ "$h" -gt "$w" ]]; then
    orientation_label="portrait"
  elif [[ "$w" -gt "$h" ]]; then
    orientation_label="paysage"
  else
    orientation_label="carré"
  fi

  echo -e "  ${GREEN}✔${RESET} ${BOLD}[$total]${RESET} $filename  ${DIM}${w}×${h}  ratio:${ratio_display}  ${orientation_label}${RESET}"

  # Copie ou déplacement effectif
  if [[ "$DRY_RUN" == false ]]; then
    if [[ "$MODE" == "copy" ]]; then
      cp "$filepath" "$outpath"
    else
      mv "$filepath" "$outpath"
    fi
  fi

  exported=$((exported + 1))
done < <(find "$INPUT_DIR" "${DEPTH_ARGS[@]}" -type f \( "${FIND_NAMES[@]}" \) -print0)

# ============================================================================
#  SECTION 9 — RÉSUMÉ FINAL
# ============================================================================
# Affichage d'un bilan clair et visuel en fin de traitement.

echo ""
echo -e "${DIM}──────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "${BOLD}📊 Résumé${RESET}"
echo ""
success "Fichiers analysés : ${BOLD}${total}${RESET}"
success "Fichiers exportés : ${BOLD}${exported}${RESET}"

if [[ "$skipped" -gt 0 ]]; then
  warn "Fichiers ignorés  : ${BOLD}${skipped}${RESET}"
fi

if [[ "$errors" -gt 0 ]]; then
  error "Erreurs           : ${BOLD}${errors}${RESET}"
fi

echo ""

if [[ "$DRY_RUN" == true ]]; then
  warn "C'était un dry-run. Relance sans --dry-run pour exécuter."
else
  if [[ "$MODE" == "copy" ]]; then
    success "Photos copiées vers : ${BOLD}${OUTPUT_DIR}${RESET}"
  else
    success "Photos déplacées vers : ${BOLD}${OUTPUT_DIR}${RESET}"
  fi
fi

echo ""