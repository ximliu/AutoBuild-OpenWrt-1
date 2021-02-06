- ## 定时更新固件测试，一定要先设置好发布密匙，因为检测更新是检测github的发布地址
#
- ### 在diy-3.sh里面需要修改的东西
```
Author="281677160"       你的帐号
Default_Device="x86-64"          机型名字，看下面说明
Updete_firmware="openwrt-x86-64-combined-squashfs.img.gz"  安装固件名字,一定要正确填写,源码不一样名字不一样
Extension=".img.gz"              安装固件的扩展（后缀），一定要正确填写
Source="lede"               源码作者名字，随便写，用来区分源码的

```

---
- 机型名字可以看.config的第三行
```
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_friendlyarm_nanopi-r2s=y

- 上面的就是机型文件的三项，第三行的DEVICE_跟着的就是机型名字，后面的=y不要，就是friendlyarm_nanopi-r2s
- 就我知道没有明确机型名字的有X86跟N1，x86的填写x86-64或者x86-32根据你编译的填写
- N1的如果有测试，我需要另外的做一份文件
```

---

- ### 如果不想开SSH链接选择插件的话，就把下面三项按需放入你的.config里面就可以了
```
CONFIG_PACKAGE_luci-app-autoupdate=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_TARGET_IMAGES_GZIP=y

#
CONFIG_PACKAGE_luci-app-autoupdate=y    定时更新插件
CONFIG_PACKAGE_luci-app-ttyd=y        openwrt内置SSH命令窗
CONFIG_TARGET_IMAGES_GZIP=y         把img压缩成img.gz的，X86一定需要，其他不是.img.gz后缀的机型不需要
```
---
使用一键更新固件脚本:
```
首先需要打开 Openwrt 主页,点击系统-TTYD 终端或命令窗,按需输入下方指令:

检查更新(保留配置): bash /bin/AutoUpdate.sh

检查更新(不保留配置): bash /bin/AutoUpdate.sh -n


使用一键扩展内部空间\挂载 Samba 共享脚本:
同上方操作,打开TTYD 终端或命令窗,输入bash /bin/AutoBuild_Tools.sh
```
