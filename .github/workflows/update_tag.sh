#!/bin/bash
git config --local user.name "github-actions[bot]"
git config --local user.email "41898282+github-actions[bot]@users.noreply.github.com"

TagRemote=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases | jq -r '.[] | select(.prerelease == false) | .tag_name' | head -n1)
TagDevRemote=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases | jq -r '.[] | select(.prerelease == true) | .tag_name' | head -n1)

TagLocal=$(cat Tag | head -n1)
TagDevLocal=$(cat TagDev | head -n1)

echo "Release (local): ${TagLocal}"
echo "Release (remote): ${TagRemote}"
echo "Dev (local): ${TagDevLocal}"
echo "Dev (remote): ${TagDevRemote}"

if [ "${TagLocal}" != "${TagRemote}" ]; then
  echo ${TagRemote} > ./Tag
  git commit -am "Update version to ${TagRemote}"
  git push -v --progress
fi

if [ "${TagDevLocal}" != "${TagDevRemote}" ]; then
  echo ${TagDevRemote} > ./TagDev
  git commit -am "Update dev version to ${TagDevRemote}"
  git push -v --progress
fi
