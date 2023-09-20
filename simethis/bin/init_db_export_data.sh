#!/bin/bash
# Encoding : UTF-8
# Import some updated, deleted or new data in GeoNature Database the CBNA Flora Data.

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options]
     --host | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     --command | --config: path to config file to use (default : config/settings.ini)
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--help") set -- "${@}" "--host" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "--command" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use --host option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use --host option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadModuleDefaultConfig "${setting_file_path-}"
    loadModuleUserConfig "${setting_file_path-}"
    redirectOutput "${sialp_log_imports}"
    local readonly commands=("psql" "dropdb" "createdb" "unzip")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    # createDb
    # createUsers
    # createExtensions

    # restoreSchemas
    # addUtilsfunctions

    extractCSV "taxref_rangs"
    extractCSV "taxref"
    extractCSV "taxref_modifs"
    extractCSV "source"
    # extractCSV "organism"
    extractCSV "user"
    extractCSV "acquisition_framework"
    extractCSV "dataset"
    extractCSV "synthese"

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function createDb() {
    printMsg "Drop database ${db_name} if exists"
    # Remove previously loaded database
    if psql --username "${db_user}" -lqt | cut -d \| -f 1 | grep -qw "${db_name}"; then
        psql --username "${db_user}" --dbname "${db_name}" --command \
            "SELECT pg_terminate_backend(pg_stat_activity.pid)
            FROM pg_stat_activity
            WHERE pg_stat_activity.datname = '${db_name}' AND pid <> pg_backend_pid();"
        dropdb --username "${db_user}" --echo --if-exists "${db_name}"
    fi
    printMsg "Create database ${db_name}"
    createdb -T template0 "${db_name}"
}

function createUsers() {
    createUser "si_user"
    createUser "cbnmed_user"
    createUser "cbnmed_admin"
    createUser "cbna_user"
    createUser "cbnc_user"
    createUser "cbnc_admin"
    createUser "cbna_admin"
    createUser "d.rougie"
}

function createUser() {
    local role="${1,,}"
    printMsg "Create user ${role}"
    echo "SELECT 'CREATE USER ${role}' WHERE NOT EXISTS (\
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '${role}'\
    )\gexec" | psql
}

function createExtensions() {
    createExtension "postgis"
    createExtension "dblink"
    createExtension '"uuid-ossp"'
    createExtension "tablefunc"
    createExtension "unaccent"
    createExtension "fuzzystrmatch"
    createExtension "postgres_fdw"
    createExtension "intarray"
    createExtension "ogr_fdw"
}

function createExtension() {
    local extensionName="${1,,}"
    printMsg "Create extension ${extensionName}"
    psql --dbname ${db_name} --command "CREATE EXTENSION ${extensionName};"
}

function restoreSchemas() {
    restoreSchema "referentiels"
    restoreSchema "applications"
    restoreSchema "sinp"
    restoreSchema "vegetation"
    restoreSchema "flore"
}

function restoreSchema() {
    local schemaName="${1,,}"
    printMsg "Restore schema ${schemaName}"

    if [[ ${schemaName} = "sinp" ]]; then
        PGPASSWORD=${db_pass} psql --host ${db_host} --username ${db_user} --dbname ${db_name} \
        --command "CREATE SCHEMA ${schemaName}"
    fi

    set +e
    PGPASSWORD=${db_pass} pg_restore --host ${db_host} --port ${db_port} --username ${db_user} \
    --dbname ${db_name} \
    --jobs ${pg_restore_jobs} --verbose \
    "${dump_folder}/${schemaName}_${si_cbn_import_date//-/}.dump"
    set -e
}

function addUtilsfunctions() {
    printMsg "Adding utils functions"
    psql --dbname "${db_name}" \
        -f "${root_dir}/simethis/data/sql/utils.sql"
}

function extractCSV() {
    local csvFileName="${1,,}"
    printMsg "Extract CSV file ${csvFileName}"
    echo "${raw_dir}/cbna_agent.csv"

    if [[ ${csvFileName} = "organism"] || [${csvFileName} = "synthese" ]]; then
        PGPASSWORD=${db_pass} psql --no-psqlrc --host ${db_host} --username ${db_user} \
        --dbname ${db_name} -f "${sql_dir}/${csvFileName}.sql"
        sudo chown ${db_user} /tmp/${csvFileName}.csv
        sudo mv /tmp/${csvFileName}.csv ${csv_folder}/
    fi

    if [[ ${csvFileName} = "user" ]]; then
        PGPASSWORD=${db_pass} psql --no-psqlrc --host ${db_host} --username ${db_user} \
        --dbname ${db_name} -v cbnaAgentCsvFilePath="${raw_dir}/cbna_agent.csv" \
        -f "${sql_dir}/${csvFileName}.sql"
        sudo chown ${db_user} /tmp/${csvFileName}.csv
        sudo mv /tmp/${csvFileName}.csv ${csv_folder}/
    fi

    PGPASSWORD=${db_pass} psql --no-psqlrc --host ${db_host} --username ${db_user} \
    --dbname ${db_name} -f "${sql_dir}/${csvFileName}.sql" \
    > "${csv_folder}/${csvFileName}.csv"
}

main "${@}"
