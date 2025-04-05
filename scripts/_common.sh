#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

py_version=3.11.2 #pretix asks for 3.9 and newer so let's stick with default python YNH version as long as possible
py_vshort="${py_version%.*}"

#################################################
# Function to install a specific Python version #
#################################################

set_venv() {
    local venv_path=$1

    # Create a virtualenv with python installed by myynh_install_python():
    ynh_exec_as_app /usr/local/bin/python$py_vshort -m venv --upgrade-deps $venv_path

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
#################################################
# Function to install a specific Python version #
#################################################

install_python() {
    local python_version=$1

    if [[ -z "$python_version" ]]; then
        echo "Usage: install_python <version>"
        return 1
    fi

    echo "Installing Python $python_version..."

    # Download and extract Python source
    local python_src="Python-$python_version"
    local python_tar="$python_src.tgz"
    local python_url="https://www.python.org/ftp/python/$python_version/$python_tar"

    wget "$python_url" -O "/tmp/$python_tar" 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Failed to download Python $python_version. Check the version number."
        return 1
    fi

    cd /tmp || return 1
    tar -xvf "$python_tar"
    cd "$python_src" || return 1

    # Compile and install Python
    ./configure --enable-optimizations 2>&1 
    if [[ $? -ne 0 ]]; then
        echo "Configuration failed."
        return 1
    fi

    make -j$(nproc) 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Build failed."
        return 1
    fi

    make altinstall 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Installation failed."
        return 1
    fi

    # Verify installation
    if command -v "python${python_version%.*}" &>/dev/null; then
        echo "Python $python_version installed successfully."
    else
        echo "Python $python_version installation failed."
        return 1
    fi

    # Clean up
    cd ..
    ynh_safe_rm "/tmp/$python_src" 
    ynh_safe_rm "/tmp/$python_tar"
}

# Example usage
# install_python 3.12.7

###################################################
# Function to uninstall a specific Python version #
###################################################

uninstall_python() {
    local python_version=$1
    local py_vshort="${py_version%.*}" 

    if [[ -z "$python_version" ]]; then
        echo "Usage: uninstall_python <version>"
        return 1
    fi

    echo "Uninstalling Python $python_version..."

    # Remove binaries
     ynh_safe_rm "/usr/local/bin/python${py_vshort}"

    # Remove libraries
     ynh_safe_rm "/usr/local/lib/python${py_vshort}"
     
    # Remove from alternatives
     update-alternatives --remove python3 "/usr/local/bin/python${py_vshort}" 2>/dev/null

    # Verify uninstallation
    if command -v "python${python_version}" &>/dev/null; then
        echo "Python $python_version was not completely removed."
        return 1
    else
        echo "Python $python_version uninstalled successfully."
    fi
}

# Example usage:
# uninstall_python 3.12

############################################
# Check if Python $py_version is installed #
############################################

check_python() {
if command -v python$py_vshort &>/dev/null; then
    # Verify the version
    installed_version=$(python$py_vshort --version 2>/dev/null)
    if [[ $installed_version == "Python $py_version" ]]; then
        echo "Python $py_version is already installed."
    else
        echo "Python $py_vshort is installed but not version $py_version."
        install_python $py_version
    fi
else
    echo "Python $py_version is not installed."
    install_python $py_version
fi
}

# Example usage:
# check_python 3.12

############################################
# Function to lock a Redis database by setting a dummy key
############################################

redis_lock() {
    local db=$1
    redis-cli -n "$db" SET "ynh_lock" "locked" > /dev/null
}

# Example usage:
# redis_lock 1

############################################
# Function to unlock a Redis database by deleting the dummy key
############################################

redis_unlock() {
    local db=$1
    redis-cli -n "$db" DEL "ynh_lock" > /dev/null
}

# Example usage:
# redis_unlock 1
