#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Functions

GET_TARGET_INFO() {
        if [[ "${REPO_URL}" == "https://github.com/coolsnowwolf/lede" ]]; then
		Compile_Version="18.06"
	elif [[ "${REPO_URL}" == "https://github.com/Lienol/openwrt" ]]; then
		Compile_Version="19.07"
	elif [[ "${REPO_URL}" == "https://github.com/immortalwrt/immortalwrt" ]]; then
		Compile_Version="18.06"
	fi
	Home=${GITHUB_WORKSPACE}/openwrt
	echo "Home Path: ${Home}"
	[ -f ${GITHUB_WORKSPACE}/Openwrt.info ] && . ${GITHUB_WORKSPACE}/Openwrt.info
	AutoBuild_Info=${GITHUB_WORKSPACE}/openwrt/package/base-files/files/etc/openwrt_info
	Github_Repo="$(grep "https://github.com/[a-zA-Z0-9]" ${GITHUB_WORKSPACE}/.git/config | cut -c8-100)"
	Openwrt_Version="${Compile_Version}-${Compile_Date}"
	AutoUpdate_Version=$(awk 'NR==6' package/base-files/files/bin/AutoUpdate.sh | awk -F '[="]+' '/Version/{print $2}')
	[[ -z "${AutoUpdate_Version}" ]] && AutoUpdate_Version="Unknown"
	[[ -z "${Author}" ]] && Author="Unknown"
	TARGET1="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)"
	TARGET2="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)"
	TARGET3="$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')"
        if [[ "${TARGET1}" == "x86" ]]; then
		TARGET_PROFILE="x86-64"
	else
		TARGET_PROFILE="${TARGET3}"
	fi
	[[ -z "${TARGET_PROFILE}" ]] && TARGET_PROFILE="Unknown"
	case "${TARGET_PROFILE}" in
	x86-64)
		GZIP="$(grep "CONFIG_TARGET_IMAGES_GZIP" ${Home}/.config)"
		if [[ "${GZIP}" == "CONFIG_TARGET_IMAGES_GZIP=y" ]];then
			Firmware_sfx="img.gz"
		else
			Firmware_sfx="img"
		fi
	;;
	*)
		Firmware_sfx="${Extension}"
	;;
	esac
}

Diy_Part1() {
	sed -i '/luci-app-autoupdate/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-autoupdate=y" >> .config
	sed -i '/luci-app-ttyd/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-ttyd=y" >> .config
}

Diy_Part2() {
	GET_TARGET_INFO
	echo "Author: ${Author}"
	echo "Openwrt Version: ${Openwrt_Version}"
	echo "Router: ${TARGET_PROFILE}"
	echo "Github: ${Github_Repo}"
	echo "Source: ${Source}"
	echo "${Openwrt_Version}" > ${AutoBuild_Info}
	echo "${Github_Repo}" >> ${AutoBuild_Info}
	echo "${TARGET_PROFILE}" >> ${AutoBuild_Info}
	echo "Firmware Type: ${Firmware_sfx}"
	echo "Writting Type: ${Firmware_sfx} to ${AutoBuild_Info} ..."
	echo "${Firmware_sfx}" >> ${AutoBuild_Info}
	echo "${Source}" >> ${AutoBuild_Info}
	
}

Diy_Part3() {
	GET_TARGET_INFO
	Firmware_Path="bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}"
	Mkdir bin/Firmware
	case "${TARGET_PROFILE}" in
	x86-64)
		if [[ "${REPO_URL}" == "https://github.com/coolsnowwolf/lede" ]];then
			cd ${Firmware_Path}
			Legacy_Firmware=openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-generic-squashfs-combined.${Firmware_sfx}
			EFI_Firmware=openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-generic-squashfs-combined-efi.${Firmware_sfx}
			AutoBuild_Firmware="${Source}-${TARGET_PROFILE}-${Openwrt_Version}"
			if [ -f "${Legacy_Firmware}" ];then
				_MD5=$(md5sum ${Legacy_Firmware} | cut -d ' ' -f1)
				_SHA256=$(sha256sum ${Legacy_Firmware} | cut -d ' ' -f1)
				touch ${Home}/bin/Firmware/${AutoBuild_Firmware}.detail
				echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.detail
				cp ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
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
		fi
		if [[ "${REPO_URL}" == "https://github.com/Lienol/openwrt" ]];then
			cd ${Firmware_Path}
			Legacy_Firmware=openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-combined-squashfs.${Firmware_sfx}
			EFI_Firmware=openwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-combined-squashfs-efi.${Firmware_sfx}
			AutoBuild_Firmware="${Source}-${TARGET_PROFILE}-${Openwrt_Version}"
			if [ -f "${Legacy_Firmware}" ];then
				_MD5=$(md5sum ${Legacy_Firmware} | cut -d ' ' -f1)
				_SHA256=$(sha256sum ${Legacy_Firmware} | cut -d ' ' -f1)
				touch ${Home}/bin/Firmware/${AutoBuild_Firmware}.detail
				echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.detail
				cp ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
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
		fi
		if [[ "${REPO_URL}" == "https://github.com/immortalwrt/immortalwrt" ]];then
			cd ${Firmware_Path}
			Legacy_Firmware=immortalwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-combined-squashfs.${Firmware_sfx}
			EFI_Firmware=immortalwrt-${TARGET_BOARD}-${TARGET_SUBTARGET}-uefi-gpt-squashfs.${Firmware_sfx}
			AutoBuild_Firmware="${Source}-${TARGET_PROFILE}-${Openwrt_Version}"
			if [ -f "${Legacy_Firmware}" ];then
				_MD5=$(md5sum ${Legacy_Firmware} | cut -d ' ' -f1)
				_SHA256=$(sha256sum ${Legacy_Firmware} | cut -d ' ' -f1)
				touch ${Home}/bin/Firmware/${AutoBuild_Firmware}.detail
				echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.detail
				cp ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
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
		fi
	;;
	*)
		cd ${Home}
		Default_Firmware="${Up_Firmware}"
		AutoBuild_Firmware="${Source}-${TARGET_PROFILE}-${Openwrt_Version}.${Firmware_sfx}"
		AutoBuild_Detail="${Source}-${TARGET_PROFILE}-${Openwrt_Version}.detail"
		echo "Firmware: ${AutoBuild_Firmware}"
		cp ${Firmware_Path}/${Default_Firmware} bin/Firmware/${AutoBuild_Firmware}
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
