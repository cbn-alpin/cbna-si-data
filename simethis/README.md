# Export Simethis
Contient les scripts d'export des données du CBNA depuis la base Simethis.
Contient une arborescence suivante :
  - bin : contient le script bash **initdb.sh** permettant la restauration du dump des données flore et végétation de simethis. A terme il contiendra, également, un autre script bash permettant d'extraire les données de la base de données PostgreSQL (contenant les données flore et végétation de simethis) sous format CSV.
  - config : contient les paramètres de configuration
  - data : 
    - un dossier raw : des fichiers sous format csv des données exportées depuis simethis
    - un dossier sql : des requêtes SQL
 
 
