
function get_date () {
    echo "$(date "+%F %T")"
}

function msg () {
    local _msg="$1"; shift
    echo " $(get_date) ==> $_msg"
}

function info () {
    local _msg="$1"; shift
    msg "INFO: $_msg"
}

function warning () {
    local _msg="$1"; shift
    msg "WARNING: $_msg"
}

function error () {
    local _msg="$1"; shift
    msg "ERROR: $_msg" >&2
}

function check_cmds() {
    local cmds="$@"
    local cmd_not_found=0
    for cmd in ${cmds[@]}; do
        command -v $cmd >/dev/null 2>&1 || {
            ((cmd_not_found++))
            error "Command '$cmd' not found"
        }
    done
    [[ "$cmd_not_found" -gt 0 ]] && return 1
    return 0
}

function find_env_aws_region() {
    # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
    [[ -n "$AWS_REGION" ]]                       && echo "$AWS_REGION" && return 0
    [[ -n "$AWS_DEFAULT_REGION" ]]               && echo "$AWS_DEFAULT_REGION" && return 0
    [[ -n "$AWS_CONFIGURE_DEFAULT_SSO_REGION" ]] && echo "$AWS_CONFIGURE_DEFAULT_SSO_REGION" && return 0
    [[ -n "$AWS_DEFAULT_SSO_REGION" ]]           && echo "$AWS_DEFAULT_SSO_REGION" && return 0
    
    echo "" && return 1
}