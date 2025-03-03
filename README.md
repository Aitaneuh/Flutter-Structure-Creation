# Script PowerShell pour compléter la structure Flutter

Ce script PowerShell permet de générer automatiquement la structure d'un projet Flutter en ajoutant les répertoires suivants :
- `component_library`
- `screen`
- `provider`
- `repository`

### Prérequis

- **PowerShell** : Ce script est écrit en PowerShell et nécessite PowerShell version 5.1 ou supérieure.
- **Flutter** : Assurez-vous d'avoir Flutter installé et configuré sur votre machine.
  
### Description

Ce script crée la structure de répertoires de base pour un projet Flutter en se basant sur des entités (par exemple, les écrans ou composants) définis par l'utilisateur. Il est conçu pour faciliter l'organisation de votre code dans un modèle MVVM, avec des répertoires dédiés aux composants réutilisables, aux écrans, aux providers et aux repositories.

### Fonctionnalités

- Crée la structure de dossier suivante :
    - `lib/component_library/`
    - `lib/domain_entities/`
    - `lib/features/`
    - `lib/repositories/`
- Demande à l'utilisateur le chemin où placer la structure (par défaut dans le répertoire `lib/`).
- Permet de définir un thème pour la structure générée.
- Permet de spécifier le nom des entités à inclure (ex. : `MyScreen`, `MyProvider`, etc.).

### Installation

1. Téléchargez le fichier `flutter_create_structure.ps1`.
2. Ouvrez PowerShell et naviguez jusqu'au dossier où vous avez téléchargé le script.
3. Exécutez le script en tapant la commande suivante :
   ```powershell
   .\flutter_create_structure.ps1
