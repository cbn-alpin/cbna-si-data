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
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.bash"

    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadModuleDefaultConfig "${setting_file_path-}"
    loadModuleUserConfig "${setting_file_path-}"
    redirectOutput "${cbna_log_imports}"
    local readonly commands=("7za" "psql" "dropdb" "createdb" "unzip")
    checkBinary "${commands[@]}"


    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    initDB
    extractArchive
    restoreData

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function initDB() {
    printMsg "drop db if exists"
    dropdb --if-exists "${db_name}"

    printMsg "Create db"
    createdb -E UTF8 -O "${db_user}" "${db_name}"

    printMsg "create extension postgis & postgis_topology"
    psql "${db_name}" -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology;"
}

function extractArchive() {
    printMsg "Extract import data CSV files..."

    cd "${raw_dir}/"
    unzip "${raw_dir}/${cbna_folder_archive}.zip"

    cd "${raw_dir}/${cbna_folder_archive}/"
    for archive in *.7z.001 ; do
        7za x "$archive"
    done

    cd "${raw_dir}/${cbna_folder_archive}/"
    for archive in *.7z ; do
        7za x "$archive" -o*
    done

}

function restoreData() {
    printMsg "Import data into database..."

    find "${raw_dir}/${cbna_folder_archive}/" -type f -name "*.sql" -print0 | while read -d $'\0' file ; do
        psql -h "${db_host}" -p "${db_port}" -U "${db_user}" -d "${db_name}" -f "${file}"
    done
}


main "${@}"
