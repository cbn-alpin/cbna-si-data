#!/bin/bash
# Encoding : UTF-8
# Restore Simethis dumps.

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
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${simethis_log_initialize_db}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    createPgToolsAlias
    precheck
    downloadDumps
    dropDb
    createDb
    createUsers
    createExtensions
    restoreSchemas
    addUtilsfunctions

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function createPgToolsAlias() {
    printMsg "Create Postgres tools alias for Simethis..."

    psql_simethis="/usr/lib/postgresql/${simethis_postgres_version}/bin/psql"
    dropdb_simethis="/usr/lib/postgresql/${simethis_postgres_version}/bin/dropdb"
    createdb_simethis="/usr/lib/postgresql/${simethis_postgres_version}/bin/createdb"
    pg_restore_simethis="/usr/lib/postgresql/${simethis_postgres_version}/bin/pg_restore"
}

function precheck() {
    printMsg "Check binaries and directories..."

    printVerbose "Check all necessary binaries" ${Gra-}
    local readonly commands=("$psql_simethis" "$dropdb_simethis" "$createdb_simethis" "$pg_restore_simethis")
    checkBinary "${commands[@]}"

    printVerbose "Check if raw data directories exist" ${Gra-}
    if [[ ! -d "${raw_dir}" ]]; then
        exitScript "Directory '${raw_dir}' does not exist."
    else
        printVerbose "Found directory '${raw_dir}': ${Gre-}OK" ${Gra-}
    fi
    if [[ ! -d "${simethis_dump_folder}" ]]; then
        exitScript "Directory '${simethis_dump_folder}' does not exist."
    else
        printVerbose "Found directory '${simethis_dump_folder}': ${Gre-}OK" ${Gra-}
    fi
}

function downloadDumps() {
    printMsg "Downloading ${app_code^^} data archive..."

    for schema_name in "${simethis_schemas[@]}"; do
        local dump_filename="${schema_name}_${simethis_dump_date//-/}.dump"
        local dump_filepath="${simethis_dump_folder}/${dump_filename}"
        if [[ ! -f "${dump_filepath}" ]]; then
            printVerbose "Dowloading file \"${dump_filename}\" in progress..." ${Gra}
            downloadSftp "${simethis_sftp_download_user}" "${simethis_sftp_download_pwd}" \
                "${simethis_sftp_download_host}" "${simethis_sftp_download_port}" \
                "/${simethis_archive_path}/${dump_filename}" "${dump_filepath}"
        else
            printVerbose "Dump file \"${dump_filename}\" already downloaded." ${Gra}
        fi
    done
}

function dropDb() {
    printMsg "Drop database ${simethis_db_name} if exists"

    if $psql_simethis --port "${simethis_db_port}" --username "${simethis_db_user}" -lqt | cut -d \| -f 1 | grep -qw "${simethis_db_name}"; then
        $psql_simethis --port "${simethis_db_port}" --username "${simethis_db_user}" \
            --dbname "${simethis_db_name}" \
            --command  "SELECT pg_terminate_backend(pg_stat_activity.pid)
            FROM pg_stat_activity
            WHERE pg_stat_activity.datname = '${simethis_db_name}' AND pid <> pg_backend_pid();"
        $dropdb_simethis --port ${simethis_db_port} --username "${simethis_db_user}" \
            --echo --if-exists "${simethis_db_name}"
        printVerbose "Database ${simethis_db_name} was droped" ${Gra-}
    else
        printVerbose "Database ${simethis_db_name} not exits, continue: ${Gre-}OK" ${Gra-}
    fi
}

function createDb() {
    printMsg "Create database ${simethis_db_name}"

    $createdb_simethis --port "${simethis_db_port}" -T template0 "${simethis_db_name}"
}

function createUsers() {
    printMsg "Create all necessary users for the database..."

    local simethis_db_users=( \
        "si_user" "cbnmed_user" "cbnmed_admin" "cbna_user" "cbnc_user" "cbnc_admin" "cbna_admin" \
        "d.rougie" "coadmin_cbn" "simethis_admin" "qgis" "user_w" "pnpc_admin" "g.debarros" \
        "user_sig" "o.gavotto"\
    )
    for user in "${simethis_db_users[@]}"; do
        createUser "${user}"
    done
}

function createUser() {
    local role="${1,,}"
    printVerbose "Create user ${role}" ${Gra-}

    echo "SELECT 'CREATE USER \"${role}\"' WHERE NOT EXISTS (\
        SELECT FROM pg_catalog.pg_roles WHERE rolname = '${role}'\
        )\gexec" | $psql_simethis --port "${simethis_db_port}" --username "${simethis_db_user}"
}

function createExtensions() {
    printMsg "Add all necessary extensions for the database..."

    local simethis_db_extensions=( \
        "postgis" "dblink" '"uuid-ossp"' "tablefunc" "unaccent" "fuzzystrmatch" \
        "postgres_fdw" "intarray" "ogr_fdw" \
    )
    for extension in "${simethis_db_extensions[@]}"; do
        createExtension "${extension}"
    done
}

function createExtension() {
    local extensionName="${1,,}"
    printVerbose "Create extension ${extensionName}" ${Gra-}

    $psql_simethis --port ${simethis_db_port} --username "${simethis_db_user}" \
        --dbname "${simethis_db_name}" \
        --command "CREATE EXTENSION ${extensionName};"
}

function restoreSchemas() {
    printMsg "Restore all database schemas..."

    for schema_name in "${simethis_schemas[@]}"; do
        restoreSchema "${schema_name}"
    done
}

function restoreSchema() {
    local schema_name="${1,,}"
    printMsg "Restore schema ${schema_name}"

    local dump_filepath="${simethis_dump_folder}/${schema_name}_${simethis_dump_date//-/}.dump"
        set +e
        PGPASSWORD="${simethis_db_pass}" $pg_restore_simethis --verbose --jobs ${pg_restore_jobs} \
            --host ${simethis_db_host} --port "${simethis_db_port}" \
            --username "${simethis_db_user}" --dbname "${simethis_db_name}" \
            "${dump_filepath}"
        set -e
}

function addUtilsfunctions() {
    printMsg "Add utils functions..."

    $psql_simethis --port "${simethis_db_port}" --dbname "${simethis_db_name}" \
        -f "${root_dir}/simethis/data/sql/utils.sql"
}

main "${@}"
