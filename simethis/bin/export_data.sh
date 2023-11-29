#!/bin/bash
# Encoding : UTF-8
# Export to CSV files the updated, deleted or new CBNA data from Simethis database.
# CSV files follow AURA/PACA SINP exchange standard.
# See: https://wiki-sinp.cbn-alpin.fr/database/import-formats

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
    redirectOutput "${simethis_log_export_data}"
    checkSuperuser

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    createPgToolsAlias
    precheck
    extractCsv "taxref_rank"
    extractCsv "taxref"
    extractCsv "source"
    extractCsv "organism"
    extractCsv "user"
    extractCsv "acquisition_framework"
    extractCsv "dataset"
    extractCsv "synthese"

    addMetaArchiveIni
    buildArchive
    uploadArchive

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function createPgToolsAlias() {
    printMsg "Create Postgres tools alias for Simethis..."

    psql_simethis="/usr/lib/postgresql/${simethis_postgres_version}/bin/psql"
}

function precheck() {
    printMsg "Check binaries and directories"

    printVerbose "Check all necessary binaries" ${Gra-}
    local readonly commands=("${psql_simethis}")
    checkBinary "${commands[@]}"

    printVerbose "Check if raw data directories exist" ${Gra-}
    if [[ ! -d "${raw_dir}" ]]; then
        exitScript "Directory '${raw_dir}' does not exist."
    else
        printVerbose "Found directory '${raw_dir}': ${Gre-}OK" ${Gra-}
    fi
    if [[ ! -d "${simethis_csv_folder}" ]]; then
        exitScript "Directory '${simethis_csv_folder}' does not exist."
    else
        printVerbose "Found directory '${simethis_csv_folder}': ${Gre-}OK" ${Gra-}
    fi
}

function extractCsv() {
    local csv_file_name="${1,,}"
    printMsg "Extract CSV file ${csv_file_name}"

    local resources_dir="${data_dir}/resources"
    if [[ "${csv_file_name}" =~ ^(synthese)$ ]]; then
        PGPASSWORD="${simethis_db_pass}" $psql_simethis --no-psqlrc \
            --host "${simethis_db_host}" --port "${simethis_db_port}" \
            --username "${simethis_db_user}" --dbname "${simethis_db_name}" \
            --variable cbnaAgentCsvFilePath="${resources_dir}/cbna_agent.csv" \
            --file "${sql_dir}/${csv_file_name}.sql"
    elif [[ "${csv_file_name}" =~ ^(user)$ ]]; then
    PGPASSWORD="${simethis_db_pass}" $psql_simethis --no-psqlrc \
        --host "${simethis_db_host}" --port "${simethis_db_port}" \
        --username "${simethis_db_user}" --dbname "${simethis_db_name}" \
        --variable cbnaAgentCsvFilePath="${resources_dir}/cbna_agent.csv" \
        --variable organismsDuplicatesCsvFilePath="${resources_dir}/organism_uuid_duplicates.csv" \
        --file "${sql_dir}/${csv_file_name}.sql"
    elif [[ "${csv_file_name}" =~ ^(organism|dataset)$ ]]; then
        PGPASSWORD="${simethis_db_pass}" $psql_simethis --no-psqlrc \
            --host "${simethis_db_host}" --port "${simethis_db_port}" \
            --username "${simethis_db_user}" --dbname "${simethis_db_name}" \
            --variable organismsDuplicatesCsvFilePath="${resources_dir}/organism_uuid_duplicates.csv" \
            --file "${sql_dir}/${csv_file_name}.sql"
    else
        PGPASSWORD="${simethis_db_pass}" $psql_simethis --no-psqlrc \
            --host "${simethis_db_host}" --port "${simethis_db_port}" \
            --username "${simethis_db_user}" --dbname "${simethis_db_name}" \
            --file "${sql_dir}/${csv_file_name}.sql" \
            > "${simethis_csv_folder}/${csv_file_name}.csv"
    fi

    if [[ -f "/tmp/${csv_file_name}.csv" ]]; then
        printVerbose "Move /tmp/${csv_file_name}.csv to ${simethis_csv_folder}" ${Gra-}
        sudo chown ${simethis_db_user} /tmp/${csv_file_name}.csv
        sudo mv /tmp/${csv_file_name}.csv ${simethis_csv_folder}/
    fi
}

function addMetaArchiveIni() {
    printMsg "Add meta archive ini file"

    local resources_dir="${data_dir}/resources"
    local ini_filepath="${simethis_csv_folder}/meta_archive.ini"
    cp --force "${resources_dir}/meta_archive.tpl.ini" "${ini_filepath}"

    local export_date=$(date +'%Y-%m-%d %H:%M:%S')
    sed -i "s/\${export_date}/${export_date}/g" "${ini_filepath}"
    sed -i "s/\${taxref_version}/${simethis_taxref_version}/g" "${ini_filepath}"
    sed -i "s/\${contact}/${simethis_export_contact}/g" "${ini_filepath}"

    cat "${ini_filepath}"
}

function buildArchive() {
    printMsg "Build archive ${simethis_archive_filename}"

    cd "${simethis_csv_folder}/"
    tar cjvf "./${simethis_archive_filename}" *.{ini,csv}
}

function uploadArchive() {
    printMsg "Uploading ${simethis_archive_filename} archive..."

    cd "${simethis_csv_folder}/"
    uploadSftp "${simethis_sftp_upload_user}" "${simethis_sftp_upload_pwd}" \
        "${simethis_sftp_upload_host}" "${simethis_sftp_upload_port}" \
        "/${simethis_archive_path}/" "${simethis_archive_filename}"
}

main "${@}"
