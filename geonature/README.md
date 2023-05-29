# Import geonature
Contient les scripts d'import des données flore et végétation du CBNA issues de la base Simethis.
Contient l'arborescence suivante :
  - bin : contient le script bash **import_update.sh** permettant de parcourir et extraire les données des fichiers "acquisition_framework.csv", "dataset.csv", "organism.csv", "source.csv", "synthese.csv" se trouvant dans le dossier data/raw. 
  - config : contient les paramètres de configuration
  - data : contient
    - un dossier raw  : des fichiers sous format CSV des données à importer dans GeoNature 
    - un dossier sql : qui contiendra les fichiers avec les requêtes SQL
  - var : 
    - un dossier log : contient le rapport des erreurs 
 
 
