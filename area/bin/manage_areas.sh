#!/bin/bash
# Encoding : UTF-8

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    loadScriptConfig "${setting_file_path-}"
    cat << EOF
${app_name-} [${app_code-}]
${app_desc-}

Usage: ./$(basename $BASH_SOURCE) [options] [action]
Example: ./$(basename $BASH_SOURCE) -v --subdivided
Options:
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: path to config file to use (default : config/settings.ini)
     -r | --run: execute an action. See action keyword below.

Actions:
     "add-tag": add CBNA TAG geometry in l_areas. Add "TAG" type.
     "add-countries": add countries geometries in l_areas. Add "COUNTRY" type.
     "subdivide": create subdivided_area table in ref_geo schema.
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
            "--run") set -- "${@}" "-r" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:r:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "r") readonly action="${OPTARG}" ;;
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
    redirectOutput "${area_log_imports}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    precheck

    if [[ ${action-} == "subdivide" ]]; then
        createSubdividedAreas
    elif [[ ${action-} == "add-tag" ]] ; then
        addCbnaTag
    elif [[ ${action-} == "add-countries" ]] ; then
        addCountries
    else
        printError "Please, specify a right action (current: '${action-}') to run with script parameter --run.\n"
        printScriptUsage
    fi
    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function precheck() {
    printMsg "Check binaries and directories"

    printVerbose "Check all necessary binaries" ${Gra-}
    local readonly commands=("psql")
    checkBinary "${commands[@]}"

    printVerbose "Check if the raw data directory exists" ${Gra-}
    if [[ ! -d "${raw_dir}" ]]; then
        exitScript "Directory '${raw_dir}' does not exist."
    else
        printVerbose "Found directory '${raw_dir}': ${Gre-}OK" ${Gra-}
    fi
}

createSubdividedAreas() {
    printMsg "Create subdivided areas..."

    export PGPASSWORD="$db_pass"; \
        psql -h $db_host -U $db_user -d $db_name \
            -v areaSubdividedTableName="${area_subdivided_table_name}" \
            -v areaSubdividedTypesList="${area_subdivided_types_list}" \
            -f "${sql_dir}/subdivide_areas.sql"
}

addCbnaTag() {
    printMsg "Add CBNA TAG area..."

    export PGPASSWORD="$db_pass"; \
        psql -h $db_host -U $db_user -d $db_name \
            -v areaTagDeptCodesList="${area_tag_dept_codes_list}" \
            -f "${sql_dir}/add_cbna_tag.sql"
}

addCountries() {
    printMsg "Add countries areas..."

    cd  "${raw_dir}"
    local osm_ids_hash=$((0x$(sha1sum <<<"${area_country_osm_ids}"|cut -c1-8)))
    local normalized_json_file_path="${raw_dir}/${area_country_db_name}_${osm_ids_hash}.ewkt"
    if [[ ! -f "${normalized_json_file_path}" ]]; then
        local osm_boundaries_url=$(echo $area_country_url_tpl | sed -e "s/{apiKey}/${area_country_api_key}/")
        local osm_boundaries_url=$(echo $osm_boundaries_url | sed -e "s/{dbName}/${area_country_db_name}/")
        local osm_boundaries_url=$(echo $osm_boundaries_url | sed -e "s/{osmIds}/${area_country_osm_ids}/")
        curl --remote-name --remote-header-name --location --max-redirs -1 "${osm_boundaries_url}"
        gzip -d *.ewkt.gz
        local json_file_name=$(ls *.ewkt | grep "OSMB-" | tail -n 1)
        local json_file_path="${raw_dir}/${json_file_name}"
        mv "${json_file_path}" "${normalized_json_file_path}"
    fi

    local sql_file="${sql_dir}/add_countries.sql"
    export PGPASSWORD="$db_pass"; \
        sed "s#\${areaCountryEwktFilePath}#${normalized_json_file_path}#g" "${sql_file}" | \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v areaCountryDbName="${area_country_db_name}" \
            -f -
}

main "${@}"
