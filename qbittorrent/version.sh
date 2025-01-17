#!/usr/bin/env bash

set -o pipefail

dir_shell=$(cd $(dirname $0); pwd)
dir_myscripts=$(cd $(dirname $0); cd ../../myscripts; pwd)

cd $dir_shell

## 官方版本
qb_tag=$(curl -s --retry 5 --retry-delay 8 https://api.github.com/repos/qbittorrent/qBittorrent/tags)
ver_qb_official=$(echo $qb_tag | jq -r .[].name | grep -m1 -E "release-([0-9]\.?){3,4}$" | sed "s/release-//")
ver_qbbeta_official=$(echo $qb_tag | jq -r .[].name | grep -m1 -E "release-([0-9]\.?){3,4}[a-zA-Z]+.*" | sed "s/release-//")

## 本地版本
ver_qb_local=$(cat qbittorrent.version)
ver_qbbeta_local=$(cat qbittorrent-beta.version)

## 导入配置
. $dir_myscripts/notify.sh
. $dir_myscripts/my_config.sh

## 检测官方版本与本地版本是否一致，如不一致则发出通知
stable_build_mark=0
if [[ $ver_qb_official ]]; then
    if [[ $ver_qb_official != $ver_qb_local ]]; then
        echo "官方已升级qBittorrent版本至：$ver_qb_official"
        notify "qBittorrent已经升级" "当前官方版本: ${ver_qb_official}\n当前本地版本: ${ver_qb_local}"
        echo "$ver_qb_official" > qbittorrent.version
        stable_build_mark=1
    else
        echo "qBittorrent官方版本和本地一致，均为：$ver_qb_official"
    fi
fi

unstable_build_mark=0
if [[ $ver_qbbeta_official ]]; then
    if [[ $ver_qbbeta_official != $ver_qbbeta_local ]]; then
        echo "官方已升级qBittorrent beta版本至：$ver_qbbeta_official"
        notify "qBittorrent beta已经升级" "当前官方版本: ${ver_qbbeta_official}\n当前本地版本: ${ver_qbbeta_local}"
        echo "$ver_qbbeta_official" > qbittorrent-beta.version
        unstable_build_mark=1
    else
        echo "qBittorrent beta官方版本和本地一致，均为：$ver_qbbeta_official"
    fi
fi

## 需要更新时则重新构建
if [[ $stable_build_mark -eq 1 ]]; then
    ./buildx.sh -v$ver_qb_official -p3.14
fi

if [[ $unstable_build_mark -eq 1 ]]; then
    ./buildx.sh -v$ver_qbbeta_official -p3.14
fi
