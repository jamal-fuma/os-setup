#!/bin/sh

read_private_content_to_file()
{
	local prompt="${1}"
	local filename="${2}"

	echo "${prompt}"
	read -e secret_text

	echo "${secret_text}" > "${filename}"
	chmod 600 ${filename}
}

mkdir_private()
{
	local private_dirname="${1}"

	# create_private_directory
	[ -d "$private_dirname" ] || \
        ( \
        mkdir -p "$private_dirname"; \
        chmod 700 "$private_dirname"; \
        );
}

create_gitpass_directory()
{
	# secret storage
	local gitpass_dirname="${1}"
	local gitpass_passwd_path="${gitpass_dirname}/passwd"
	local gitpass_salt_path="${gitpass_dirname}/salt"

	# create_gitpass_directory
	[ -d "$gitpass_dirname" ] \
		|| mkdir -p "$gitpass_dirname";

	# populate passwd
	[ -f "$gitpass_passwd_path" ] || \
		read_private_content_to_file "Gitpass: enter passwd" "${gitpass_passwd_path}"

	# populate salt
	[ -f "$gitpass_salt_path" ] || \
		read_private_content_to_file "Gitpass: enter salt" "${gitpass_salt_path}"
}

inject_smudge_clean_filters()
{
    # augment git/.config with smudge filters
	local dotfiles_dirname="${1}"
	local dotfiles_git_config_path="${dotfiles_dirname}/.git/config"

    # sed replacements
	local gitencrypt_dirname="${dotfiles_dirname}/gitencrypt"

    grep -q 'filter "openssl"' "${dotfiles_git_config_path}" || \
        sed -e "/@@_/{
s|@@_HOOKDIR_@@|${gitencrypt_dirname}|g;
}" >> "${dotfiles_git_config_path}" <<'EOS'
[filter "openssl"]
        smudge = @@_HOOKDIR_@@/smudge_filter_openssl
        clean  = @@_HOOKDIR_@@/clean_filter_openssl
[diff "openssl"]
        textconv = @@_HOOKDIR_@@/diff_filter_openssl
EOS
}

clone_dotfiles_repo()
{
	# paths
	local dotfiles_dirname="${1}"
	local dotfiles_install_log_path="${2}"

	# pull from github
	local dotfiles_url="https://github.com/jamal-fuma/dotfiles"
	local dotfiles_install_sh_path="${dotfiles_dirname}/install.sh"

	[ -d ${dotfiles_dirname} ] || \
		git clone "${dotfiles_url}" "${dotfiles_dirname}"

	# run the installer
	if [ ! -f "${dotfiles_install_log_path}" ] ;
    then
        /bin/sh "${dotfiles_install_sh_path}" | \
            tee "${dotfiles_install_log_path}" ;

        inject_smudge_clean_filters "${dotfiles_dirname}" | \
            tee -a "${dotfiles_install_log_path}" ;
    fi
}

setup_ssh_directory()
{
	local dotfiles_dirname="${1}"
	local dotfiles_ssh_config_path="${dotfiles_dirname}/ssh/config"

    printf "%s\n" "${dotfiles_ssh_config_path}"
}

help()
{
	echo "Beyond help you are";
}

main()
{
	gitpass_dirname="${HOME}/.gitpass"
	dotfiles_dirname="${HOME}/dotfiles"
	dotfiles_install_log_path="/tmp/dotfiles-install.log"
case $1 in
help)
		help
		;;
*)
		create_gitpass_directory  "${gitpass_dirname}";
		clone_dotfiles_repo "${dotfiles_dirname}" "${dotfiles_install_log_path}";
        setup_ssh_directory "${dotfiles_dirname}"
	;;
esac
}
main
