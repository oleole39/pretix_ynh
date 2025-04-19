#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

nodejs_version="22"
min_python_version_required=3.9
py_vshort="${min_python_version_required%.*}"


############################################
# Ensure mininum Python version is installed #
############################################

check_python_min_req() {
    local min_req_version=$1
 
    compare_format() { 
        printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); 
    }
    
    if command -v python$py_vshort &>/dev/null; then
        installed_version=$(python$py_vshort --version 2>/dev/null)
        installed_version=${installed_version#Python }
        if [ $(compare_format $installed_version) -ge $(compare_format $min_req_version) ]; then
            echo "Python version installed ($installed_version) satisfies $app requirement (>=$min_req_version)."
            export 
        else
            echo "Python installed ($installed_version) does not satisfy $app requirement (>=$min_req_version). Exiting..."
            exit 1
        fi
    else
        echo "Python is not installed. Exiting..."
        exit 1
    fi
}

# Example usage:
# check_python_min_req 3.9

#################################################
# Function to install a specific Python version #
#################################################

set_venv() {
    local venv_path=$1

    # Create a virtualenv with python installed by myynh_install_python():
    ynh_exec_as_app /usr/bin/python$py_vshort -m venv --upgrade-deps $venv_path

    # Print some version information:
    ynh_print_info "venv Python version: $($venv_path/bin/python$py_vshort -VV)"
    ynh_print_info "venv Pip version: $($venv_path/bin/python$py_vshort -m pip -V)"    
}

# Example usage:
# set_venv $install_dir/venv

#~ myynh_setup_log_file() {
    #~ mkdir -p "$(dirname "$log_file")"
    #~ touch "$log_file"

    #~ chown -c -R $app:$app "$log_path"
    #~ chmod -c u+rwx,o-rwx "$log_path"
#~ }

#~ myynh_fix_file_permissions() {
    #~ # /var/www/$app/
    #~ # static files served by nginx, so use www-data group:
    #~ chown -c -R "$app:www-data" "$install_dir"
    #~ chmod -c u+rwx,g+rx,o-rwx "$install_dir"

    #~ # /home/yunohost.app/$app/
    #~ chown -c -R "$app:$app" "$data_dir"
    #~ chmod -c u+rwx,g+rwx,o-rwx "$data_dir"
#~ }

#--- Next helpers copied from https://github.com/YunoHost-Apps/indico_ynh/blob/1a4be95bcfa0aac73252e648d3d5d692cc0c4bd9/scripts/_common.sh 
############################################################
# Function to lock a Redis database by setting a dummy key #
############################################################

redis_lock() {
    local db=$1
    redis-cli -n "$db" SET "ynh_lock" "locked" > /dev/null
}

# Example usage:
# redis_lock 1

#################################################################
# Function to unlock a Redis database by deleting the dummy key #
#################################################################

redis_unlock() {
    local db=$1
    redis-cli -n "$db" DEL "ynh_lock" > /dev/null
}

# Example usage:
# redis_unlock 1
