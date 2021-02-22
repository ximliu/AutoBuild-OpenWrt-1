#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Functions

GET_TARGET_INFO() {
	Home=${GITHUB_WORKSPACE}/openwrt
	echo "Home Path: ${Home}"
	[ -f ${GITHUB_WORKSPACE}/Openwrt.info ] && . ${GITHUB_WORKSPACE}/Openwrt.info
	Default_File="package/lean/default-settings/files/zzz-default-settings"
	Author="${Author}"
	Source="${Source}"
	[ -f ${Default_File} ] && Lede_Version="$(egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ${Default_File})"
	[[ -z ${Lede_Version} ]] && Lede_Version="Openwrt"
	Openwrt_Version="${Lede_Version}-${Compile_Date}"
	x86_Test="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/CONFIG_TARGET_(.*)_DEVICE_(.*)=y/\1/')"
	if [[ "${x86_Test}" == "x86_64" ]];then
		TARGET_PROFILE="x86_64"
	else
		TARGET_PROFILE="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')"
	fi
	[[ -z "${TARGET_PROFILE}" ]] && TARGET_PROFILE="${Default_Device}"
	case "${TARGET_PROFILE}" in
	x86_64)
		grep "CONFIG_TARGET_IMAGES_GZIP=y" ${Home}/.config
		if [[ ! $? -ne 0 ]];then
			Firmware_sfx="img.gz"
		else
			Firmware_sfx="img"
		fi
	;;
	*)
		Firmware_sfx="bin"
	;;
	esac
	TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)"
	TARGET_SUBTARGET="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)"
	Github_Repo="$(grep "https://github.com/[a-zA-Z0-9]" ${GITHUB_WORKSPACE}/.git/config | cut -c8-100)"
	AutoBuild_Info=${GITHUB_WORKSPACE}/openwrt/package/base-files/files/etc/openwrt_info
}

Diy_Part1() {
	Diy_Core
	GET_TARGET_INFO
	Replace_File Customize/uhttpd.po feeds/luci/applications/luci-app-uhttpd/po/zh-cn
	Replace_File Customize/webadmin.po package/lean/luci-app-webadmin/po/zh-cn
	Replace_File Customize/mwan3.config package/feeds/packages/mwan3/files/etc/config mwan3
	if [[ "${INCLUDE_Enable_FirewallPort_53}" == "true" ]];then
		[ -f "${Default_File}" ] && sed -i "s?iptables?#iptables?g" ${Default_File} > /dev/null 2>&1
	fi
	if [[ "${INCLUDE_AutoUpdate}" == "true" ]];then
		ExtraPackages git lean luci-app-autoupdate https://github.com/Hyy2001X main
		sed -i '/luci-app-autoupdate/d' .config > /dev/null 2>&1
		echo -e "\nCONFIG_PACKAGE_luci-app-autoupdate=y" >> .config
		Replace_File Scripts/AutoUpdate.sh package/base-files/files/bin
		AutoUpdate_Version=$(awk 'NR==6' package/base-files/files/bin/AutoUpdate.sh | awk -F '[="]+' '/Version/{print $2}')
		[[ -z "${AutoUpdate_Version}" ]] && AutoUpdate_Version="Unknown"
		sed -i "s?Openwrt?Openwrt ${Openwrt_Version} / AutoUpdate ${AutoUpdate_Version}?g" package/base-files/files/etc/banner
		echo "AutoUpdate Version: ${AutoUpdate_Version}"
	else
		sed -i "s?Openwrt?Openwrt ${Openwrt_Version}?g" package/base-files/files/etc/banner
	fi
	[[ -z "${Author}" ]] && Author="Unknown"
	echo "Author: ${Author}"
	echo "Openwrt Version: ${Openwrt_Version}"
	echo "Router: ${TARGET_PROFILE}"
	echo "Github: ${Github_Repo}"
	[ -f "$Default_File" ] && sed -i "s?${Lede_Version}?${Lede_Version} Compiled by ${Author} [${Display_Date}]?g" $Default_File
	echo "${Openwrt_Version}" > ${AutoBuild_Info}
	echo "${Github_Repo}" >> ${AutoBuild_Info}
	echo "${TARGET_PROFILE}" >> ${AutoBuild_Info}
	echo "Firmware Type: ${Firmware_sfx}"
	echo "Writting Type: ${Firmware_sfx} to ${AutoBuild_Info} ..."
	echo "${Firmware_sfx}" >> ${AutoBuild_Info}
	echo "${Source}" >> ${AutoBuild_Info}
	
}

Diy_Part2() {
	Diy_Core
	GET_TARGET_INFO
	Firmware_Path="bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}"
	Mkdir bin/Firmware
	case "${TARGET_PROFILE}" in
	x86_64)
		cd ${Firmware_Path}
		Legacy_Firmware=openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-generic-squashfs-combined.${Firmware_sfx}
		EFI_Firmware=openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-generic-squashfs-combined-efi.${Firmware_sfx}
		AutoBuild_Firmware="${Source}-${TARGET_PROFILE}-${Openwrt_Version}"
		if [ -f "${Legacy_Firmware}" ];then
			_MD5=$(md5sum ${Legacy_Firmware} | cut -d ' ' -f1)
			_SHA256=$(sha256sum ${Legacy_Firmware} | cut -d ' ' -f1)
			touch ${Home}/bin/Firmware/${AutoBuild_Firmware}.detail
			echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.detail
			mv -f ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
			echo "Legacy Firmware is detected !"
		fi
		if [ -f "${EFI_Firmware}" ];then
			_MD5=$(md5sum ${EFI_Firmware} | cut -d ' ' -f1)
			_SHA256=$(sha256sum ${EFI_Firmware} | cut -d ' ' -f1)
			touch ${Home}/bin/Firmware/${AutoBuild_Firmware}-UEFI.detail
			echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}-UEFI.detail
			cp ${EFI_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-UEFI.${Firmware_sfx}
			echo "UEFI Firmware is detected !"
		fi
	;;
	*)
		cd ${Home}
		Default_Firmware="openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-${TARGET_PROFILE}-squashfs-sysupgrade.${Firmware_sfx}"
		AutoBuild_Firmware="${Source}-${TARGET_PROFILE}-${Openwrt_Version}.${Firmware_sfx}"
		AutoBuild_Detail="${Source}-${TARGET_PROFILE}-${Openwrt_Version}.detail"
		echo "Firmware: ${AutoBuild_Firmware}"
		mv -f ${Firmware_Path}/${Default_Firmware} bin/Firmware/${AutoBuild_Firmware}
		_MD5=$(md5sum bin/Firmware/${AutoBuild_Firmware} | cut -d ' ' -f1)
		_SHA256=$(sha256sum bin/Firmware/${AutoBuild_Firmware} | cut -d ' ' -f1)
		echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > bin/Firmware/${AutoBuild_Detail}
	;;
	esac
	cd ${Home}
	echo "Actions Avaliable: $(df -h | grep "/dev/root" | awk '{printf $4}')"
}

Mkdir() {
	_DIR=${1}
	if [ ! -d "${_DIR}" ];then
		echo "[$(date "+%H:%M:%S")] Creating new folder [${_DIR}] ..."
		mkdir -p ${_DIR}
	fi
	unset _DIR
}
