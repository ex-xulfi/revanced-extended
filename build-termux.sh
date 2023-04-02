#!/usr/bin/env bash

set -euo pipefail

pr() { echo -e "\033[0;32m[+] ${1}\033[0m"; }
ask() {
	local y
	for ((n = 0; n < 3; n++)); do
		pr "$1"
		if read -r y; then
			if [ "$y" = y ]; then
				return 0
			elif [ "$y" = n ]; then
				return 1
			fi
		fi
		pr "Asking again..."
	done
	return 1
}

CFG=config.toml

if [ ! -f ~/.rvmm_"$(date '+%Y%m')" ]; then
	pr "Setting up environment..."
	yes "" | pkg update -y && pkg install -y openssl git wget jq openjdk-17 zip
	: >~/.rvmm_"$(date '+%Y%m')"
fi

if [ -f build.sh ]; then cd ..; fi
if [ -d revanced-extended ]; then
	pr "Checking for revanced-extended updates"
	git -C revanced-extended fetch
	if git -C revanced-extended status | grep -q 'is behind'; then
		pr "revanced-extended already is not synced with upstream."
		pr "Cloning revanced-extended. config.toml will be preserved."
		cp -f revanced-extended/config*toml .
		rm -rf revanced-extended
		git clone https://github.com/ex-xulfi/revanced-extended.git --recurse --depth 1
		mv -f config*toml revanced-extended/
	fi
else
	pr "Cloning revanced-extended."
	git clone https://github.com/ex-xulfi/revanced-extended.git --recurse --depth 1
	sed -i '/^enabled.*/d; /^\[.*\]/a enabled = false' revanced-extended/config*toml
fi
cd revanced-extended
chmod +x build.sh build-termux.sh

if ! ask "Select config (y=revanced n=revanced extended)"; then
	CFG=config-rv-ex.toml
fi
if ask "Do you want to open the config for customizations? [y/n]"; then
	nano $CFG
fi
if ! ask "Setup is done. Do you want to start building? [y/n]"; then
	exit 0
fi
./build.sh $CFG

echo "Running repack.sh"
curl -sSLO https://raw.githubusercontent.com/NoName-exe/revanced-misc-stuff/master/scripts/repack.sh && chmod +x repack.sh && ./repack.sh && rm -rf ./repack.sh

#We are in 'cd build'

PWD=$(pwd)
mkdir -p ~/storage/downloads/revanced-extended
for op in *; do
	[ "$op" = "*" ] && continue
	mv -f "${PWD}/${op}" ~/storage/downloads/revanced-extended/"${op}"
done

pr "Outputs are available in /sdcard/Download/revanced-extended folder"
