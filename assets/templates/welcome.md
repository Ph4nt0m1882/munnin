# Bienvenue dans Munnin ! 🐦‍⬛

Votre nouvelle base de connaissances est prête. Munnin n'est pas un simple lecteur Markdown, c'est un environnement **interactif**.

Voici un aperçu de vos pouvoirs actuels :

## 0. Syntaxe de base

La syntaxe html en général est compatible avec la syntaxe markdown

### Titres :
Les titres en markdowns sont hierarchiques de 1 à 6 et représenter avec des "#" en début de lignes 
⚠️ il est important de mettre un espace avant le '#'

````markdown
# Titre 1
## Titre 2
### Titre 3
#### Titre 4
##### Titre 5
###### Titre 6
````

<details> <summary> petits plus </summary>

c'est aussi possible de créer des titres de niveau 1 et 2 en les soulignant avec des "=" ou des "-"

````markdown
Titre 1
=======

Titre 2
-------
````

</details>

### Délimitation :
En markdown, il est possible d'ajouter une ligne de séparation horizontale en utilisant trois tirets, astérisques ou underscores sur une ligne vide.

````markdown
---
***
___
````

### Mise en forme du texte :
Vous pouvez facilement mettre en valeur votre texte avec des symboles simples.

````markdown
**Texte en gras** ou __Texte en gras__
*Texte en italique* ou _Texte en italique_
~~Texte barré~~
````

<details> <summary> petits plus </summary>

Il est tout à fait possible de combiner ces mises en forme pour des cas plus spécifiques !

````markdown
***Gras et italique***
~~**Gras et barré**~~
````

</details>

### Listes :
Organisez vos idées avec des listes à puces ou numérotées.

````markdown
Listes à puces :
- Élément 1
* Élément 2
+ Élément 3

Listes numérotées :
1. Premier
2. Deuxième
3. Troisième
````

<details> <summary> petits plus </summary>

Vous pouvez imbriquer des listes en ajoutant simplement des espaces (généralement 2 ou 4 espaces) au début de la ligne, et même mélanger les types de listes !

````markdown
1. Étape 1
   - Détail A
   - Détail B
2. Étape 2
   1. Sous-étape 2.1
   2. Sous-étape 2.2
````

</details>

### Blocs de citation :
Idéal pour mettre en avant une citation ou une remarque.

````markdown
> C'est une citation
> Elle peut s'étendre sur plusieurs lignes.
````

<details> <summary> petits plus </summary>

Les citations peuvent aussi être imbriquées les unes dans les autres !

````markdown
> Citation principale
>> Sous-citation pour répondre à un point spécifique
````

</details>

### Liens :
Créez des liens hypertextes facilement.

````markdown
[Texte du lien](https://www.exemple.com)
````

<details> <summary> petits plus </summary>

Vous pouvez ajouter un texte de survol (titre) qui s'affichera au passage de la souris !

````markdown
[Texte du lien](https://www.exemple.com "Titre au survol")
````

</details>

## 1. Gestion Avancée des Tâches
Contrairement au Markdown classique, Munnin propose 4 états pour vos listes de tâches, modifiables **directement depuis la vue Rendu** à la souris :

- [ ] **Tâche vide** : *Essayez de faire un clic gauche ici !*
- [*] **Tâche en cours / faite** : *(Obtenu via un clic gauche)*
- [v] **Tâche validée** : *(Obtenu via un **double-clic**)*
- [x] **Tâche annulée** : *(Obtenu via un **clic droit**)*

> [!NOTE]
> Munnin utilise un système de **sauvegarde partielle intelligente** : quand vous cliquez sur une case en mode rendu, le fichier source sur votre disque dur est mis à jour *silencieusement* !

## 2. Tableaux Natifs
Les tableaux épousent automatiquement la largeur de l'écran avec une alternance de couleurs élégante.

| Fonctionnalité | Raccourci / Action | Statut |
| :--- | :--- | :--- |
| **Checkboxes interactives** | Clics souris | [v] |
| **Images locales** | Chemins relatifs | [v] |
| **Blocs de code interactifs** | Clic droit (copier), Clic gauche (sélection) | [v] |

## 3. Admonitions (Blocs d'alerte)
Munnin supporte nativement les admonitions classiques style GitHub, mais va beaucoup plus loin avec des admonitions personnalisables !

**Classique :**
> [!NOTE]
> Ceci est une note standard, avec une continuité visuelle parfaite.

**Personnalisable :**
Vous pouvez choisir l'icône, le titre et la couleur de la bordure (`blue`, `red`, `green`, `purple`, `orange`...) :
> [!{lucide-play}{Nouveau bloc}{purple}]
> Un bloc personnalisé avec une icône et une bordure violette !

## 4. Sélecteur d'Icônes (Icon Picker)
Pour vous aider à personnaliser vos documents, Munnin intègre un sélecteur de milliers d'icônes (Lucide et Simple Icons) et de symboles spéciaux (©, ™, ♥).
- Cliquez sur l'icône **😃** dans la barre d'outils rétractable au-dessus de l'éditeur ou utilisez `Ctrl + Maj + I`.
- Double-cliquez sur une icône pour insérer son identifiant directement, ou utilisez un simple clic pour la copier dans votre presse-papier !

## 5. Images Locales Résolues
Fini les maux de tête avec les images locales ! Munnin résout les chemins relatifs automatiquement depuis l'emplacement du fichier en cours de lecture.
![Exemple Image Inexistante](images/test.png)
*(Un joli encart d'erreur vous avertit si l'image n'est pas trouvée, sans casser la page)*

## 6. Balises Personnalisées
Munnin intercepte des syntaxes Markdown uniques, comme le double-point d'exclamation :
!![Fichier Spécial](mon_fichier.pdf)

{{ ... }}

---
*Explorez, éditez et façonnez votre wiki comme vous le souhaitez !*

## 7. Liens Wiki et Notes de bas de page
Vous pouvez lier vos documents entre eux très facilement en utilisant la syntaxe WikiLink avec de simples doubles crochets :

- **Lien simple :** `[[Mon super lien]]`
- **Lien avec Alias (Texte personnalisé) :** `[[Pomme|Une belle pomme]]`
- **Lien vers un titre spécifique :** `[[Pomme(pommes vertes)]]`
- **Lien vers un titre avec Alias :** `[[Pomme(pommes vertes)|Des pommes vertes]]`

Essayez de cliquer sur ces liens en mode rendu : [[Pomme(pommes vertes)|Des pommes vertes]]

Vous pouvez également ajouter des notes de bas de page de cette manière : [^1]

[^1]: Et voici la définition de la note de bas de page !
