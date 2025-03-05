function Set-UpperCamelCase {
    param([string]$inputString)
    return ($inputString -split '\s+|_|-' | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() }) -join ''
}

# Demande du nom du projet
$projectName = Read-Host "Entrez le nom de votre projet Flutter"
$projectPath = Read-Host "Entrez le chemin du projet Flutter"

Write-Host "Création du projet Flutter : $projectName"
Set-Location $projectPath
$platforms = "android,web"
flutter create --platforms=$platforms $projectName
Write-Host "Le projet $projectName a été créé avec succès."


# Path mis sur le dossier actuel
$path = "$projectPath\$projectName"


# Sélection du thème principal
$theme = Read-Host "Entrez le thème principal de votre projet Flutter"
$themeMaju = $theme.Substring(0, 1).ToUpper() + $theme.Substring(1).ToLower()

# Sélection des entités du projet
$entities = @()

$entitiesIndex = 0

do {
    $entity = Read-Host "Entrez une entité (appuyez sur 'Entrée' pour terminer)"
    if ($entity -ne "") {
        $entities += @{ Name = $entity; Properties = @() }
        do {
            $property = Read-Host "Entrez une propriété pour $entity (appuyez sur 'Entrée' pour terminer)"
            if ($property -ne "") {
                $entities[$entitiesIndex].Properties += $property
            }
        } while ($property -ne "")
        $entitiesIndex++
    }
} while ($entity -ne "")

Write-Output $entities

Set-Location $path

# Création du dossier packages
mkdir packages
Set-Location packages

# Création du dossier domain_entities
mkdir domain_entities
Set-Location domain_entities

flutter pub add equatable

# Création des fichiers analysis_options.yaml, pubspec.yaml
New-Item -Name analysis_options.yaml -ItemType file
@("include: package:flutter_lints/flutter.yaml", "", "linter:", "  rules:") | Add-Content -Path $path\packages\domain_entities\analysis_options.yaml

New-Item -Name pubspec.yaml -ItemType file

@("name: domain_entities", "publish_to: none", "", "environment:", "  sdk: ^3.5.1", "", "dependencies:", "  equatable: ^2.0.7", "", "dev_dependencies:", "  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\domain_entities\pubspec.yaml

foreach ($entity in $entities) {
    $entityName = $entity.Name  # Récupération du nom de l'entité
    $entityPath = "$path\packages\domain_entities\lib\src\$entityName"

    $className = Set-UpperCamelCase $entityName

    mkdir $entityPath -Force  # -Force pour éviter les erreurs si le dossier existe déjà

    $filePath = "$entityPath\$entityName.dart"
    New-Item -Path $filePath -ItemType File -Force

    @("import 'package:equatable/equatable.dart';", "", "class $className extends Equatable {", "  const $className({") | Set-Content -Path $filePath

    foreach ($property in $entity.Properties) {
        @("    required this.$property,") | Add-Content -Path $filePath
    }

    @("  });", "") | Add-Content -Path $filePath

    foreach ($property in $entity.Properties) {
        @("  final String $property;") | Add-Content -Path $filePath  # Ici, j'ai mis String par défaut
    }

    @("", "  @override", "  List<Object?> get props => [") | Add-Content -Path $filePath

    $dataLine = ($entity.Properties -join ", ")  # Construit la liste des propriétés en une ligne
    @("    $dataLine,", "  ];", "}") | Add-Content -Path $filePath

    # Mise à jour du barrel file
    @("export 'src/$entityName/$entityName.dart';") | Add-Content -Path "$path\packages\domain_entities\lib\domain_entities.dart"
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
@("name: $nameRepo", "publish_to: none", "", "environment:", "  sdk: ^3.5.1", "", "dependencies:", "  domain_entities:", "    path: ../domain_entities", "dev_dependencies:", "  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\$nameRepo\pubspec.yaml

# Ajout des dossiers lib/src et du barrel
mkdir lib
Set-Location lib

@("export 'src/mappers/mappers.dart';", "export 'src/models/models.dart';", "export 'src/services/services.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\$nameRepo.dart

mkdir src
Set-Location src

New-Item -Name $theme"_repository.dart" -ItemType file

# Ajout du dossier et des fichiers models
New-Item -Name models -ItemType Directory
Set-Location models
New-Item -Name "models.dart" -ItemType file

# Fichiers model local
foreach ($entity in $entities) {
    $entityName = $entity.Name
    New-Item -Name "${entityName}_local_file_model.dart" -ItemType file
    @("export '${entityName}_local_file_model.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\models.dart
    @("class ${entityName}LocalFileModel {", "  const ${entityName}LocalFileModel(") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart

    foreach ($property in $entity.Properties) {
        $thisProperty = "       this.${property},"
        @($thisProperty) | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart
    }
    @("  );", "") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart
    

    @(" factory ${entityName}LocalFileModel.fromJson(Map<String, dynamic> json) {", "    return ${entityName}LocalFileModel(") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart

    foreach ($property in $entity.Properties) {
        $thisProperty = "   ${property}: json['${property}'],"
        @($thisProperty) | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart
    }

    @("    );", "  }", "") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart

    foreach ($property in $entity.Properties) {
        $thisProperty = "   final String ${property};"
        @($thisProperty) | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart
    }

    @("}") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart
}

Set-Location ..

# Ajout du dossier et des fichiers mappers
New-Item -Name mappers -ItemType Directory
Set-Location mappers
New-Item -Name "mappers.dart" -ItemType file

foreach ($entity in $entities) {
    $entityName = $entity.Name
    New-Item -Name "${entityName}_local_file_model_to_domain.dart" -ItemType file
    @("export '${entityName}_local_file_model_to_domain.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\mappers.dart

    @("import 'package:domain_entities/domain_entities.dart';", "import 'package:$nameRepo/$nameRepo.dart';", "extension ${entityName}LocalFileModelToDomain on ${entityName}LocalFileModel {", "  ${entityName} toDomainEntity() {", "    return ${entityName}(") | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\${entityName}_local_file_model_to_domain.dart

    foreach ($property in $entity.Properties) {
        $thisProperty = "       ${property}: ${property},"
        @($thisProperty) | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\${entityName}_local_file_model_to_domain.dart
    }
    @("    );", "  }", "}") | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\${entityName}_local_file_model_to_domain.dart
}

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

@("name: component_library", "publish_to: none", "", "environment:", "  sdk: ^3.5.1", "", "dependencies:", "  flutter:", "    sdk: flutter", "  domain_entities:", "    path: ../domain_entities", "dev_dependencies:", "  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\component_library\pubspec.yaml

# Création du projet Example
flutter create --platforms=web example
Set-Location example
flutter pub add storybook_flutter
Set-Location ..

# Ajout du dossier lib et du fichier component_library.dart
mkdir lib
Set-Location lib

New-Item -Name component_library.dart -ItemType file

mkdir src

# Ajout de la variable du nom de la "list"
$nameList = $theme + "_list";

# Création du dossier features et du sous-dossier list
Set-Location $path\packages
mkdir features
Set-Location features

mkdir $nameList
Set-Location $nameList

# Ajout du fichier analysis_options.yaml et pubspec.yaml
New-Item -Name analysis_options.yaml -ItemType file
@("include: package:flutter_lints/flutter.yaml", "", "linter:", "  rules:") | Add-Content -Path $path\packages\features\$nameList\analysis_options.yaml

New-Item -Name pubspec.yaml -ItemType file
@("name: $nameList", "publish_to: none", "", "environment:", "  sdk: ^3.5.1", "", "dependencies:", "  flutter:", "    sdk: flutter", "", "  component_library:", "    path: ../../component_library", "  domain_entities:", "    path: ../../domain_entities", "  ${nameRepo}:", "    path: ../../${nameRepo}", "dev_dependencies:", "  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\features\$nameList\pubspec.yaml

flutter pub add uuid

# Installation de la dépendance provider
flutter pub add provider

# Création des dossiers lib/src et du barrel
mkdir lib
Set-Location lib

New-Item -Name $nameList".dart" -ItemType file
@("library;", "", "export 'src/providers/providers.dart';", "export 'src/screens/screens.dart';", "", "export 'package:provider/provider.dart';") | Add-Content -Path $path\packages\features\$nameList\lib\$nameList".dart"

mkdir src
Set-Location src

# Ajout des dossier providers et de ses fichiers
mkdir providers
Set-Location providers

New-Item -Name "${theme}_provider.dart" -ItemType file
@("import 'package:domain_entities/domain_entities.dart';", "import 'package:flutter/material.dart';", "import 'package:${nameRepo}/${nameRepo}.dart';", "import 'package:uuid/uuid.dart';", "", "class ${themeMaju}Provider with ChangeNotifier {", "  ${themeMaju}Provider({required this.repository});", "", "  final ${themeMaju}Repository repository;", "", "  final uuid = const Uuid();", "", "") | Add-Content -Path $path\packages\features\$nameList\lib\src\providers\${theme}_provider.dart

# Ajout des différentes entités dans le provider
foreach($entity in $entities) {
    $entityMaju = $entity.Substring(0, 1).ToUpper() + $entity.Substring(1).ToLower()
    @("final _items$entityMaju = <$entityMaju>[];", "  List<$entityMaju> get items$entityMaju => [..._items$entityMaju];", "", "  Future<void> fetchAndSet${entityMaju}s    () async {", "    final datas = await repository.getAll${themeMaju}s();", "    _items.clear();", "    _items.addAll(datas);", "    notifyListeners();") | Add-Content -Path $path\packages\features\$nameList\lib\src\providers\${theme}_provider.dart
}

@("     }", "   }", "}") | Add-Content -Path $path\packages\features\$nameList\lib\src\providers\${theme}_provider.dart

New-Item -Name "providers.dart" -ItemType file
@("export '${theme}_provider.dart';") | Add-Content -Path $path\packages\features\$nameList\lib\src\providers\providers.dart

Set-Location ..

# Ajout des dossier screens et de ses fichiers
mkdir screens
Set-Location screens

New-Item -Name "screens.dart" -ItemType file

Set-Location $path
@("name: $projectName", "description: A new Flutter project.", "", "publish_to: 'none'", "", "version: 1.0.0+1", "", "environment:", "  sdk: ^3.5.1", "", "dependencies:", "  flutter:", "    sdk: flutter", "", "  component_library:", "    path: packages/component_library", "  domain_entities:", "    path: packages/domain_entities", "  ${nameList}:", "    path: packages/features/${nameList}", "  ${nameRepo}:", "    path: packages/${nameRepo}", "dev_dependencies:", "  flutter_test:", "    sdk: flutter", "  flutter_lints: ^4.0.0", "", "flutter:", "  uses-material-design: true") | Set-Content -Path $path\pubspec.yaml