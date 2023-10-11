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
    source "$(dirname "${BASH_SOURCE[0]}")/../../shared/lib/utils.bash"

    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${log_file}"
    local readonly commands=("7za" "psql" "dropdb" "createdb" "unzip")
    checkBinary "${commands[@]}"


    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    initDB
    extractArchive "${raw_dir}"
    restoreData

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function initDB() {

    printMsg "create extension postgis & postgis_topology"
    psql "${db_name}" --command "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS postgis_topology;"
}

function extractArchive() {
    printMsg "Extract import data CSV files..."

    local dir="$1"

    # Check if the directory exists
    if [ ! -d "$dir" ]; then
        echo "Directory '$dir' does not exist."
        return 1
    fi


    # Loop through all archive files in the directory
    find "$dir" -type f \( -name "*.tar" -o -name "*.tar.gz" -o -name "*.tgz" -o -name "*.tar.bz2" -o -name "*.tar.xz" -o -name "*.zip" -o -name "*.7z.001" -o -name "*.7z" \) -exec sh -c '
        for archive do
            if [ ! -d "${archive%.*}" ]; then
                # Determine the archive format and extract accordingly
                if [ "${archive##*.}" = "zip" ]; then
                    unzip "$archive" -d "${archive%.*}"
                    cd ${archive%.*}
                    for archive in */; do
                        7za x "$archive"
                    done
                    for archive in *.7z; do
                        7za x "$archive" -o*
                    done
                else 
                    tar xf "$archive" -C "${archive%.*}"
                fi
            else
                echo "Zip file already extracted." ${Gra}
            fi
        done
    ' sh {} +
}

function restoreData() {
    printMsg "Import data into database..."

    find "${raw_dir}/" -type f -name "*.sql" -print0 | while read -d $'\0' file ; do
        export PGPASSWORD="${db_pass}"; \
        psql --host "${db_host}" --port "${db_port}" --username "${db_user}" --dbname "${db_name}" --file "${file}"
    done
}


main "${@}"
