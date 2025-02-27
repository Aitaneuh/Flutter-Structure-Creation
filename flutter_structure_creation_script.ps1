#récupérer l'environnement de flutter (sdk)

# Sélection du chemin
$path = Read-Host "Entrez le chemin de votre projet Flutter"
Set-Location $path

# Sélection du nom du projet
$name = Read-Host "Entrez le nom de votre projet Flutter"

# Sélection du thème principal
$theme = Read-Host "Entrez le thème principal de votre projet Flutter"

# Sélection des entités du projet
$entities = @()

do {
    $entity = Read-Host "Entrez une entité (appuyez sur 'Entrée' pour terminer)"
    if ($entity -ne "") {
        $entities += $entity
    }
} while ($entity -ne "")

# Création du dossier package
mkdir packages
Set-Location packages

# Création du dossier domain_entities
mkdir domain_entities
Set-Location domain_entities

# Création des fichiers analysis_options.yaml, pubspec.yaml
New-Item -Name analysis_options.yaml -ItemType file
@("include: package:flutter_lints/flutter.yaml", "", "linter:", "  rules:") | Add-Content -Path $path\packages\domain_entities\analysis_options.yaml

New-Item -Name pubspec.yaml -ItemType file

@("name: domain_entities", "publish_to: none", "", "environment:", "  sdk: ^3.5.1", "", "dev_dependencies:","  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\domain_entities\pubspec.yaml

# Ajout de la dépendance equatable
flutter pub add equatable

# Création des dossier lib/src et du barrel
mkdir lib
Set-Location lib

New-Item -Name domain_entities.dart -ItemType file

mkdir src
Set-Location src

# Création des entités - problèmes ici
foreach ($entity in $entities) {
    mkdir $entity
    Set-Location $entity

    New-Item -Name $entity.dart -ItemType file

    @("class $entity {", "  const $entity({", " })", "}") | Add-Content -Path $path\packages\domain_entities\lib\src\$entity\$entity.dart

    Set-Location ..
}