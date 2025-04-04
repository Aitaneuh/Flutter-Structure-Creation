function Set-UpperCamelCase {
    param([string]$inputString)
    return ($inputString -split '\s+|_|-' | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() }) -join ''
}

# Texte du début
Clear-Host
Write-Host "Création complète de la structure de votre projet Flutter - en local"
Write-Host "===================================================================="
Write-Host ""
Write-Host "- Assurez-vous d'avoir Flutter installé sur votre machine"
Write-Host "- Assurez-vous d'avoir un / des fichier(s) json qui correspond à vos entités et propriétés"
Write-Host "- Vous devrez ajoutez vos fichiers json dans le dossier packages/repository/lib/src/assets/data"
Write-Host "- Votre fichier devra être composé de Map avec le nom de votre entité en clé"
Write-Host ""

# Demande du nom du projet
$projectName = Read-Host "Entrez le nom de votre projet Flutter"
$projectPath = Read-Host "Entrez le chemin du projet Flutter"

Write-Host "Création du projet Flutter : $projectName"
Set-Location $projectPath
$platforms = "android,web" #todo
flutter create --platforms=$platforms $projectName
Write-Host "Le projet $projectName a été créé avec succès."


# Path mis sur le dossier actuel
$path = "$projectPath\$projectName"


# Sélection du thème principal
$theme = Read-Host "Entrez le thème principal de votre projet Flutter"
$themeMaju = $theme.Substring(0, 1).ToUpper() + $theme.Substring(1).ToLower()

# Récupération de la version du SDK et stockage dans une variable
$sdk = ((Get-Content -Path "$path\pubspec.yaml") -match "sdk: \^(\d+\.\d+\.\d+)")[0] -split "sdk: \^" | Select-Object -Last 1

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

@("name: domain_entities", "publish_to: none", "", "environment:", "  sdk: ^${sdk}", "", "dependencies:", "  equatable: ^2.0.7", "", "dev_dependencies:", "  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\domain_entities\pubspec.yaml

foreach ($entity in $entities) {
    $entityName = $entity.Name
    $entityPath = "$path\packages\domain_entities\lib\src"

    $className = Set-UpperCamelCase $entityName

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
    @("export 'src/$entityName.dart';") | Add-Content -Path "$path\packages\domain_entities\lib\domain_entities.dart"
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
@("name: $nameRepo", "publish_to: none", "", "environment:", "  sdk: ^${sdk}", "", "dependencies:", "  flutter:", "    sdk: flutter", "  domain_entities:", "    path: ../domain_entities", "dev_dependencies:", "  flutter_lints: ^4.0.0", "flutter: ", "  assets:", "    - lib/src/assets/data/data.json") | Add-Content -Path $path\packages\$nameRepo\pubspec.yaml

# Ajout des dossiers lib/src et du barrel
mkdir lib
Set-Location lib

@("library $nameRepo;", "export 'src/mappers/mappers.dart';", "export 'src/models/models.dart';", "export 'src/services/services.dart';", "export 'src/${nameRepo}.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\$nameRepo.dart

mkdir src
Set-Location src

# Fichier repo 2ème niveau
New-Item -Name $nameRepo".dart" -ItemType file
@("import 'package:domain_entities/domain_entities.dart';", "import 'package:${nameRepo}/src/services/services.dart';", "import 'package:${nameRepo}/${nameRepo}.dart';", "class ${themeMaju}Repository {") | Add-Content -Path $path\packages\$nameRepo\lib\src\$theme"_repository.dart"

foreach ($entity in $entities) {
    $name = $entity.Name
    $requiredEntities += "required this.${name}Storage,"
}

@(" const ${themeMaju}Repository({$requiredEntities});", "") | Add-Content -Path $path\packages\$nameRepo\lib\src\$theme"_repository.dart"


foreach ($entity in $entities) {
    $name = $entity.Name
    $nameMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()

    @("  final ${nameMaju}Storage ${name}Storage;", "") | Add-Content -Path $path\packages\$nameRepo\lib\src\$theme"_repository.dart"

    @("  Future<List<${nameMaju}>> getAll${nameMaju}s() async {", "    return ${name}Storage.getAll${nameMaju}s();", "  }") | Add-Content -Path $path\packages\$nameRepo\lib\src\$nameRepo".dart"
}

@("}") | Add-Content -Path $path\packages\$nameRepo\lib\src\$theme"_repository.dart"

# Ajout du dossier et des fichiers models
New-Item -Name models -ItemType Directory
Set-Location models
New-Item -Name "models.dart" -ItemType file

# Fichiers model local
foreach ($entity in $entities) {
    $entityName = $entity.Name
    $nameMaju = $entityName.Substring(0, 1).ToUpper() + $entityName.Substring(1).ToLower()
    New-Item -Name "${entityName}_local_file_model.dart" -ItemType file
    @("export '${entityName}_local_file_model.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\models.dart
    @("class ${nameMaju}LocalFileModel {", "  const ${nameMaju}LocalFileModel(") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart

    foreach ($property in $entity.Properties) {
        $thisProperty = "       this.${property},"
        @($thisProperty) | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart
    }
    @("  );", "") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart
    

    @(" factory ${nameMaju}LocalFileModel.fromJson(Map<String, dynamic> json) {", "    return ${nameMaju}LocalFileModel(") | Add-Content -Path $path\packages\$nameRepo\lib\src\models\${entityName}_local_file_model.dart

    foreach ($property in $entity.Properties) {
        $thisProperty = "           json['${property}'],"
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
    $entityMaju = $entityName.Substring(0, 1).ToUpper() + $entityName.Substring(1).ToLower()
    New-Item -Name "${entityName}_local_file_model_to_domain.dart" -ItemType file
    @("export '${entityName}_local_file_model_to_domain.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\mappers.dart

    @("import 'package:domain_entities/domain_entities.dart';", "import 'package:$nameRepo/$nameRepo.dart';", "extension ${entityMaju}LocalFileModelToDomain on ${entityMaju}LocalFileModel {", "  ${entityMaju} toDomainEntity() {", "    return ${entityMaju}(") | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\${entityName}_local_file_model_to_domain.dart

    foreach ($property in $entity.Properties) {
        $thisProperty = "       ${property}: ${property},"
        @($thisProperty) | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\${entityName}_local_file_model_to_domain.dart
    }
    @("    );", "  }", "}") | Add-Content -Path $path\packages\$nameRepo\lib\src\mappers\${entityName}_local_file_model_to_domain.dart
}

Set-Location .. 

# Ajout du dossier assets
mkdir assets
Set-Location assets
mkdir data
Set-Location ..

# Ajout du dossier et des fichiers services
New-Item -Name services -ItemType Directory
Set-Location services

New-Item -Name "services.dart" -ItemType file

# Fichier storage
New-Item -Name "storage.dart" -ItemType file
@("import 'package:domain_entities/domain_entities.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\src\services\storage.dart

foreach ($entity in $entities) {
    $name = $entity.Name
    $nameMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()
    @("abstract class ${nameMaju}Storage {", "  Future<List<${nameMaju}>> getAll${nameMaju}s();", "}") | Add-Content -Path $path\packages\$nameRepo\lib\src\services\storage.dart
}

# Ajout des différents fichiers de storage_local
foreach ($entity in $entities) {
    $name = $entity.Name
    $nameMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()
    New-Item -Name "${name}_local_storage.dart" -ItemType file
    @("import 'dart:convert';", "import 'package:domain_entities/domain_entities.dart';", "import 'package:flutter/services.dart';", "import 'package:${theme}_repository/${theme}_repository.dart';", "", "class ${nameMaju}LocalStorage implements ${nameMaju}Storage {", "  @override", "  Future<List<${nameMaju}>> getAll${nameMaju}s() async {", "    final ${name}s = <${nameMaju}>[];", "", "        final dataString = await rootBundle.loadString('packages/${theme}_repository/lib/src/assets/data/data.json');", "       final Map<String, dynamic> json = jsonDecode(dataString);", "", "    json['${name}'].forEach((v) {", "      ${name}s.add(${nameMaju}LocalFileModel.fromJson(v).toDomainEntity());", "    });", "    return ${name}s;", "  }", "}") | Add-Content -Path $path\packages\$nameRepo\lib\src\services\${name}_local_storage.dart

    @("")
    @("export '${name}_local_storage.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\src\services\services.dart
}
@("export 'storage.dart';") | Add-Content -Path $path\packages\$nameRepo\lib\src\services\services.dart


Set-Location ..

# Création du dossier component_library
set-location $path\packages
mkdir component_library
Set-Location component_library

# Ajout du fichier analysis_options.yaml et pubspec.yaml
@("include: package:flutter_lints/flutter.yaml", "", "linter:", "  rules:") | Add-Content -Path $path\packages\component_library\analysis_options.yaml

@("name: component_library", "publish_to: none", "", "environment:", "  sdk: ^${sdk}", "", "dependencies:", "  flutter:", "    sdk: flutter", "  domain_entities:", "    path: ../domain_entities", "dev_dependencies:", "  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\component_library\pubspec.yaml

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
@("name: $nameList", "publish_to: none", "", "environment:", "  sdk: ^${sdk}", "", "dependencies:", "  flutter:", "    sdk: flutter", "", "  component_library:", "    path: ../../component_library", "  domain_entities:", "    path: ../../domain_entities", "  ${nameRepo}:", "    path: ../../${nameRepo}", "dev_dependencies:", "  flutter_lints: ^4.0.0") | Add-Content -Path $path\packages\features\$nameList\pubspec.yaml

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
foreach ($entity in $entities) {
    $name = $entity.Name
    $entityMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()
    @("final _items$entityMaju = <$entityMaju>[];", "  List<$entityMaju> get items$entityMaju => [..._items$entityMaju];", "", "  Future<void> fetchAndSet${entityMaju}s () async {", "    final datas = await repository.getAll${entityMaju}s();", "    _items${entityMaju}.clear();", "    _items${entityMaju}.addAll(datas);", "    notifyListeners();", "}") | Add-Content -Path $path\packages\features\$nameList\lib\src\providers\${theme}_provider.dart
}

@("}") | Add-Content -Path $path\packages\features\$nameList\lib\src\providers\${theme}_provider.dart

New-Item -Name "providers.dart" -ItemType file
@("export '${theme}_provider.dart';") | Add-Content -Path $path\packages\features\$nameList\lib\src\providers\providers.dart

Set-Location ..

# Ajout des dossier screens et de ses fichiers
mkdir screens
Set-Location screens

New-Item -Name 'home_screen.dart' -ItemType file
@("import 'package:component_library/component_library.dart';", "import 'package:flutter/material.dart';", "import 'package:${theme}_list/${theme}_list.dart';", "", "class HomeScreen extends StatefulWidget {", "  const HomeScreen({super.key});", "", "  @override", "  State<HomeScreen> createState() => _HomeScreenState();", "}", "class _HomeScreenState extends State<HomeScreen> {", "  var _isLoading = false;", "  var _isInit = true;", "", "  @override", "  void didChangeDependencies() async {", "    if (_isInit) {", "      _fetchData();", "      _isInit = false;", "    }", "    }", "", "  Future<void> _fetchData() async {", "    setState(() {", "      _isLoading = true;", "    });", "", "    final ${theme}Provider = context.read<${themeMaju}Provider>();", "") | Add-Content -Path $path\packages\features\$nameList\lib\src\screens\home_screen.dart

foreach ($entity in $entities) {
    $name = $entity.Name
    $nameMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()
    @("    if (${theme}Provider.items${nameMaju}.isEmpty) {", "      await ${theme}Provider.fetchAndSet${nameMaju}s();", "    }") | Add-Content -Path $path\packages\features\$nameList\lib\src\screens\home_screen.dart
}

@("    setState(() {","      _isLoading = false;","    });","  }", "", "  @override", "  Widget build(BuildContext context) {", "    final ${theme}Provider = context.watch<${themeMaju}Provider>();", "", "    return Scaffold(", "      appBar: AppBar(title: const Text('${themeMaju}')),", "      body: _isLoading", "          ? const Center(child: CircularProgressIndicator())", "          : ListView(", "              padding: const EdgeInsets.all(16.0),", "              children: [") | Add-content -path $path\packages\features\$nameList\lib\src\screens\home_screen.dart

foreach ($entity in $entities) {
    $name = $entity.Name
    $nameMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()
    @("                ...${theme}Provider.items${nameMaju}.map(", "                  ($name) => _buildSection('$nameMaju', [") | Add-Content -Path $path\packages\features\$nameList\lib\src\screens\home_screen.dart

    foreach($property in $entity.Properties) {
        $propertyMaju = $property.Substring(0, 1).ToUpper() + $property.Substring(1).ToLower()
        $element = '${' + $name + "." + $property + '}'
        @("                    '${propertyMaju}: $element',") | Add-Content -Path $path\packages\features\$nameList\lib\src\screens\home_screen.dart
    }

    @("                  ]),", "                ),", "                const Divider(),") | Add-Content -Path $path\packages\features\$nameList\lib\src\screens\home_screen.dart
}

@("              ],", "            ),", "    );", "  }", "", "  Widget _buildSection(String title, List<String> details) {", "    return Column(", "      crossAxisAlignment: CrossAxisAlignment.start,", "      children: [", "        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),", "        ...details.map((detail) => Text(detail)),", "        const SizedBox(height: 10),", "      ],", "    );", "  }", "}") | Add-Content -Path $path\packages\features\$nameList\lib\src\screens\home_screen.dart

New-Item -Name "screens.dart" -ItemType file
@("export 'home_screen.dart';") | Add-Content -Path $path\packages\features\$nameList\lib\src\screens\screens.dart

Set-Location $path
@("name: $projectName", "description: A new Flutter project.", "", "publish_to: 'none'", "", "version: 1.0.0+1", "", "environment:", "  sdk: ^${sdk}", "", "dependencies:", "  flutter:", "    sdk: flutter", "", "  component_library:", "    path: packages/component_library", "  ${nameList}:", "    path: packages/features/${nameList}", "  ${nameRepo}:", "    path: packages/${nameRepo}", "  cupertino_icons: ^1.0.8", "dev_dependencies:", "  flutter_test:", "    sdk: flutter", "  flutter_lints: ^4.0.0", "", "flutter:", "  uses-material-design: true") | Set-Content -Path $path\pubspec.yaml

# Ajout du main
Set-Location -Path $path\lib

# flutter pub add provider

Remove-Item -Path main.dart
New-Item -Name main.dart -ItemType file
@("import 'package:flutter/material.dart';", "import 'package:component_library/component_library.dart';", "import 'package:${theme}_list/${theme}_list.dart';", "import 'package:${theme}_repository/${theme}_repository.dart';", "", "void main() {", "  runApp(const MyApp());", "}", "", "class MyApp extends StatelessWidget {", "  const MyApp({super.key});", "", "  @override", "  Widget build(BuildContext context) {", "    return MultiProvider(", "      providers: [") | Add-Content -Path $path\lib\main.dart

foreach ($entity in $entities) {
    $name = $entity.Name
    $nameMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()
    @("        Provider<${nameMaju}LocalStorage>(", "          create: (context) => ${nameMaju}LocalStorage(),", "        ),") | Add-Content -Path $path\lib\main.dart
}

@("        Provider<${themeMaju}Repository>(", "          create: (context) =>") | Add-Content -Path $path\lib\main.dart
$storages = ""
foreach ($entity in $entities) {
    $name = $entity.Name
    $nameMaju = $name.Substring(0, 1).ToUpper() + $name.Substring(1).ToLower()
    $storages += "${name}Storage: context.read<${nameMaju}LocalStorage>(), "
}
@() | Add-Content -Path $path\lib\main.dart
@("         ${themeMaju}Repository($storages),", "        ),", "        ChangeNotifierProvider<${themeMaju}Provider>(", "          create: (context) =>", "              ${themeMaju}Provider(repository: context.read<${themeMaju}Repository>()),", "        ),", "      ],", "      child: MaterialApp(", "        debugShowCheckedModeBanner: false,", "        title: '$projectName',", "        theme: ThemeData(", "          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),", "          useMaterial3: true,", "        ),", "      home: const HomeScreen(),", "      ),", "    );", "  }", "}") | Add-Content -Path $path\lib\main.dart

# Création du fichier de configuration
Set-Location $path
mkdir .vscode
Set-Location .vscode
New-Item -Name launch.json -ItemType file
@('{', '    "configurations": [', '        {', '            "name": "Main",', '            "type": "dart",', '            "request": "launch",', '            "program": "lib\\main.dart"', '        }', '    ]', '}') | Add-Content -Path $path/.vscode/launch.json

Set-Location $path