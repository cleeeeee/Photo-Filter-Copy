# Photo-Filter-Export

![Badge Licence](https://img.shields.io/badge/license-MIT-blue)
![Badge Maintenance](https://img.shields.io/badge/maintained-yes-brightgreen)
![Badge Shell](https://img.shields.io/badge/language-bash-green)

Un script Bash pour **filtrer et exporter des photos** selon des critères précis : orientation, dimensions, ratio, format de fichier. Idéal pour préparer du contenu en masse (reels, stories, posts, impressions…) sans tri manuel.

Ce projet est maintenu par **Lechevlu** (Cle).

## Pourquoi ce script ?

En tant que photographe, tu travailles souvent avec des centaines (voire des milliers) de clichés de tailles et orientations variées. Quand tu dois préparer du contenu pour les réseaux :

- **Reels / Shorts** → il te faut les **verticales**
- **Posts classiques** → tu veux les **paysages** ou les **carrées**
- **Impression grand format** → tu filtres par **résolution minimale**

Ce script fait le tri à ta place en une seule commande.

## Fonctionnalités

- **Filtrage par orientation** : portrait, paysage ou carré
- **Filtrage par dimensions** : largeur/hauteur min et max en pixels
- **Filtrage par ratio** : ratio largeur/hauteur personnalisé (ex : `< 0.7` pour du très vertical)
- **Filtrage par format** : JPG, PNG, TIFF, WebP, HEIC… ou tout combo personnalisé
- **Copie ou déplacement** : tes originaux restent intacts par défaut
- **Miroir d'arborescence** : reproduit la structure de tes dossiers source
- **Mode flat** : tout exporter à la racine d'un seul dossier
- **Dry-run** : simule l'opération pour vérifier avant d'exécuter
- **Traitement récursif** : parcourt tous les sous-dossiers automatiquement
- **Prise en charge EXIF** : l'orientation EXIF est respectée pour le calcul des dimensions

## Prérequis

Ce script fonctionne sur les systèmes Unix (macOS, Linux).

- **Bash** (v3.2+)
- **ImageMagick** (v7+)

### Vérification

```bash
magick -version
```

Si la commande n'est pas trouvée, installe ImageMagick :

```bash
# macOS (Homebrew)
brew install imagemagick

# Linux (apt)
sudo apt install imagemagick
```

## Installation

1. Clone ce dépôt :
   ```bash
   git clone https://github.com/cleeeeee/Photo-Filter-Export.git
   cd Photo-Filter-Export
   ```

2. Rends le script exécutable :
   ```bash
   chmod +x photo-filter-export.sh
   ```

## Utilisation Rapide

Le script prend deux arguments obligatoires : le dossier source et le dossier de destination, plus des options de filtrage.

```bash
./photo-filter-export.sh [OPTIONS] DOSSIER_SOURCE DOSSIER_DESTINATION
```

Pour plus de détails, consulte le [Guide d'utilisation](utilisation.md).

## Aperçu

![Script Preview](Assets/code.png)

### Cas d'usage concrets

#### 📱 Préparer des reels (verticales uniquement)

```bash
./photo-filter-export.sh --orientation portrait ./retouches ./reels-prep
```

#### 🖼️ Exporter les paysages haute résolution

```bash
./photo-filter-export.sh --orientation landscape --min-width 3000 ./raw ./export-hd
```

#### ⬜ Récupérer les photos carrées en JPEG

```bash
./photo-filter-export.sh --orientation square --formats jpg,jpeg ./src ./carrées
```

#### 📐 Filtrer par ratio (très vertical pour reels)

```bash
./photo-filter-export.sh --max-ratio 0.7 ./retouches ./ultra-vertical
```

#### 🧪 Simuler avant d'exécuter (dry-run)

```bash
./photo-filter-export.sh --orientation portrait --dry-run ./retouches ./test
```

#### 📦 Tout en flat (pas de sous-dossiers)

```bash
./photo-filter-export.sh --orientation portrait --flat ./retouches ./reels-flat
```

## Options complètes

| Option | Description | Exemple |
|---|---|---|
| `--orientation` | portrait, landscape, square | `--orientation portrait` |
| `--min-width` | Largeur minimale (px) | `--min-width 2000` |
| `--max-width` | Largeur maximale (px) | `--max-width 5000` |
| `--min-height` | Hauteur minimale (px) | `--min-height 3000` |
| `--max-height` | Hauteur maximale (px) | `--max-height 6000` |
| `--min-ratio` | Ratio L/H minimum | `--min-ratio 0.5` |
| `--max-ratio` | Ratio L/H maximum | `--max-ratio 1.0` |
| `--formats` | Formats à inclure | `--formats jpg,png,heic` |
| `--copy` | Copier les fichiers (défaut) | |
| `--move` | Déplacer les fichiers | |
| `--flat` | Pas de sous-dossiers en sortie | |
| `--dry-run` | Simulation sans action | |
| `--recursive` | Parcours récursif (défaut) | |
| `--no-recursive` | Premier niveau seulement | |
| `--verbose` | Afficher les fichiers ignorés | |
| `--help` | Afficher l'aide | |
| `--version` | Afficher la version | |

## Voir aussi

- [Border-Galery-Maker](https://github.com/cleeeeee/Border-Galery-Maker) — Script d'ajout de bordures galerie pour Instagram (même auteur)

## Contribution

Les contributions sont les bienvenues. Pour des changements majeurs, veuillez ouvrir d'abord une issue pour discuter de ce que vous souhaitez modifier.

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## Contact

**Lechevlu** - [https://lechevlu.fr](https://lechevlu.fr/)  
✉️ contact@lechevlu.fr
