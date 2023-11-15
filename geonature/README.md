# Import GeoNature

Contient les scripts d'import des données flore et végétation du CBNA issues de la base Simethis.

## Arborescence des dossiers

  - `bin/` : contient les scripts Bash utilisés pour l'import des données CBNA dans GeoNature.
    - `import_update.sh` : script permettant de parcourir et extraire les données des fichiers "acquisition_framework.csv", "dataset.csv", "organism.csv", "source.csv", "synthese.csv" se trouvant dans le dossier `data/raw`.
  - `config/` : contient les paramètres de configuration.
  - `data/` :
    - `raw/`  : contient les fichiers principalement au format CSV des données à importer dans GeoNature.
    - `sql/` : contient les fichiers SQL utilisés par les scripts présents dans `bin/`.
  - `var/` :
    - `log/` : contient les logs d'execution des scripts présents dans `bin/`.


