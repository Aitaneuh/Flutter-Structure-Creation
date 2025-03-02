#récupérer l'environnement de flutter (sdk)

# Sélection du chemin
# $path = Read-Host "Entrez le chemin de votre projet Flutter"
$path = "C:/Test/test"
Set-Location $path


# Sélection du nom du projet
# $name = Read-Host "Entrez le nom de votre projet Flutter"

# Sélection du thème principal
# $theme = Read-Host "Entrez le thème principal de votre projet Flutter"
$theme = 'voitures';

# Sélection des entités du projet
# $entities = @()

# do {
#     $entity = Read-Host "Entrez une entité (appuyez sur 'Entrée' pour terminer)"
#     if ($entity -ne "") {
#         $entities += $entity
#     }
# } while ($entity -ne "")

$entities = @('modele', 'marque');

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

    New-Item -Name "$entity.dart" -ItemType file

    @("class $entity extands Equatable {", "  const $entity({", " })", "@override", "List<Object?> get props => [];", "}") | Add-Content -Path $path\packages\domain_entities\lib\src\$entity\$entity.dart

    Set-Location ..

    @("export 'src/$entity/$entity.dart';") | Add-Content -Path $path\packages\domain_entities\lib\domain_entities.dart
}

# Création du dossier repository
$nameRepo = $theme + "_repository";
Set-Location $path\packages;
mkdir $nameRepo;
Set-Location $nameRepo;

# Ajout du fichier analysis_options.yaml et pubspec.yaml
New-Item -Name analysis_options.yaml -ItemType file
@("include: package:flutter_lints/flutter.yaml", "", "linter:", "  rules:") | Add-Content -Path $path\packages\$nameRepo\analysis_options.yaml

New-Item -Name pubspec.yaml -ItemType file
@("name: $nameRepo", "publish_to: none", "", "environment:", "  sdk: ^3.5.1", "", "dependencies:", "  domain_entities:", "    path: ../domain_entities", "dev_dependencies:","  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\$nameRepo\pubspec.yaml

# Ajout des dossiers lib/src et du barrel
mkdir lib
Set-Location lib

@("export 'src/mappers.dart", "export 'src/models.dart", "export 'src/services.dart") | Add-Content -Path $path\packages\$nameRepo\lib\$nameRepo.dart

mkdir src
Set-Location src

New-Item -Name $theme"_repository.dart" -ItemType file

# Ajout du dossier et des fichiers mappers
New-Item -Name mappers -ItemType Directory
Set-Location mappers
New-Item -Name "mappers.dart" -ItemType file
Set-Location ..

# Ajout du dossier et des fichiers models
New-Item -Name models -ItemType Directory
Set-Location models
New-Item -Name "models.dart" -ItemType file
Set-Location .. 

# Ajout du dossier et des fichiers services
New-Item -Name services -ItemType Directory
Set-Location services
New-Item -Name "services.dart" -ItemType file
Set-Location ..

# Création du dossier component_library
set-location $path\packages
mkdir component_library
Set-Location component_library

# Ajout du fichier analysis_options.yaml et pubspec.yaml
@("include: package:flutter_lints/flutter.yaml", "", "linter:", "  rules:") | Add-Content -Path $path\packages\component_library\analysis_options.yaml

@("name: component_library", "publish_to: none", "", "environment:", "  sdk: ^3.5.1", "", "dependencies:", "  flutter:", "    sdk: flutter", "  domain_entities:", "    path: ../domain_entities", "dev_dependencies:", "  flutter_lints: ^4.0.0", "flutter:", "  uses-material-design: true") | Add-Content -Path $path\packages\component_library\pubspec.yaml

# Ajout du dossier lib et du fichier component_library.dart
mkdir lib
Set-Location lib

New-Item -Name component_library.dart -ItemType file

mkdir src

