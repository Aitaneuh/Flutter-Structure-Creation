# Flutter Project Structure Generator

## Overview
This PowerShell script automates the creation of a structured Flutter project with a clean architecture approach. It generates necessary packages, folders, and files based on user input, making it easier to start a new Flutter project.

## Features
- Initializes a new Flutter project
- Generates domain entities and repository structure
- Supports JSON-based entity and property definitions
- Creates clean architecture components like models, mappers, and services
- Adds essential dependencies for Flutter development

## Prerequisites
Before running the script, ensure you have:
- [Flutter](https://flutter.dev/) installed on your machine
- A valid JSON file with entity definitions
- PowerShell installed on your system

## Usage
1. **Run the script in PowerShell**
   ```powershell
   .\generate_flutter_structure.ps1
   ```
2. **Provide the required details when prompted:**
   - Project name
   - Project path
   - Main theme name
   - Entities and properties

3. **The script will:**
   - Create a new Flutter project
   - Generate the necessary package structure
   - Set up domain entities, repository, and services
   - Configure required dependencies

## Project Structure
The script will generate the following structure:
```
project_name/
│── packages/
│   ├── domain_entities/
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   ├── domain_entities.dart
│   ├── repository/
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── models/
│   │   │   │   ├── mappers/
│   │   │   │   ├── services/
│   │   │   │   ├── repository.dart
│   ├── component_library/
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   ├── component_library.dart
│── example/
│── pubspec.yaml
```

## Dependencies
The script automatically installs the following dependencies:
- `equatable` for entity equality
- `flutter_lints` for linting
- `storybook_flutter` for UI component previews

## Notes
- JSON files containing entity definitions must be placed in:
  ```
  packages/repository/lib/src/assets/data
  ```
- The JSON format should be:
  ```json
  {
    "EntityName": [
      { "property1": "value", "property2": "value" }
    ]
  }
  ```
