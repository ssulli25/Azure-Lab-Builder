# To include in your script, place in the same folder and then add
# SCRIPT_PATH=$(dirname "$0")
# source "$SCRIPT_PATH/common_functions.sh"

function timestamp {
  echo $(date "+%F %T")
}

function debug {
  if [[ ${DEBUG_OUTPUT} ]]; then
    echo "$(timestamp) DEBUG: $1" 1>&2
  fi
}

function info {
  echo "$(timestamp) INFO:  $1"
}

function error {
  echo "$(timestamp) ERROR: $1" 1>&2
}

# Used to check if a variable is defined or not
function require {
  if [ -z "${!1}" ]; then
    error "$1 is undefined"
    exit 1
  fi
}

# Encodes strings to be used as part of URLs
function url_encode {
  echo "${1}" | jq -Rr @uri
}
