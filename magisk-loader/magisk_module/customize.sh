# 这个文件是LSPosed的一部分
#
# LSPosed是自由软件：您可以根据自由软件基金会发布的GNU通用公共许可证的条款重新分发和/或修改它
# 这个许可证，可以是许可证的第3版，或者（根据您的选择）任何更新的版本。
#
# LSPosed是在希望它对您有用的情况下进行分发的，
# 但是没有任何保障；甚至没有适销性或适用于特定目的的隐含保障。请参阅GNU通用公共许可证以获取更多详细信息。
#
# 您应该随LSPosed一起收到GNU通用公共许可证的副本。
# 如果没有，请参阅<https://www.gnu.org/licenses/>。
#
# 版权 (C) 2020 EdXposed贡献者
# 版权 (C) 2021 LSPosed贡献者
#

# 禁用shellcheck对未使用的变量发出警告
# shellcheck disable=SC2034
SKIPUNZIP=1

# 定义FLAVOR变量，值为zygisk，在构建时会被替换为具体的模块版本（如zygisk或riru）
FLAVOR=zygisk

# 定义一个函数enforce_install_from_magisk_app，该函数用于强制要求用户通过Magisk应用安装模块
# 如果系统当前处于Magisk引导模式下，则打印出正在通过Magisk应用安装的信息
# 否则，打印出警告信息，指出不支持从恢复模式安装，并且可能会导致Riru或Riru模块无法正常工作
# 最后，调用abort函数退出安装过程，并显示警告信息
enforce_install_from_magisk_app() {
  if $BOOTMODE; then
    ui_print "- Installing from Magisk app"
  else
    ui_print "*********************************************************"
    ui_print "! Install from recovery is NOT supported"
    ui_print "! Some recovery has broken implementations, install with such recovery will finally cause Riru or Riru modules not working"
    ui_print "! Please install from Magisk app"
    abort "*********************************************************"
  fi
}

# 获取并存储LSPosed的版本号到VERSION变量中
VERSION=$(grep_prop version "${TMPDIR}/module.prop")
# 打印LSPosed的版本号
ui_print "- LSPosed version ${VERSION}"

# 打印正在提取verify.sh的信息
ui_print "- Extracting verify.sh"
# 从ZIPFILE中提取verify.sh到TMPDIR目录，并覆盖已存在的文件
unzip -o "$ZIPFILE" 'verify.sh' -d "$TMPDIR" >&2
# 检查verify.sh是否成功提取，如果失败，则打印出错误信息，指出zip文件可能已损坏，需要重新下载
if [ ! -f "$TMPDIR/verify.sh" ]; then
 ui_print "*********************************************************"
 ui_print "! Unable to extract verify.sh!"
 ui_print "! This zip may be corrupted, please try downloading again"
 abort    "*********************************************************"
fi
# 加载verify.sh脚本中的内容
. "$TMPDIR/verify.sh"

# 打印正在提取必要的文件的信息
# Base check
# 从ZIPFILE中提取customize.sh到TMPDIR目录，并覆盖已存在的文件
extract "$ZIPFILE" 'customize.sh' "$TMPDIR"
# 从ZIPFILE中提取verify.sh到TMPDIR目录，这一步实际上是重复的，因为前面已经提取过了
extract "$ZIPFILE" 'verify.sh' "$TMPDIR"
# 从ZIPFILE中提取util_functions.sh到TMPDIR目录，并覆盖已存在的文件
extract "$ZIPFILE" 'util_functions.sh' "$TMPDIR"
# 加载util_functions.sh脚本中的内容
. "$TMPDIR/util_functions.sh"
# 检查Android版本是否符合要求
check_android_version
# 检查Magisk版本是否符合要求
check_magisk_version
# 检查是否与其他不兼容的模块一起安装
check_incompatible_module

# 如果FLAVOR变量的值为"riru"，则执行以下操作
if [ "$FLAVOR" == "riru" ]; then
  # 打印正在提取riru.sh的信息
  # Extract riru.sh
  extract "$ZIPFILE" 'riru.sh' "$TMPDIR"
  # 加载riru.sh脚本中的内容
  . "$TMPDIR/riru.sh"
  # 调用riru.sh脚本中定义的check_riru_version函数，检查Riru版本是否符合要求
  # Functions from riru.sh
  check_riru_version
fi

# 再次调用enforce_install_from_magisk_app函数，强制要求用户通过Magisk应用安装模块
enforce_install_from_magisk_app

# 检查设备架构是否为arm、arm64、x86或x64，如果不是其中之一，则调用abort函数退出安装过程，并显示不支持的平台信息
# Check architecture
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86" ] && [ "$ARCH" != "x64" ]; then
  abort "! Unsupported platform: $ARCH"
else
  # 如果架构是受支持的，则打印出设备平台的信息
  ui_print "- Device platform: $ARCH"
fi

# 打印正在提取模块文件的信息
# Extract libs
ui_print "- Extracting module files"

# 从ZIPFILE中提取module.prop到MODPATH目录
extract "$ZIPFILE" 'module.prop'        "$MODPATH"
# 从ZIPFILE中提取post-fs-data.sh到MODPATH目录
extract "$ZIPFILE" 'post-fs-data.sh'    "$MODPATH"
# 从ZIPFILE中提取service.sh到MODPATH目录
extract "$ZIPFILE" 'service.sh'         "$MODPATH"
# 从ZIPFILE中提取uninstall.sh到MODPATH目录
extract "$ZIPFILE" 'uninstall.sh'       "$MODPATH"
# 从ZIPFILE中提取sepolicy.rule到MODPATH目录
extract "$ZIPFILE" 'sepolicy.rule'      "$MODPATH"
# 从ZIPFILE中提取framework/lspd.dex到MODPATH目录
extract "$ZIPFILE" 'framework/lspd.dex' "$MODPATH"
# 从ZIPFILE中提取daemon.apk到MODPATH目录
extract "$ZIPFILE" 'daemon.apk'         "$MODPATH"
# 从ZIPFILE中提取daemon到MODPATH目录
extract "$ZIPFILE" 'daemon'             "$MODPATH"
# 如果MODPATH目录下已经存在manager.apk，则删除它
rm -f "$MODPATH"/manager.apk
# 从ZIPFILE中提取manager.apk到MODPATH目录
extract "$ZIPFILE" 'manager.apk'        "$MODPATH"
# 在/data/adb/lspd目录下创建一个空目录
mkdir                                   '/data/adb/lspd'
# 从ZIPFILE中提取cli到/data/adb/lspd/bin目录
extract "$ZIPFILE" 'cli'                '/data/adb/lspd/bin'

# 如果FLAVOR变量的值为"zygisk"，则执行以下操作
if [ "$FLAVOR" == "zygisk" ]; then
  # 提取仅在KernelSU环境下需要的文件
  # extract only if KernelSU
  if [ "$KSU" ] || [ "$APATCH" ]; then
    # 如果是zygisk模式，在MODPATH/webroot目录下创建一个空目录
    # webroot only for zygisk
    mkdir -p "$MODPATH/webroot"
    # 提取webroot/index.html到MODPATH/webroot目录
    extract "$ZIPFILE" "webroot/index.html" "$MODPATH/webroot" true
    # 通过awk命令从ZIPFILE中获取webroot/src目录下的所有文件名，并排除sha256文件
    # evaluate if use awk or tr -s ' ' | cut -d' ' -f5
    SRCJS=$(unzip -l "$ZIPFILE" | grep "webroot/src" | grep -v sha256 | awk '{print $4}')
    # 提取SRCJS所指向的文件到MODPATH/webroot目录
    extract "$ZIPFILE" "$SRCJS" "$MODPATH/webroot" true
  fi

  # 在MODPATH/zygisk目录下创建一个空目录
  mkdir -p "$MODPATH/zygisk"
  # 如果架构为arm或arm64，则进行以下操作
  if [ "$ARCH" = "arm" ] || [ "$ARCH" = "arm64" ]; then
    # 提取lib/armeabi-v7a/liblspd.so到MODPATH/zygisk目录，并重命名为armeabi-v7a.so
    extract "$ZIPFILE" "lib/armeabi-v7a/liblspd.so" "$MODPATH/zygisk" true
    mv "$MODPATH/zygisk/liblspd.so" "$MODPATH/zygisk/armeabi-v7a.so"

    # 如果设备是64位的，则还需要执行以下操作
    if [ "$IS64BIT" = true ]; then
      # 提取lib/arm64-v8a/liblspd.so到MODPATH/zygisk目录，并重命名为arm64-v8a.so
      extract "$ZIPFILE" "lib/arm64-v8a/liblspd.so" "$MODPATH/zygisk" true
      mv "$MODPATH/zygisk/liblspd.so" "$MODPATH/zygisk/arm64-v8a.so"
    fi
  fi

  # 如果架构为x86或x64，则进行以下操作
  if [ "$ARCH" = "x86" ] || [ "$ARCH" = "x64" ]; then
    # 提取lib/x86/liblspd.so到MODPATH/zygisk目录，并重命名为x86.so
    extract "$ZIPFILE" "lib/x86/liblspd.so" "$MODPATH/zygisk" true
    mv "$MODPATH/zygisk/liblspd.so" "$MODPATH/zygisk/x86.so"

    # 如果设备是64位的，则还需要执行以下操作
    if [ "$IS64BIT" = true ]; then
      # 提取lib/x86_64/liblspd.so到MODPATH/zygisk目录，并重命名为x86_64.so
      extract "$ZIPFILE" "lib/x86_64/liblspd.so" "$MODPATH/zygisk" true
      mv "$MODPATH/zygisk/liblspd.so" "$MODPATH/zygisk/x86_64.so"
    fi
  fi
elif [ "$FLAVOR" == "riru" ]; then
  # 如果FLAVOR变量的值为"riru"，则执行以下操作
  # 在MODPATH/riru目录下创建一个空目录
  mkdir "$MODPATH/riru"
  # 在MODPATH/riru/lib目录下创建一个空目录
  mkdir "$MODPATH/riru/lib"
  # 在MODPATH/riru/lib64目录下创建一个空目录
  mkdir "$MODPATH/riru/lib64"
  # 如果架构为arm或arm64，则进行以下操作
  if [ "$ARCH" = "arm" ] || [ "$ARCH" = "arm64" ]; then
    # 打印正在提取arm库的信息
    ui_print "- Extracting arm libraries"
    # 提取lib/armeabi-v7a/lib$RIRU_MODULE_LIB_NAME.so到MODPATH/riru/lib目录
    extract "$ZIPFILE" "lib/armeabi-v7a/lib$RIRU_MODULE_LIB_NAME.so" "$MODPATH/riru/lib" true

    # 如果设备是64位的，则还需要执行以下操作
    if [ "$IS64BIT" = true ]; then
      # 打印正在提取arm64库的信息
      ui_print "- Extracting arm64 libraries"
      # 提取lib/arm64-v8a/lib$RIRU_MODULE_LIB_NAME.so到MODPATH/riru/lib64目录
      extract "$ZIPFILE" "lib/arm64-v8a/lib$RIRU_MODULE_LIB_NAME.so" "$MODPATH/riru/lib64" true
    fi
  fi

  # 如果架构为x86或x64，则进行以下操作
  if [ "$ARCH" = "x86" ] || [ "$ARCH" = "x64" ]; then
    # 打印正在提取x86库的信息
    ui_print "- Extracting x86 libraries"
    # 提取lib/x86/lib$RIRU_MODULE_LIB_NAME.so到MODPATH/riru/lib目录
    extract "$ZIPFILE" "lib/x86/lib$RIRU_MODULE_LIB_NAME.so" "$MODPATH/riru/lib" true

    # 如果设备是64位的，则还需要执行以下操作
    if [ "$IS64BIT" = true ]; then
      # 打印正在提取x64库的信息
      ui_print "- Extracting x64 libraries"
      # 提取lib/x86_64/lib$RIRU_MODULE_LIB_NAME.so到MODPATH/riru/lib64目录
      extract "$ZIPFILE" "lib/x86_64/lib$RIRU_MODULE_LIB_NAME.so" "$MODPATH/riru/lib64" true
    fi
  fi

  # 如果RIRU_MODULE_DEBUG变量的值为true，则执行以下操作
  if [ "$RIRU_MODULE_DEBUG" = true ]; then
    # 将MODPATH/riru目录下的内容移动到MODPATH/system目录下
    mv "$MODPATH/riru" "$MODPATH/system"
    # 将MODPATH/system/lib目录下的lib$RIRU_MODULE_LIB_NAME.so文件重命名为libriru_$RIRU_MODULE_LIB_NAME.so
    mv "$MODPATH/system/lib/lib$RIRU_MODULE_LIB_NAME.so" "$MODPATH/system/lib/libriru_$RIRU_MODULE_LIB_NAME.so"
    # 将MODPATH/system/lib64目录下的lib$RIRU_MODULE_LIB_NAME.so文件重命名为libriru_$RIRU_MODULE_LIB_NAME.so
    mv "$MODPATH/system/lib64/lib$RIRU_MODULE_LIB_NAME.so" "$MODPATH/system/lib64/libriru_$RIRU_MODULE_LIB_NAME.so"
    # 如果RIRU_API变量的值大于等于26，则执行以下操作
    if [ "$RIRU_API" -ge 26 ]; then
      # 在MODPATH/riru/lib目录下创建一个空目录
      mkdir -p "$MODPATH/riru/lib"
      # 在MODPATH/riru/lib64目录下创建一个空目录
      mkdir -p "$MODPATH/riru/lib64"
      # 创建一个空文件MODPATH/riru/lib/libriru_$RIRU_MODULE_LIB_NAME
      touch "$MODPATH/riru/lib/libriru_$RIRU_MODULE_LIB_NAME"
      # 创建一个空文件MODPATH/riru/lib64/libriru_$RIRU_MODULE_LIB_NAME
      touch "$MODPATH/riru/lib64/libriru_$RIRU_MODULE_LIB_NAME"
    else
      # 如果RIRU_API变量的值小于26，则在/data/adb/riru/modules/$RIRU_MODULE_LIB_NAME目录下创建一个空目录
      mkdir -p "/data/adb/riru/modules/$RIRU_MODULE_LIB_NAME"
    fi
  fi
fi

# 如果设备的Android API版本大于等于29，则执行以下操作
if [ "$API" -ge 29 ]; then
  # 打印正在提取dex2oat二进制文件的信息
  ui_print "- Extracting dex2oat binaries"
  # 在MODPATH/bin目录下创建一个空目录
  mkdir "$MODPATH/bin"

  # 如果架构为arm或arm64，则进行以下操作
  if [ "$ARCH" = "arm" ] || [ "$ARCH" = "arm64" ]; then
    # 提取bin/armeabi-v7a/dex2oat到MODPATH/bin目录，并重命名为dex2oat32
    extract "$ZIPFILE" "bin/armeabi-v7a/dex2oat" "$MODPATH/bin" true
    mv "$MODPATH/bin/dex2oat" "$MODPATH/bin/dex2oat32"

    # 如果设备是64位的，则还需要执行以下操作
    if [ "$IS64BIT" = true ]; then
      # 提取bin/arm64-v8a/dex2oat到MODPATH/bin目录，并重命名为dex2oat64
      extract "$ZIPFILE" "bin/arm64-v8a/dex2oat" "$MODPATH/bin" true
      mv "$MODPATH/bin/dex2oat" "$MODPATH/bin/dex2oat64"
    fi
  elif [ "$ARCH" == "x86" ] || [ "$ARCH" == "x64" ]; then
    # 如果架构为x86或x64，则进行以下操作
    # 提取bin/x86/dex2oat到MODPATH/bin目录，并重命名为dex2oat32
    extract "$ZIPFILE" "bin/x86/dex2oat" "$MODPATH/bin" true
    mv "$MODPATH/bin/dex2oat" "$MODPATH/bin/dex2oat32"

    # 如果设备是64位的，则还需要执行以下操作
    if [ "$IS64BIT" = true ]; then
      # 提取bin/x86_64/dex2oat到MODPATH/bin目录，并重命名为dex2oat64
      extract "$ZIPFILE" "bin/x86_64/dex2oat" "$MODPATH/bin" true
      mv "$MODPATH/bin/dex2oat" "$MODPATH/bin/dex2oat64"
    fi
  fi

  # 打印正在修补二进制文件的信息
  ui_print "- Patching binaries"
  # 生成一个32位的随机字符串DEV_PATH，用于替换二进制文件中的特定字符串
  DEV_PATH=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 32)
  # 使用sed命令在MODPATH/daemon.apk文件中将特定字符串替换为DEV_PATH
  sed -i "s/5291374ceda0aef7c5d86cd2a4f6a3ac/$DEV_PATH/g" "$MODPATH/daemon.apk"
  # 使用sed命令在MODPATH/bin/dex2oat32文件中将特定字符串替换为DEV_PATH
  sed -i "s/5291374ceda0aef7c5d86cd2a4f6a3ac/$DEV_PATH/" "$MODPATH/bin/dex2oat32"
  # 使用sed命令在MODPATH/bin/dex2oat64文件中将特定字符串替换为DEV_PATH
  sed -i "s/5291374ceda0aef7c5d86cd2a4f6a3ac/$DEV_PATH/" "$MODPATH/bin/dex2oat64"
else
  # 如果设备的Android API版本小于29，则执行以下操作
  # 提取system.prop到MODPATH目录
  extract "$ZIPFILE" 'system.prop' "$MODPATH"
fi

# 递归地设置MODPATH目录下所有文件和子目录的权限，用户和组都是0，文件权限为0755，子目录权限为0755
set_perm_recursive "$MODPATH" 0 0 0755 0644
# 递归地设置MODPATH/bin目录下所有文件和子目录的权限，用户为0，组为2000，文件权限为0755，子目录权限为0755，SELinux上下文为u:object_r:magisk_file:s0
set_perm_recursive "$MODPATH/bin" 0 2000 0755 0755 u:object_r:magisk_file:s0
# 递归地设置/data/adb/lspd/目录下所有文件和子目录的权限，用户和组都是0，文件权限为0755，子目录权限为0644
set_perm_recursive "/data/adb/lspd/" 0 0 0755 0644
# 递归地设置/data/adb/lspd/bin目录下所有文件和子目录的权限，用户和组都是0，文件权限为0755，子目录权限为0755，SELinux上下文为u:object_r:magisk_file:s0
set_perm_recursive "/data/adb/lspd/bin" 0 0 0755 0755 u:object_r:magisk_file:s0
# 设置MODPATH/daemon文件的权限为0744
chmod 0744 "$MODPATH/daemon"
# 设置/data/adb/lspd/bin/cli文件的权限为0700
chmod 0700 "/data/adb/lspd/bin/cli"

# 如果系统属性ro.maple.enable的值为1，并且FLAVOR变量的值为"zygisk"，则执行以下操作
if [ "$(grep_prop ro.maple.enable)" == "1" ] && [ "$FLAVOR" == "zygisk" ]; then
  # 打印正在添加ro.maple.enable=0的信息
  ui_print "- Add ro.maple.enable=0"
  # 将ro.maple.enable=0添加到MODPATH/system.prop文件中
  echo "ro.maple.enable=0" >> "$MODPATH/system.prop"
fi

# 打印欢迎使用LSPosed的信息
ui_print "- Welcome to LSPosed!"
