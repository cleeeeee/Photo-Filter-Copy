# Guide d'utilisation — Photo-Filter-Export

Ce guide détaille toutes les fonctionnalités du script `photo-filter-export.sh`.

## Table des matières

1. [Principe de fonctionnement](#principe-de-fonctionnement)
2. [Filtrage par orientation](#filtrage-par-orientation)
3. [Filtrage par dimensions](#filtrage-par-dimensions)
4. [Filtrage par ratio](#filtrage-par-ratio)
5. [Choix des formats](#choix-des-formats)
6. [Modes de copie](#modes-de-copie)
7. [Arborescence de sortie](#arborescence-de-sortie)
8. [Mode dry-run](#mode-dry-run)
9. [Combiner les filtres](#combiner-les-filtres)
10. [FAQ](#faq)

---

## Principe de fonctionnement

Le script parcourt un dossier source, analyse chaque image avec ImageMagick (`magick identify`), et applique les filtres que tu as définis. Seules les images qui passent **tous** les filtres sont exportées.

```
DOSSIER_SOURCE  →  [Analyse + Filtres]  →  DOSSIER_DESTINATION
```

L'orientation EXIF est prise en compte : une photo prise en portrait sur un appareil est bien détectée comme portrait, même si le fichier brut a des métadonnées d'orientation.

---

## Filtrage par orientation

### Portrait (vertical)

Photos où la **hauteur est supérieure à la largeur**. Idéal pour préparer du contenu reels, stories, TikTok.

```bash
./photo-filter-export.sh --orientation portrait ./source ./destination
```

### Paysage (horizontal)

Photos où la **largeur est supérieure à la hauteur**. Pour des posts classiques, bannières, fonds d'écran.

```bash
./photo-filter-export.sh --orientation landscape ./source ./destination
```

### Carré

Photos où **largeur = hauteur**. Pour des posts Instagram carrés, favicons, vignettes.

```bash
./photo-filter-export.sh --orientation square ./source ./destination
```

---

## Filtrage par dimensions

Tu peux filtrer par largeur et/ou hauteur minimale et maximale.

### Exemples

Uniquement les photos de plus de 2000px de large :
```bash
./photo-filter-export.sh --min-width 2000 ./source ./destination
```

Photos entre 1000 et 3000px de haut :
```bash
./photo-filter-export.sh --min-height 1000 --max-height 3000 ./source ./destination
```

Les filtres de dimensions se combinent avec l'orientation :
```bash
# Portraits de plus de 3000px de haut
./photo-filter-export.sh --orientation portrait --min-height 3000 ./source ./destination
```

---

## Filtrage par ratio

Le ratio est calculé comme **largeur / hauteur** :
- `ratio < 1.0` → image verticale
- `ratio = 1.0` → image carrée
- `ratio > 1.0` → image horizontale

### Exemples

Photos très verticales (ratio < 0.7, style reel/short) :
```bash
./photo-filter-export.sh --max-ratio 0.7 ./source ./destination
```

Photos quasi-carrées (ratio entre 0.9 et 1.1) :
```bash
./photo-filter-export.sh --min-ratio 0.9 --max-ratio 1.1 ./source ./destination
```

Photos panoramiques (ratio > 2.0) :
```bash
./photo-filter-export.sh --min-ratio 2.0 ./source ./destination
```

---

## Choix des formats

Par défaut, le script traite : **jpg, jpeg, png, tif, tiff, webp, heic**.

Tu peux restreindre à certains formats :

```bash
# Uniquement les JPG
./photo-filter-export.sh --formats jpg,jpeg ./source ./destination

# RAW + TIFF
./photo-filter-export.sh --formats tif,tiff ./source ./destination

# WebP uniquement
./photo-filter-export.sh --formats webp ./source ./destination
```

---

## Modes de copie

### Copie (par défaut)

Les originaux restent en place. Les fichiers sont **copiés** vers la destination.

```bash
./photo-filter-export.sh --copy ./source ./destination
```

### Déplacement

Les fichiers sont **déplacés** : ils disparaissent du dossier source.

```bash
./photo-filter-export.sh --move ./source ./destination
```

> ⚠️ **Attention** : en mode `--move`, les originaux sont supprimés du dossier source. Utilise `--dry-run` d'abord pour vérifier.

---

## Arborescence de sortie

### Mode miroir (par défaut)

La structure des dossiers source est reproduite dans la destination :

```
source/
  ├── mariage/
  │   ├── photo1.jpg  ← portrait ✔
  │   └── photo2.jpg  ← paysage ✖
  └── corporate/
      ├── photo3.jpg  ← portrait ✔
      └── photo4.jpg  ← portrait ✔

destination/
  ├── mariage/
  │   └── photo1.jpg
  └── corporate/
      ├── photo3.jpg
      └── photo4.jpg
```

### Mode flat

Toutes les photos exportées sont mises à la racine, sans sous-dossiers :

```bash
./photo-filter-export.sh --orientation portrait --flat ./source ./destination
```

```
destination/
  ├── photo1.jpg
  ├── photo3.jpg
  └── photo4.jpg
```

> En cas de doublons de noms, un suffixe numérique est ajouté automatiquement (`photo1_1.jpg`, `photo1_2.jpg`…).

---

## Mode dry-run

Le dry-run simule l'opération **sans toucher à aucun fichier**. C'est la première chose à faire quand tu configures de nouveaux filtres.

```bash
./photo-filter-export.sh --orientation portrait --dry-run --verbose ./source ./destination
```

Le script affiche exactement ce qu'il ferait, avec les compteurs de fichiers analysés, exportés et ignorés.

---

## Combiner les filtres

Tous les filtres se combinent. Seules les images qui passent **tous** les filtres sont exportées.

### Exemple complet

```bash
# Exporter les portraits verticaux en JPEG,
# d'au moins 2000px de haut,
# avec un ratio < 0.8 (bien vertical),
# en mode flat, sans les sous-dossiers
./photo-filter-export.sh \
  --orientation portrait \
  --formats jpg,jpeg \
  --min-height 2000 \
  --max-ratio 0.8 \
  --flat \
  ./retouches \
  ./reels-content
```

---

## FAQ

### Le script modifie-t-il mes photos ?

**Non.** Le script ne touche pas au contenu des images. Il les copie (ou déplace) telles quelles. Aucune modification, aucun redimensionnement, aucune compression.

### Il gère les accents et espaces dans les noms de fichiers ?

**Oui.** Le script utilise `find -print0` et `read -d ''` pour gérer correctement les noms avec espaces, accents et caractères spéciaux.

### Comment gérer les fichiers RAW (.CR2, .ARW, .NEF…) ?

ImageMagick peut lire certains formats RAW, mais ça dépend de ton installation. Tu peux tester en ajoutant l'extension à `--formats` :

```bash
./photo-filter-export.sh --formats cr2,arw,nef --orientation portrait ./raw ./dest
```

Si ça ne fonctionne pas, installe le délégué RAW pour ImageMagick (ex : `ufraw-batch` ou `darktable-cli`).

### Quelle est la différence avec un simple `find + cp` ?

Le script lit les **vraies dimensions de l'image** avec ImageMagick, pas juste les métadonnées du fichier. Il gère l'orientation EXIF, les ratios calculés, la gestion des doublons en mode flat, et offre un résumé visuel complet.
