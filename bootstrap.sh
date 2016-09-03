#!/bin/sh -x

read_private_content_to_file()
{
	local prompt="${1}"
	local filename="${2}"

	echo "${prompt}"
	read -e secret_text

	echo "${secret_text}" > "${filename}"
	chmod 600 ${filename}
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

    grep -q 'filter\s+"openssl"' "${dotfiles_git_config_path}" || \
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
	# user setup
	dotfiles_dirname="${HOME}/dotfiles"
	dotfiles_url="https://github.com/jamal-fuma/dotfiles"
	dotfiles_install_sh_path="${dotfiles_dirname}/install.sh"
	dotfiles_install_log_path="/tmp/dotfiles-install.log"

	# pull from github
	[ -d ${dotfiles_dirname} ] || \
		git clone "${dotfiles_url}" "${dotfiles_dirname}"

	# run the installer
	[ ! -f "${dotfiles_install_log_path}" ]  && \
		( /bin/sh "${dotfiles_install_sh_path}" | tee "${dotfiles_install_log_path}" )
}

help()
{
	echo "Beyond help you are";
}

main()
{
case $1 in
help)
		help
		;;
*)
		create_gitpass_directory;
		clone_dotfiles_repo;
	;;
esac
}
main
