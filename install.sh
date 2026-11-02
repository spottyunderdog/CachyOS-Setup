#!/bin/env bash
getLatestReleaseVersion() {
	url=$1
	wget --spider "$url" &> log.txt
	url=${url%"latest"}tag/v
	
	file="log.txt"
	while read -r line; do

		case "$line" in
			*"$url"*) lineOut=$line; break;;	
		esac
	done<$file
	rm log.txt

	for item in $lineOut; do
		case "$item" in
			$url*) urlOut=$item; break;;
		esac
	done

	version=${urlOut#"$url"}
	echo $version
}


echo "Setting Up Chaotic AUR"

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo "[chaotic-aur]" | sudo tee -a /etc/pacman.conf
echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf

echo "Installing pacman packages"
sudo pacman -Syu --noconfirm
sudo pacman $(cat ./packages.txt) --needed --noconfirm

echo "Installing flatpaks"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.spotify.Client
flatpak install flathub dev.deedles.Trayscale
flatpak install flathub org.jellyfin.JellyfinDesktop

echo "Installing papirus icons"
wget -qO- https://git.io/papirus-icon-theme-install | sh

echo "Installing tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo "fetching & installing r2modman"
version=$(getLatestReleaseVersion https://github.com/ebkr/r2modmanPlus/releases/latest)
wget https://github.com/ebkr/r2modmanPlus/releases/download/v$version/r2modman-$version.pacman
sudo pacman -U r2modman-$version.pacman

echo "fetching & installing subtitle edit"
version=$(getLatestReleaseVersion https://github.com/SubtitleEdit/subtitleedit/releases/latest)
wget https://github.com/SubtitleEdit/subtitleedit/releases/download/v$version/SubtitleEdit-linux-x64.flatpak 
flatpak install SubtitleEdit-linux-x64.flatpak --system --or-update --noninteractive


echo "Enabling needed system service for Podman and thermald"
sudo systemctl enable --now thermald.service
systemctl --user enable podman-restart.service
sudo loginctl enable-linger $USER

echo "Setting up qemu services"
# Force libvirt to use iptables
echo 'firewall_backend = "iptables"' | sudo tee -a /etc/libvirt/network.conf
# This will add the user to the "libvirt" group so they can use it:
sudo usermod -aG libvirt $USER
# LXC backend (optional, for linux containers, enabling both backends does not conflict):
systemctl enable --now libvirtd.service
# QEMU backend (for VMs):
systemctl enable --now libvirtd.socket
# This will bring Internet up in a VM whenever one starts:
sudo virsh net-autostart default
# And to enable the entire VM network to have unfettered transit: (You should consider if you need more granular firewall rules based on your use case and security posture)
sudo ufw route allow from 192.168.122.0/24
