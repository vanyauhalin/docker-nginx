#!/bin/sh

main() {
	case "$1" in
	"help") help ;;
	"version") version ;;
	*) setup ;;
	esac
}

version() {
	echo "0.0.1"
}

help() {
	echo "Usage: setup.sh [command]"
	echo
	echo "Commands:"
	echo "  help      Display this help message"
	echo "  version   Display the version of this script"
}

setup() {
	answer=""
	ask "? Create a new user account? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		useradd --create-home vanyauhalin
		gpasswd --add vanyauhalin wheel
		passwd vanyauhalin
	fi

	echo

	answer=""
	ask "? Enable passwordless sudo for wheel group? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	fi

	echo

	answer=""
	ask "? Enable ssh key-based authentication? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		# ssh-keygen -t ed25519 -C "vanyauhalin@gmail.com" -f "$HOME/.ssh/key"
		# cat "$HOME/.ssh/key.pub" | pbcopy
		answer=""
		ask "? Enter the public key: " answer
		mkdir "$HOME/.ssh"
		chmod 700 "$HOME/.ssh"
		echo "$answer" >> "$HOME/.ssh/authorized_keys"
		chmod 600 "$HOME/.ssh/authorized_keys"
		service ssh restart
	fi

	echo

	answer=""
	ask "? Change system locale to en_US? (y/N)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		locale-gen en_US.UTF-8
		localectl set-locale LANG=en_US.UTF-8
	fi

	echo

	answer=""
	ask "? Change system time to UTC? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		timedatectl set-timezone UTC
	fi

	echo

	answer=""
	ask "? Enable system time synchronization? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		timedatectl set-ntp true
	fi

	echo

	answer=""
	ask "? Synchronize hardware clock with system time? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		hwclock --systohc
	fi

	echo

	answer=""
	ask "? Update system packages? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		rm /var/cache/pacman/pkg/*
		rm -rf /etc/pacman.d/gnupg
		pacman-key --init
		pacman-key --populate
		pacman -S archlinux-keyring
		pacman -Syu
	fi

	echo

	answer=""
	ask "? Hide last login information? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		sed --in-place 's/^#PrintLastLog yes$/PrintLastLog no/' /etc/ssh/sshd_config
		service ssh restart
	fi

	echo

	answer=""
	ask "? Simplify shell prompt? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		echo "PS1='$ '" >> "$HOME/.bashrc"
	fi

	echo

	answer=""
	ask "? Install Make? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		pacman -S make
	fi

	echo

	answer=""
	ask "? Install Git? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		pacman -S git
	fi

	echo

	answer=""
	ask "? Install GitHub CLI? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		pacman -S github-cli
	fi

	answer=""
	ask "? Generate a new SSH key for GitHub? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		ssh-keygen -t ed25519 -C "vanyauhalin@gmail.com" -f "$HOME/.ssh/github.com"
		printf "%b" "Host github.com\n	IdentityFile \"$HOME/.ssh/github.com\"\n" >> "$HOME/.ssh/config"
	fi

	echo

	answer=""
	ask "? Install Docker? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		pacman -S docker
		systemctl start docker.service
		systemctl enable docker.service
		gpasswd --add "$USER" docker
		pacman -S docker-buildx
		pacman -S docker-compose
	fi

	echo

	answer=""
	ask "? Install Backblaze B2 CLI? (Y/n)" answer
	if [ "$answer" = "" ] || [ "$answer" = "y" ]; then
		curl --location https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux/ --output /usr/local/bin/b2
		chmod +x /usr/local/bin/b2
	fi
}

ask() {
	printf "%s " "$1"
	read -r "$2"
}

main "$@"
