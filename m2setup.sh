#!/usr/bin/env bash
# Magento 2 setup
#
#   File: m2setup.sh
#
#   Description: Create magento 2 project + install

readonly VERSION="1.0.1"
readonly SCRIPT=${0##*/}
readonly USAGE="\
M2Setup (v$VERSION)

Global Commands:
  $SCRIPT <command>
------------------------------
  -h, --help         display this help message
  --test             enable test mode
  --version          display the M2Setup script's version
------------------------------
"

ACTION=$1; shift
MODE="normal"

# Handle "--help" command
if [ "$ACTION" = "--help" -o "$ACTION" = "-h" ]; then

  echo -e "$USAGE"
  exit 0

# Handle "--test" command
elif [ "$ACTION" = "--test" ]; then

  MODE="test"

# Handle "--version" command
elif [ "$ACTION" = "--version" ]; then

  echo "M2Setup: $VERSION"
  exit 0

fi

readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

CURRENT_SYSTEM="UNKNOWN"

readonly SUPPORTED_OS=("BSD" "GNU")
readonly ARR_SERVER_TYPES=("Apache" "Nginx")
readonly ARR_APACHE_VERSIONS=("2.2" "2.4")
readonly ARR_NGINX_VERSIONS=("1.8>x.x")
readonly ARR_DB_TYPES=("mysql")
readonly ARR_DB_VERSIONS=("5.6>x.x")
readonly ARR_PHP_VERSIONS=("5.5.22>5.5.x" "5.6.0>5.6.x" "7.0.2" "7.0.3" "7.0.4" "7.0.6") # Known issue with PHP 7.0.5
readonly ARR_PHP5_EXTS=("curl" "gd" "ImageMagick 6.3.7>x.x.x" "intl" "mbstring" "mcrypt" "mhash" "openssl" "PDO/MySQL"
 "SimpleXML" "soap" "xml" "xsl" "zip")
readonly ARR_PHP7_EXTS=("json" "iconv")

readonly E_OS_TYPE="OS not supported!"
readonly E_DETECT_PHP="Cannot detect PHP!"
readonly E_VALIDATE_PHP="Cannot validate PHP!"
readonly E_VERSION_PHP="Cannot detect PHP version!"
readonly E_SERVER_TYPE="Cannot detect server type!"
readonly E_SERVER_VERSION="Cannot detect server version!"

readonly EXT_VALIDATE=validate.php

ERROR_EXISTS_PHP_DETECT=0;

echo "Running in ${MODE} mode."

#######################################
# Print error
#
# Usage:
#   fn_error "An error occurred."
# Globals:
#   None
# Arguments:
#   (string) error
# Returns:
#   None
#######################################
fn_error ()
{
  error=$1

  if [[ -n ${error} ]]; then
    echo -e "${RED}Error - ${error}${NC}"
  fi
}

#######################################
# Validate system
#
# Usage:
#   fn_if_nix gnu
# Global:
#   OSTYPE
#   CURRENT_SYSTEM
# Arguments:
#   (string) system
# Returns:
#   None
#######################################
fn_validate_system ()
{
  case "$OSTYPE" in
    *linux*|*hurd*|*msys*|*cygwin*|*sua*|*interix*) CURRENT_SYSTEM="GNU";;
    *bsd*|*darwin*) CURRENT_SYSTEM="BSD";;
    *sunos*|*solaris*|*indiana*|*illumos*|*smartos*) CURRENT_SYSTEM="SUN";;
  esac

  echo -e "${YELLOW}OS Type: ${NC}${OSTYPE}"
  echo -e "${YELLOW}System: ${NC}${CURRENT_SYSTEM}"

  # Check if OS supported
  if [[ ! " ${SUPPORTED_OS[@]} " =~ " ${CURRENT_SYSTEM} " ]]; then
    # If not supported, display error and exit
    fn_error "$E_OS_TYPE" && exit 1
  fi
}

#######################################
# Get bin path for validation
#
# Usage:
#   fn_get_bin_path_for_validate php fn_validate_php
# Globals:
#   None
# Arguments:
#   (command) search
#   (function) callback
# Returns:
#   bool
#######################################
fn_get_bin_path_for_validate ()
{
    search=$1
    callback=$2

    if which $1 > /dev/null 2>&1; then
        local path="$(which $1)"
        ${callback} "$path"
        return 1
    fi

    return 0
}

#######################################
# Validate PHP
#
# Usage:
#   fn_validate_php "bin_path"
# Globals:
#   None
# Arguments:
#   string bin_path
# Returns:
#   None
#######################################
fn_validate_php ()
{
  if [ -z "$1" ]; then
    # If PHP bin path empty, display error and exit
    fn_error "$E_VALIDATE_PHP" && exit 1
  else
    fn_run_external_validation $1

    exit;

    local out_version="$($1 -v)"

    if [[ -n ${out_version} ]]; then
      # Use internal expression to get version
      local version=${out_version:4:5}

      #version="5.5.22>5.5.x"
      version="5.5.22"

      # Check version
      if [[ " ${ARR_PHP_VERSIONS[@]} " =~ " ${version} " ]]; then
        output="${version}${GREEN} OK${NC}"
      else
        output="${version}${RED} NOT OK${NC}"
      fi
    else
      # If cant detect version, fetch error for output
      output=$(fn_error "$E_VERSION_PHP")
    fi

    echo -e "${YELLOW}PHP Version:${NC} ${output}"
    echo -e ""
  fi
}

fn_run_external_validation ()
{
  local php_bin=$1

  # Absolute path of current script
  local absolute_path=`echo $0 | sed 's/m2setup\.sh//g'`

  if ! ps auxwww | grep "$absolute_path""$EXT_VALIDATE" | grep -v grep 1>/dev/null 2>/dev/null ; then
      "$php_bin" "$absolute_path""$EXT_VALIDATE"
  fi
}

# 1. Validate system
echo -e "${BLUE}Validating system...${NC}\n"
fn_validate_system

# 2. Validate PHP
echo -e "${BLUE}Validating PHP...${NC}\n"
if fn_get_bin_path_for_validate php fn_validate_php; then
  # If PHP undetected, display error and exit
  fn_error "$E_DETECT_PHP" && exit 1
fi

# 3. Validate server
#fn_validate_server

exit 1;

## Most of below is deprecated!!!

# Pre check system requirements
function fn_pre_check_setup
{
    # Check OS Type and set vars out_os_type, out_server_path, out_server_ver
    # Can also use unamestr=`uname` if required instead of global OSTYPE
    if [[ "$OSTYPE" == "linux-gnu" ]]; then

        # Linux

        # Determine if apache installed
        if which httpd > /dev/null 2>&1; then
            out_server_path="$(which httpd)"

            # Check apache
            fn_check_apache

        # Determine if apache installed
        elif which apache > /dev/null 2>&1; then
            out_server_path="$(which apache)"

            # Check apache
            fn_check_apache

        # Determine if nginx installed
        elif which nginx > /dev/null 2>&1; then
            out_server_path="$(which nginx)"

            # Check apache
            fn_check_nginx
        fi

    elif [[ "$OSTYPE" == "darwin"* ]]; then

        # Mac OSX

        # Determine if apache installed
        if which httpd > /dev/null 2>&1; then
            out_server_path="$(which httpd)"

            # Check apache
            fn_check_apache

        # Determine if apache installed
        elif which apache > /dev/null 2>&1; then
            out_server_path="$(which apache)"

            # Check apache
            fn_check_apache

        # Determine if apache installed
        elif which apache2 > /dev/null 2>&1; then
            out_server_path="$(which apache2)"

            # Check apache
            fn_check_apache

        # Determine if nginx installed
        elif which nginx > /dev/null 2>&1; then
            out_server_path="$(which nginx)"

            # Check apache
            fn_check_nginx
        else
            pre_check_has_errors=1
        fi



        # Check mysql

        # Check PHP version

        # Check PHP extensions

        # Check PHP memory_limit

        # Check PHP OPcache

    elif [[ "$OSTYPE" == "cygwin" ]]; then

        # POSIX compatibility layer and Linux environment emulation for Windows
        out_os_type = $OSTYPE

    elif [[ "$OSTYPE" == "msys" ]]; then

        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        out_os_type = $OSTYPE

    elif [[ "$OSTYPE" == "win32" ]]; then

        # I'm not sure this will work
        out_os_type = $OSTYPE

    elif [[ "$OSTYPE" == "freebsd"* ]]; then

        # Linux
        out_os_type = $OSTYPE

    else

        # Unsupported OS
        pre_check_has_errors=1

    fi

    echo -e "${YELLOW}OS:${NC} ${OSTYPE}"
    echo -e "${YELLOW}Server:${NC} ${server_type_result}"
    echo -e "${YELLOW}Server Version:${NC} ${server_version_result}"
    echo -e ""
}

# Check apache
function fn_check_apache
{
    if [ -z "$out_server_path" ]; then
        pre_check_has_errors=1
    else
        out_server_ver="$(${out_server_path} -v)"

        if [[ -n ${out_server_ver} ]]; then
            # Use internal expression to fetch server vars we need
            server_type=${out_server_ver:16:6}
            server_ver=${out_server_ver:23:3}

            # Check server type
            if [[ " ${ARR_SERVER_TYPES[@]} " =~ " ${server_type} " ]]; then
                server_type_result="${server_type}${GREEN} OK${NC}"
            else
                server_type_result="${server_type}${RED} NOT OK${NC}"
                pre_check_has_errors=1
            fi

            # Check server ver
            if [[ " ${ARR_APACHE_VERSIONS[@]} " =~ " ${server_ver} " ]]; then
                server_version_result="${server_ver}${GREEN} OK${NC}"
            else
                server_version_result="${server_ver}${RED} NOT OK${NC}"
                pre_check_has_errors=1
            fi
        else
            pre_check_has_errors=1
        fi
    fi
}

# Check nginx
function fn_check_nginx
{
    if [ -z "$out_server_path" ]; then
        pre_check_has_errors=1
    else
        echo -ne "${YELLOW}TODO: implement nginx check.${NC}"
    fi

    echo -ne "${YELLOW}TODO: implement nginx check.${NC}"
}

# Display input to continue setup
function fn_error_continue_setup_input
{
    echo -ne "${RED}Errors were detected. Continue Setup [y/n]: ${NC}"
    read continue_setup_value

    if [ "$continue_setup_value" != "y" ]; then
        echo "Exiting."
        exit 1
    fi

    echo -e ""
}

# Display input to use project path
function fn_use_current_dir_input
{
    INSTALL_PATH_VALUE=$(pwd)"/"
    echo -ne "${YELLOW}Install in current directory '${INSTALL_PATH_VALUE}' [y/n]: ${NC}\n"
    read use_current_dir_value

    if [ "$use_current_dir_value" != "y" ]; then
        fn_set_current_install_path_input
    fi
}

# Display input to use project path
function fn_set_current_install_path_input
{
    echo -ne "${YELLOW}New install directory (include prefix and suffix '/'): ${NC}"
    read new_install_path

    while [ "$new_install_path" = "" ]; do
        echo -e "${RED}ERROR: The install directory can not be empty!${NC}"
        fn_set_current_install_path_input
    done

    while [ ! -d "$new_install_path" ]; do
        echo -e "${RED}ERROR: The install directory '${new_install_path}' does not exist!${NC}"
        fn_set_current_install_path_input
    done

    while [ "$new_install_path" = "/" ]; do
        echo -e "${RED}ERROR: The install directory can not be root!${NC}"
        fn_set_current_install_path_input
    done

    INSTALL_PATH_VALUE="$new_install_path"
}

# Display input for project name
function fn_project_name_input
{
    echo -ne "${YELLOW}Magento 2 Project Name: ${NC}\n"
    read PROJECT_NAME_VALUE

    while [ "$PROJECT_NAME_VALUE" = "" ]; do
        echo -e "${RED}ERROR: The project name can not be empty!${NC}"
        fn_project_name_input
    done

    TRUE_INSTALL_PATH_VALUE="$INSTALL_PATH_VALUE""$PROJECT_NAME_VALUE"

    while [ -d "$TRUE_INSTALL_PATH_VALUE" ]; do
        echo -e "${RED}ERROR: The project name already exist!${NC}"
        fn_project_name_input
    done
}

# Composer create-project
function fn_composer_create_project
{
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition "$TRUE_INSTALL_PATH_VALUE"
}

# Create .gitignore in project folder
function fn_create_git_ignore
{
cat > "$TRUE_INSTALL_PATH_VALUE"/.gitignore << EOF
# IDE
/.buildpath
/.cache
/.metadata
/.project
/.settings
atlassian*
/nbproject
/.idea
/.gitattributes

# Magento
/app/code/Magento
/app/design/*/Magento
/app/etc
/app/i18n/magento
/app/*.*

/bin

/dev/shell

/dev/tests/*/framework
/dev/tests/*/testsuite/Magento
/dev/tests/*/tmp
/dev/tests/*/etc
/dev/tests/*/*.*
/dev/tests/*.*
/dev/tests/api-functional/config
/dev/tests/api-functional/_files/Magento
/dev/tests/js/JsTestDriver/framework
/dev/tests/js/JsTestDriver/testsuite/lib
/dev/tests/js/JsTestDriver/testsuite/mage
/dev/tests/js/JsTestDriver/*.*
/dev/tests/js/jasmine/assets
/dev/tests/js/jasmine/spec_runner
/dev/tests/js/jasmine/tests/app/code/Magento
/dev/tests/js/jasmine/tests/lib/mage
/dev/tests/js/jasmine/*.*
/dev/tests/performance
/dev/tests/functional/lib/Magento
/dev/tests/functional/tests/app/Magento
/dev/tests/functional/testsuites/Magento
/dev/tests/functional/utils

/dev/tools/Magento
/dev/tools/grunt
/dev/tools/*.*
/tools

/dev/*.*

/lib

/pub

/setup

/var

/vendor

/phpserver

/update

/dev

/node_modules

/*.*
!.gitignore
!/composer.json
!/composer.lock
!/README.md
!/app/etc/config.php

/sitemap

EOF
}

echo -e "${BLUE}Checking system requirements...${NC}\n"
fn_pre_check_setup

if [[ "$pre_check_has_errors" == 1 ]]; then
    fn_error_continue_setup_input
fi

echo -e "${BLUE}Preparing install...${NC}\n"

fn_use_current_dir_input

fn_project_name_input

# REVIEW HERE

echo -e "\n${BLUE}Review...${NC}\n"
echo -e "${YELLOW}Install path is '${TRUE_INSTALL_PATH_VALUE}'${NC}\n"

if [ ! "$MODE" == "test" ]; then
    fn_composer_create_project

    fn_create_git_ignore
fi

echo -e "${GREEN}Complete!${NC}\n"

exit 0