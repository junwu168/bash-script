#!/bin/bash

function show_help
{
    echo "Usage:"
    echo "    $(basename ${BASH_SOURCE[0]}) (--install|--reinstall)"
    echo "    $(basename ${BASH_SOURCE[0]}) --uninstall"
    echo ""
}

function run
{
    local mode=''
    local uninstall=false
    #local default_repo_url=http://dl.rockylinux.org/pub
    #local repo_url=$default_repo_url
    
    # proceed the parameters one by one
    while [[ $# -gt 0 ]]; do case $1 in 
    --install)
            mode=install
        ;;
    
    --uninstall)
            mode=uninstall
        ;;
    
     --reinstall)
            mode=reinstall
        ;;
    
    -h|--help|help)
            show_help; exit 1
        ;;

    esac; shift; done # "shift" means move the next parameter to $1

    [[ "$(id -u)" == 0 ]] ||
        die "this script must be run as root"

    #
    # detect OS
    #

    [[ -f /etc/os-release ]] ||
        die "cannot find /etc/os-release file"

    [[ "$(cat /etc/os-release)" =~ [[:space:]]ID=\"?([a-zA-Z0-9-]+)\"?[[:space:]] ]] ||
        die "cannot extract OS name from /etc/os-release file"
    local os_name=${BASH_REMATCH[1]}

    [[ "$(cat /etc/os-release)" =~ [[:space:]]VERSION_ID=\"?(([0-9]+)(\.[0-9]+)?)\"?[[:space:]] ]] ||
        die "cannot extract OS version from /etc/os-release file"
    local os_version=${BASH_REMATCH[1]}
    local os_version_x=${BASH_REMATCH[2]}
    local os_version_y=${BASH_REMATCH[3]}

    local os_arch=$(uname -p)
    [[ -n "$os_arch" ]] ||
        die "cannot determine OS architecture"

    case $os_name in
        centos)
            install_type=rhel
            repo_os_name=centos
        ;;

        rocky)
            install_type=rhel
            repo_os_name=rocky
        ;;

        ubuntu)
            deb_os_name_suffix=ubuntu
            install_type=deb
            repo_os_name=ubuntu
        ;;

        *)
            die "unsupported OS $os_name"
        ;;
    esac

    #
    # OS-specific polymorphism
    #

    if [[ $install_type == rhel ]]; then
        if (( os_version_x >= 8 )); then
            function yum_or_dnf { dnf "$@"; }
        else
            function yum_or_dnf { yum "$@"; }
        fi

        function install_packages_low_level { rpm -Uvh "$@"; }
        function install_packages           { yum_or_dnf -y install "$@"; }
        function uninstall_packages         { yum_or_dnf -y remove "$@"; }
        function update_repo                { yum_or_dnf clean all; }

    elif [[ $install_type == deb ]]; then
        function install_packages_low_level { dpkg -i "$@"; }
        function install_packages           { apt -y install "$@"; }
        function uninstall_packages         { apt -y purge "$@"; }
        function update_repo                { apt update; }

    else
        die "unsupported install_type $install_type"
    fi


    #
    # install, uninstall, reinstall, configure
    #

    if [[ -z "${mode}" ]]; then
        mode=install
    fi

    if [[ ${mode} =~ ^(uninstall|reinstall)$ ]]; then
        uninstall_packages "*httpd*" || die
    fi

    if [[ "${mode}" =~ ^(install|reinstall)$ ]]; then
        update_repo ||
            die "Something wrong with your repository"

        install_packages httpd ||
            die "cannot install httpd packages"
    fi
}

function die
{
    [[ -n "$@" ]] && >&2 echo -e "$@"
    exit 1
}

run "$@"
