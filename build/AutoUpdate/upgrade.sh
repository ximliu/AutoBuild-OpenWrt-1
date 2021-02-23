#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Functions

GET_TARGET_INFO() {
	Home=${GITHUB_WORKSPACE}/openwrt
	echo "Home Path: ${Home}"
	[ -f ${GITHUB_WORKSPACE}/Openwrt.info ] && . ${GITHUB_WORKSPACE}/Openwrt.info
	AutoBuild_Info=${GITHUB_WORKSPACE}/openwrt/package/base-files/files/etc/openwrt_info
	Github_Repo="$(grep "https://github.com/[a-zA-Z0-9]" ${GITHUB_WORKSPACE}/.git/config | cut -c8-100)"
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
	
	if [[ "${REPO_URL}" == "https://github.com/coolsnowwolf/lede" ]];then
		Lede_Version="18.06"
		if [[ "${TARGET_PROFILE}" == "x86-64" ]]; then
			Up_Firmware="openwrt-x86-64-generic-squashfs-combined.img.gz"
			Firmware_sfx=".img.gz"
		elif [[ "${TARGET_PROFILE}" == "phicomm-k3" ]]; then
			Up_Firmware="openwrt-bcm53xx-generic-phicomm-k3-squashfs.trx"
			Firmware_sfx=".trx"
		elif [[ "${TARGET_PROFILE}" =~ (xiaomi_mir3g|d-team_newifi-d2) ]]; then
			Up_Firmware="openwrt-${TARGET1}-${TARGET2}-${TARGET3}-squashfs-sysupgrade.bin"
			Firmware_sfx=".bin"
		else
			Up_Firmware="${Updete_firmware}"
			Firmware_sfx="${Extension}"
		fi
	fi
        
	if [[ "${REPO_URL}" == "https://github.com/Lienol/openwrt" ]];then
		Lede_Version="19.07"
		if [[ "${TARGET_PROFILE}" == "x86-64" ]]; then
			Up_Firmware="openwrt-x86-64-combined-squashfs.img.gz"
			Firmware_sfx=".img.gz"
		elif [[ "${TARGET_PROFILE}" == "phicomm-k3" ]]; then
			Up_Firmware="openwrt-bcm53xx-phicomm-k3-squashfs.trx"
			Firmware_sfx=".trx"
		elif [[ "${TARGET_PROFILE}" =~ (xiaomi_mir3g|d-team_newifi-d2) ]]; then
			Up_Firmware="openwrt-${TARGET1}-${TARGET2}-${TARGET3}-squashfs-sysupgrade.bin"
			Firmware_sfx=".bin"
		else
			Up_Firmware="${Updete_firmware}"
			Firmware_sfx="${Extension}"
		fi
	fi
	
        if [[ "${REPO_URL}" == "https://github.com/immortalwrt/immortalwrt" ]];then
		Lede_Version="18.06"
		if [[ "${TARGET_PROFILE}" == "x86-64" ]]; then
			Up_Firmware="immortalwrt-x86-64-combined-squashfs.img.gz"
			Firmware_sfx=".img.gz"
		elif [[ "${TARGET_PROFILE}" == "phicomm-k3" ]]; then
			Up_Firmware="immortalwrt-bcm53xx-phicomm-k3-squashfs.trx"
			Firmware_sfx=".trx"
		elif [[ "${TARGET_PROFILE}" =~ (xiaomi_mir3g|d-team_newifi-d2) ]]; then
			Up_Firmware="immortalwrt-${TARGET1}-${TARGET2}-${TARGET3}-squashfs-sysupgrade.bin"
			Firmware_sfx=".bin"
		else
			Up_Firmware="${Updete_firmware}"
			Firmware_sfx="${Extension}"
		fi
	fi

	Openwrt_Version="${Lede_Version}-${Compile_Date}"
}

Diy_Part1() {
	sed -i '/luci-app-autoupdate/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-autoupdate=y" >> .config
	sed -i '/luci-app-ttyd/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_PACKAGE_luci-app-ttyd=y" >> .config
	sed -i '/IMAGES_GZIP/d' .config > /dev/null 2>&1
	echo -e "\nCONFIG_TARGET_IMAGES_GZIP=y" >> .config
}

Diy_Part2() {
	GET_TARGET_INFO
	echo "Author: ${Author}"
	echo "Openwrt Version: ${Openwrt_Version}"
	echo "Router: ${TARGET_PROFILE}"
	echo "Github: ${Github_Repo}"
	echo "Source: ${Source}"
	echo "Up_Firmware: ${Up_Firmware}"
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
				cp -a ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
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
				cp -a ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
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
				cp -a ${Legacy_Firmware} ${Home}/bin/Firmware/${AutoBuild_Firmware}-Legacy.${Firmware_sfx}
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
		cp -a bin/targets/*/*/*"${Default_Firmware}" bin/Firmware/"${AutoBuild_Firmware}"
		_MD5="$(md5sum bin/Firmware/${AutoBuild_Firmware} | cut -d ' ' -f1)"
		_SHA256="$(sha256sum bin/Firmware/${AutoBuild_Firmware} | cut -d ' ' -f1)"
		echo -e "\nMD5:${_MD5}\nSHA256:${_SHA256}" > bin/Firmware/"${AutoBuild_Detail}"
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
