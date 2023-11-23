#!/bin/bash
# Encoding : UTF-8
# Maintain a history of standards changes (customization) made by CBNA.
# These modifications are stored in the 'cbna' schema of the GeoNature database.

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

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${cbna_log_imports}"
    checkSuperuser

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    buildTablePrefix

    executeCopy "taxref rank"
    executeCopy "taxref"

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function buildTablePrefix() {
    table_prefix="${app_code}_${cbna_import_date//-/}"
}

function executeCopy() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi
    local type="${1,,}"
    local data_type="${type// /_}"
    local data_type_abbr=$(echo "${type}" | sed 's/\(.\)[^ ]* */\1/g')
    if [[ "${#data_type_abbr}" = "1" ]]; then
        data_type_abbr="${data_type}"
    fi
    local table="${table_prefix}_${data_type}"
    local sql_file="${sql_dir}/${data_type}/copy.sql"
    local csv_file="${raw_dir}/${data_type}.csv"
    local psql_var="${data_type_abbr}ImportTable"

    printMsg "Copy ${type^^} in GeoNature database..."
    if [[ -f "${csv_file}" ]]; then
        sudo -n -u "${pg_admin_name}" -s \
            psql -d "${db_name}" \
                -v "${psql_var}=${table}" \
                -v gnDbOwner="${db_user}" \
                -v csvFilePath="${csv_file}" \
                -f "${sql_file}"
    else
        printVerbose "Skip copy of ${type^^}. CSV file was not found : ${csv_file}" ${Gra}
    fi
}


main "${@}"
