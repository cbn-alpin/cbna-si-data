# Export Simethis

Contient les scripts d'export des données du CBNA depuis la base Simethis.

## Arborescence des dossiers
- `bin/` : contient les scripts Bash permettant la restauration en local de la base Simethis et l'export des données CBNA.
  - **initialize_db.sh** : scripts Bash permettant la restauration des dumps de la base Simethis.
  - **export_data.sh** : scripts Bash permettant d'extraire les données du CBNA de la base de données locale Simethis sous format CSV.
- `config/` : contient les paramètres de configuration.
- `data/` :
  - `raw/` : contient les fichiers principalement au format CSV des données à importer dans GeoNature.
    - `expoted_csv/` : dossier configuré par défaut pour hébergé les fichiers CSV exportés de la base locale Simethis.
    - `dumps/` :  dossier configuré par défaut pour hébergé les fichiers dumps de Simethis à restaurer localement.
  - `sql/` : contient les fichiers SQL utilisés par les scripts présents dans `bin/`.
- `var/` :
  - `log/` : contient les logs d'execution des scripts présents dans `bin/`.

