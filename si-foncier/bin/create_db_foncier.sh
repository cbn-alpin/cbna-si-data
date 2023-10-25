#!/bin/bash
# Encoding : UTF-8
# Import Foncier data into sigeo database.

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: path to config file to use (default : config/settings.ini)
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
            "--help") set -- "${@}" "-h" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "-c" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
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

    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${log_file}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    precheck
    initializeDatabase
    downloadArchives
    unzipArchives
    executeInitSqlFiles
    executeDataSqlFiles

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function precheck() {
    printMsg "Check binaries and directories"

    printVerbose "Check all necessary binaries" ${Gra-}
    local readonly commands=("7za" "psql" "unzip" "gdown")
    checkBinary "${commands[@]}"

    printVerbose "Check if the raw data directory exists" ${Gra-}
    if [[ ! -d "${raw_dir}" ]]; then
        exitScript "Directory '${raw_dir}' does not exist."
    else
        printVerbose "Found directory '${raw_dir}': ${Gre-}OK" ${Gra-}
    fi

}

function initializeDatabase() {
    printMsg "Create extensions postgis & postgis_topology..."
    psql "${db_name}" --command "CREATE EXTENSION IF NOT EXISTS postgis;"
    psql "${db_name}" --command "CREATE EXTENSION IF NOT EXISTS postgis_topology;"
}

function downloadArchives() {
    printMsg "Download ${#sifo_gdrive_files[@]} necessary archives files from Google Drive..."
    cd "${raw_dir}"
    for file_id in "${!sifo_gdrive_files[@]}"; do
        local file_name="${sifo_gdrive_files[$file_id]}"
        if [[ ! -f "${file_name}" ]]; then
            gdown --quiet --output "${file_name}" "${file_id}"
        else
            printVerbose "File '${file_name}' already downloaded !" ${Gra-}
        fi
    done
}

function unzipArchives() {
    printMsg "Unzip archive files..."
    # Loop through all archive files in the raw data directory
    find "${raw_dir}" -type f -name "*.zip" -print0 | sort -z | while read -d $'\0' archive; do
        printVerbose "Unziping archive: ${archive}" ${Gra-}
        if [[ ! -d "${archive%.*}" ]]; then
            # Determine the archive format and extract accordingly
            unzip "${archive}" -d "${archive%.*}"
            cd ${archive%.*}
            pwd
            for archive in */*.7z.001; do
                7za x "${archive}"
            done
            for archive in *.7z; do
                7za x "${archive}" -o*
            done
        else
            printVerbose "Zip file '${archive}' already extracted." ${Gra-}
        fi
    done
}

function executeInitSqlFiles() {
    printMsg "Extract distinct INIT SQL files..."
    declare -A distinct_sql_files
    # WARNING: do not use PIPE with associative array (distinct_sql_files)
    while IFS= read -r -d '' file_path; do
        local lines=$(wc -l "${file_path}" | awk '{ print $1 }')
        local bytes=$(wc -c "${file_path}" | awk '{ print $1 }')
        local hash="${lines}-${bytes}"

        if [[ ! -n "${distinct_sql_files[${hash}]:-}" ]]; then
            printVerbose "New distinct file find: ${hash} ${file_path}" ${Gra-}
            distinct_sql_files[${hash}]="${file_path}"
        fi
    done < <(find "${raw_dir}/" -type f -name "*_init.sql" -print0)

    printMsg "Execute ${#distinct_sql_files[@]} INIT SQL files..."
    for file in "${distinct_sql_files[@]}"; do
        printVerbose "Importing SQL file '${file}' ..." ${Gra-}
        export PGPASSWORD="${db_pass}"; \
            psql --host "${db_host}" --port "${db_port}" --username "${db_user}" \
                --dbname "${db_name}" --file "${file}"
    done
}

function executeDataSqlFiles() {
    printMsg "Extract distinct DATA SQL files..."
    declare -A distinct_sql_files
    # WARNING: do not use PIPE with associative array (distinct_sql_files)
    while IFS= read -r -d '' file_path; do
        local lines=$(wc -l "${file_path}" | awk '{ print $1 }')
        local bytes=$(wc -c "${file_path}" | awk '{ print $1 }')
        local hash="${lines}-${bytes}"

        if [[ ! -n "${distinct_sql_files[${hash}]:-}" ]]; then
            printVerbose "New distinct file find: ${hash} ${file_path}" ${Gra-}
            distinct_sql_files[${hash}]="${file_path}"
        fi
    done < <(find "${raw_dir}/" -type f -name "*_data.sql" -print0)

    printMsg "Execute ${#distinct_sql_files[@]} DATA SQL files..."
    for file in "${distinct_sql_files[@]}"; do
        printVerbose "Importing SQL file '${file}' ..." ${Gra-}
        export PGPASSWORD="${db_pass}"; \
            psql --host "${db_host}" --port "${db_port}" --username "${db_user}" \
                --dbname "${db_name}" --file "${file}"
    done
}


main "${@}"
