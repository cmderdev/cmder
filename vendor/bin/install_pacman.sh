#!/usr/bin/env bash

# Based on: https://github.com/mcgitty/pacman-for-git
# My Fork: https://github.com/daxgames/pacman-for-git

export bin_source=${1:-https://github.com/daxgames/pacman-for-git/raw/refs/heads/main}

if [[ "$HOSTTYPE" == "i686" ]]; then
  pacman=(
    pacman-6.0.0-4-i686.pkg.tar.zst
    pacman-mirrors-20210703-1-any.pkg.tar.zst
    msys2-keyring-1~20210213-2-any.pkg.tar.zst
  )

 zstd=zstd-1.5.0-1-i686.pkg.tar.xz
 zstd_win=https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-v1.5.5-win32.zip
else
  pacman=(
    pacman-6.0.1-18-x86_64.pkg.tar.zst
    pacman-mirrors-20220205-1-any.pkg.tar.zst
    msys2-keyring-1~20220623-1-any.pkg.tar.zst
  )

  zstd=zstd-1.5.2-1-x86_64.pkg.tar.xz
  zstd_win=https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-v1.5.5-win64.zip
fi

echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo Downloading pacman files...
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
for f in "${pacman[@]}"; do
  echo "Running: curl -sLkf -o \"$HOME/Downloads/$f\" \"${bin_source}/$f\""
  curl -sLkf -o "$HOME/Downloads/$f" "${bin_source}/$f" || exit 1
done
echo -e "\n=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"

echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo Downloading zstd binaries...
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo "Running: curl -sLkf -o \"$HOME/Downloads/$zstd\" \"${bin_source}/$zstd\""
curl -sLkf -o "$HOME/Downloads/$zstd" "${bin_source}/$zstd" || exit 1
echo "Running: curl -sLkf -o \"$HOME/Downloads/$(basename \"${zstd_win}\")\" \"$zstd_win\""
curl -sLkf -o "$HOME/Downloads/$(basename "${zstd_win}")" "$zstd_win" || exit 1
echo -e "\n=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"

echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo Downloading pacman.conf...
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo "Running: curl -Lk https://raw.githubusercontent.com/msys2/MSYS2-packages/7858ee9c236402adf569ac7cff6beb1f883ab67c/pacman/pacman.conf"
curl -sLk https://raw.githubusercontent.com/msys2/MSYS2-packages/7858ee9c236402adf569ac7cff6beb1f883ab67c/pacman/pacman.conf -o /etc/pacman.conf || exit 1

pushd "$HOME/Downloads"
[[ -d "$(basename "${zstd_win}" | sed 's/\.zip$//')" ]] && \
  rm -rf "$(basename "${zstd_win}" | sed 's/\.zip$//')"
unzip "$HOME/Downloads/$(basename "${zstd_win}")"
export PATH="$PATH:$HOME/Downloads/$(basename "${zstd_win}" | sed 's/\.zip$//')"
popd
echo -e "\n=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"

cd /
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo Installing pacman files...
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo "Extracting zstd to /usr..."
tar x --xz -vf "$HOME/Downloads/$zstd" usr

for f in "${pacman[@]}"; do
  echo "Extracting $f to /usr and /etc..."
  tar x --zstd -vf "$HOME/Downloads/$f" usr etc 2>/dev/null
done
echo -e "\n=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"

echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo Initializing pacman...
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
mkdir -p /var/lib/pacman
ln -sf "$(which gettext)" /usr/bin/
pacman-key --init
pacman-key --populate msys2
pacman -Syu --noconfirm
echo -e "\n=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"

echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo Getting package versions for the installed Git release
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
t=$(grep -E 'mingw-w64-[ix_0-9]+-git ' /etc/package-versions.txt)
echo "Found package version line: $t"

curl --help >/dev/null 2>&1 || { echo "ERROR: curl is not installed properly."; exit 1; }

echo "Getting commit ID that matches '$t' from github pacman-for-git..."
t=$(curl -sLk "${bin_source}/version-tags.txt" | grep "$t")
echo "Full line from version-tags.txt: '$t'"

[[ "$t" == "" ]] && echo "ERROR: Commit ID not logged in github pacman-for-git." && exit 1
echo -e "Using commit ID: '${t##* }'"
echo -e "\n=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"

echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
echo Downloading package database files for the installed Git release
echo =-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
b=64 && [[ "$t" == *-i686-* ]] && b=32
URL="https://github.com/git-for-windows/git-sdk-$b/raw/${t##* }"
while read -r p v; do
  d="/var/lib/pacman/local/$p-$v"
  mkdir -p "$d"
  echo "$d"

  for f in desc files mtree; do
    curl -fsSL "$URL$d/$f" -o "$d/$f"
  done

  [[ ! -f "$d/desc" ]] && rmdir "$d" && echo "Missing $d"
done < /etc/package-versions.txt
echo -e "\n=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n"
