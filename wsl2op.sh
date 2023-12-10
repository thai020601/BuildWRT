#!/bin/bash
# OP编译
# Copyright (c) 2019-2022 smallprogram
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/smallprogram/OpenWrtAction
# File: wsl2op.sh
# Description: WSL automatically compiles Openwrt script code

# ------------------------------------------------------⬇⬇⬇⬇Code⬇⬇⬇⬇------------------------------------------------------
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make -j$(nproc)
# ----------------------------------------------------------------------------------------------------------------
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make tools/compile -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make toolchain/compile -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/cleanup -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make target/compile -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make buildinfo -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/compile -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make diffconfig buildversion feedsversion
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/install -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make target/install -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/index -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make json_overview_image_info -j$(nproc)
# PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make checksum -j$(nproc)
# ================================================================================================================
# make -j$(nproc)
# ----------------------------------------------------------------------------------------------------------------
# make tools/compile -j$(nproc)
# make toolchain/compile -j$(nproc)
# make package/cleanup -j$(nproc)
# make target/compile -j$(nproc)
# make buildinfo -j$(nproc)
# make package/compile -j$(nproc)
# make diffconfig buildversion feedsversion
# make package/install -j$(nproc)
# make target/install -j$(nproc)
# make package/index -j$(nproc)
# make json_overview_image_info -j$(nproc)
# make checksum -j$(nproc)


#--------------------⬇⬇⬇⬇环境变量⬇⬇⬇⬇--------------------
# 路由默认IP地址
routeIP=10.10.0.253
# 编译环境中当前账户名字
userName=$USER
# 默认OpenWrtAction的Config文件夹中的config文件名
configName=$1
# 默认lean源码文件夹名
ledeDir=lede_$configName
config_list=($(ls /home/$userName/OpenWrtAction/config))
# 默认输入超时时间，单位为秒
timer=15
# 编译环境默认值，1为WSL2，2为非WSL2的Linux环境。不要修改这里
sysenv=1
# OpenWrtAction Git URL
owaUrl=https://github.com/smallprogram/OpenWrtAction.git
# 是否首次编译 0否，1是
isFirstCompile=0
# 是否Make Clean & Make DirClean
isCleanCompile=$2
# 是否单线程编译
isSingleCompile=$3
# 编译openwrt的log日志文件夹名称
log_folder_name=openwrt_log
# 编译子文件夹名称
folder_name=log_Compile_${configName}_$(date "+%Y-%m-%d-%H-%M-%S")
# logfile名称
log_feeds_update_filename=Func_Main1_feeds_update-git_log.log
log_feeds_install_filename=Func_Main2_feeds_install-git_log.log
log_make_defconfig_filename=Func_Main3_make_defconfig-git_log.log
log_make_down_filename=Func_Main4_make_download-git_log.log
log_Compile_filename=Func_Main5_Compile-git_log.log
log_Compile_time_filename=Func_Main6_Compile_Time-git_log.log
# defconfig操作之前的config文件名
log_before_defconfig_config=.config_old
# defconfig操作之后的config文件名
log_after_defconfig_config=.config_new
# 两个config的差异文件名
log_diff_config=.config_diff
#清理超过多少天的日志文件
clean_day=3
# 扩展luci插件地址
# luci_apps=(
#     # https://github.com/jerrykuku/luci-theme-argon.git
#     https://github.com/jerrykuku/luci-app-argon-config.git
#     # https://github.com/jerrykuku/lua-maxminddb.git
#     # https://github.com/jerrykuku/luci-app-vssr.git
#     # https://github.com/lisaac/luci-app-dockerman.git
#     # https://github.com/xiaorouji/openwrt-passwall.git
#     https://github.com/rufengsuixing/luci-app-adguardhome.git
# )
# 编译结果变量
is_complie_error=0
# 编译是否展示详细信息
is_VS='V=s'
#Git参数
git_email=smallprogram@foxmail.com
git_user=smallprogram




#--------------------⬇⬇⬇⬇各种函数⬇⬇⬇⬇--------------------

# 输出默认语言函数
function Func_LogMessage(){
    if [ ! -n "$isChinese" ];then
        echo -e "$1"
    else
        echo -e "$2"
    fi
}

Func_LogMessage "\033[31m 输入任意值取消显示详细编译信息 \033[0m" "\033[31m Enter any value to cancel the display of detailed compilation information \033[0m"
Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
read -t $timer isVS
if [ ! -n "$isVS" ]; then
    Func_LogMessage "\033[34m 默认显示详细编译信息  \033[0m" "\033[34m Display detailed compilation information by default  \033[0m"
    sleep 1s
else
    Func_LogMessage "\033[34m 取消默认显示详细编译信息 \033[0m" "\033[34m Cancel the default display of detailed compilation information \033[0m"
    is_VS=''
    sleep 1s
fi

# DIY Script函数

function Func_DIY1_Script(){
    Func_LogMessage "\033[31m 开始执行DIY1设置脚本 \033[0m" "\033[31m Start executing the DIY1 setup script \033[0m"
    sleep 1s
    
    bash ../OpenWrtAction/diy_script/diy-part1.sh

    Func_LogMessage "\033[31m DIY1脚本执行完成 \033[0m" "\033[31m DIY script execution completed \033[0m"
    sleep 2s
}


function Func_DIY2_Script(){
    Func_LogMessage "\033[31m 开始执行DIY2设置脚本 \033[0m" "\033[31m Start executing the DIY2 setup script \033[0m"
    sleep 1s
    
    bash ../OpenWrtAction/diy_script/diy-part2.sh 1

    Func_LogMessage "\033[31m DIY2脚本执行完成 \033[0m" "\033[31m DIY script execution completed \033[0m"
    sleep 2s
}

#GIT设置
function Func_GitSetting(){
    git config --global user.email "${git_email}"
    git config --global user.name "${git_user}"
    export GIT_SSL_NO_VERIFY=1
}

# 获取自定插件函数 作废，直接使用diy脚本
# function Func_Get_luci_apps(){
#     for luci_app in "${luci_apps[@]}"; do

#         temp=${luci_app##*/} # xxx.git
#         dir=${temp%%.*}  # xxx

#         Func_LogMessage "\033[31m 开始同步$dir.... \033[0m" "\033[31m Start syncing $dir.... \033[0m"
#         sleep 2s

#         # if [[ $isFirstCompile == 1 && $dir == luci-theme-argon ]]; then
#         #     cd /home/${userName}/${ledeDir}/package/lean/
#         #     rm -rf $dir
#         #     git clone -b 18.06 $luci_app
#         #     continue
#         # fi

#         # if [[ $luci_app == https://github.com/xiaorouji/openwrt-passwall.git ]]; then
#         #     cd /home/${userName}/${ledeDir}/package/lean/
#         #     rm -rf passwall
#         #     rm -rf passwall_package
#         #     git clone -b luci $luci_app passwall
#         #     git clone -b packages $luci_app passwall_package
#         #     cp -rf passwall_package/* passwall
#         #     rm -rf passwall_package
#         #     continue
#         # fi

#         if [ ! -d "/home/${userName}/${ledeDir}/package/lean/$dir" ];
#         then
#             cd /home/${userName}/${ledeDir}/package/lean/
#             git clone $luci_app
#             cd /home/${userName}
#         else
#             cd /home/${userName}/${ledeDir}/package/lean/$dir
#             git stash
#             git stash drop
#             git pull --rebase
#             cd /home/${userName}
#         fi
#     done
# }

# 编译报错检查函数
check_compile_error() {
  local is_compile_error=$1
  local messages=$2

  if [ "$is_compile_error" -ne 0 ]; then
    Func_LogMessage "\033[34m ${messages},的编译状态:${is_compile_error} \033[0m" "\033[34m ${messages}，Compile Status Code:${is_complie_error} \033[0m"
    exit $1
  else
    Func_LogMessage "\033[34m ${messages},的编译状态:${is_compile_error} \033[0m" "\033[34m ${messages}，Compile Status Code:${is_complie_error} \033[0m"
  fi
}

# 编译函数
function Func_Compile_Firmware() {

    
    # CheckUpdate
    cd /home/${userName}/${ledeDir}
    begin_date=开始时间$(date "+%Y-%m-%d-%H-%M-%S")
    folder_name=log_Compile_${configName}_$(date "+%Y-%m-%d-%H-%M-%S")
    Func_LogMessage "\033[31m 是否启用Clean编译，如果不输入任何值默认否，输入任意值启用Clean编译，Clean操作适用于大版本更新 \033[0m" "\033[31m Whether to enable Clean compilation, if you do not enter any value, the default is No, enter any value to enable Clean compilation, Clean operation is suitable for major version updates \033[0m"
    Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    read -t $timer isSingleCompile
    if [ ! -n "$isCleanCompile" ]; then
        Func_LogMessage "\033[34m 不执行make clean && make dirclean  \033[0m" "\033[34m OK, do not execute make clean && make dirclean  \033[0m"
    else
        Func_LogMessage "\033[34m 配置为Clean编译。执行make clean && make dirclean \033[0m" "\033[34m OK, configure for Clean compilation. \033[0m"
        # make clean
        # make dirclean
        make distclean
        Func_LogMessage "\033[34m 执行make clean && make dirclean完毕，准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
        sleep 1s
    fi
    
    Func_LogMessage "\033[34m 创建编译日志文件夹/home/${userName}/${log_folder_name}/${folder_name} \033[0m" "\033[34m Create compilation log folder /home/${userName}/${log_folder_name}/${folder_name} \033[0m"
    sleep 1s

    if [ ! -d "/home/${userName}/${log_folder_name}" ];
    then
        mkdir /home/${userName}/${log_folder_name}
    fi
    if [ ! -d "/home/${userName}/${log_folder_name}/${folder_name}" ];
    then
        mkdir /home/${userName}/${log_folder_name}/${folder_name}
    fi
    touch /home/${userName}/${log_folder_name}/${folder_name}/${log_feeds_update_filename}
    touch /home/${userName}/${log_folder_name}/${folder_name}/${log_feeds_install_filename}
    touch /home/${userName}/${log_folder_name}/${folder_name}/${log_make_defconfig_filename}
    touch /home/${userName}/${log_folder_name}/${folder_name}/${log_make_down_filename}
    touch /home/${userName}/${log_folder_name}/${folder_name}/${log_Compile_filename}
    echo -e $begin_date > /home/${userName}/${log_folder_name}/${folder_name}/${log_Compile_time_filename}

    Func_LogMessage "\033[34m 编译日志文件夹创建成功 \033[0m" "\033[34m The compilation log folder was created successfully \033[0m"
    sleep 1s
    Func_LogMessage "\033[34m 开始编译！！ \033[0m" "\033[34m Start compiling! ! \033[0m"
    sleep 1s

    Func_LogMessage "\033[31m 开始将OpenwrtAction中的自定义feeds注入lean源码中.... \033[0m" "\033[31m Started injecting custom feeds in OpenwrtAction into lean source code... \033[0m"
    sleep 2s
    echo
    cat /home/${userName}/OpenWrtAction/feeds_config/custom.feeds.conf.default > /home/${userName}/${ledeDir}/feeds.conf.default

    Func_DIY1_Script

    Func_LogMessage "\033[31m 开始clean feeds.... \033[0m" "\033[31m begin update feeds.... \033[0m"
    ./scripts/feeds clean
    echo
    Func_LogMessage "\033[31m 开始update feeds.... \033[0m" "\033[31m begin update feeds.... \033[0m"
    sleep 1s
    ./scripts/feeds update -a | tee -a /home/${userName}/${log_folder_name}/${folder_name}/${log_feeds_update_filename}
    echo
    Func_LogMessage "\033[31m 开始install feeds.... \033[0m" "\033[31m begin install feeds.... \033[0m"
    sleep 1s
    ./scripts/feeds install -a | tee -a /home/${userName}/${log_folder_name}/${folder_name}/${log_feeds_install_filename}
    echo

    

    Func_DIY2_Script


    echo
    Func_LogMessage "\033[31m 开始将OpenwrtAction中config文件夹下的${configName}注入lean源码中,准备make toolchain.... \033[0m" "\033[31m Start to inject ${configName} under the config folder in OpenwrtAction into lean source code... \033[0m"
    sleep 2s
    echo
    cat /home/${userName}/OpenWrtAction/config/${configName} > /home/${userName}/${ledeDir}/.config

    cat /home/${userName}/${ledeDir}/.config > /home/${userName}/${log_folder_name}/${folder_name}/${log_before_defconfig_config}
    # echo -e "\nCONFIG_ALL=y" >> .config
    # echo -e "\nCONFIG_ALL_NONSHARED=y" >> .config

    Func_LogMessage "\033[34m 开始执行make defconfig! \033[0m" "\033[34m Start to execute make defconfig! \033[0m"
    sleep 1s
    make defconfig | tee -a /home/${userName}/${log_folder_name}/${folder_name}/${log_make_defconfig_filename}

    cat /home/${userName}/${ledeDir}/.config > /home/${userName}/${log_folder_name}/${folder_name}/${log_after_defconfig_config}
    diff  /home/${userName}/${log_folder_name}/${folder_name}/${log_before_defconfig_config} /home/${userName}/${log_folder_name}/${folder_name}/${log_after_defconfig_config} -y -W 200 > /home/${userName}/${log_folder_name}/${folder_name}/${log_diff_config}


    Func_LogMessage "\033[34m 开始执行make download! \033[0m" "\033[34m Start to execute make download! \033[0m"
    sleep 1s
    make -j8 download | tee -a /home/${userName}/${log_folder_name}/${folder_name}/${log_make_down_filename}
    find dl -size -1024c -exec ls -l {} \;
    find dl -size -1024c -exec rm -f {} \;


    echo
    Func_LogMessage "\033[31m 开始make tools. \033[0m" "\033[31m Begin make tools \033[0m"
    sleep 2s
    echo
    if [[ $sysenv == 1 ]]
    then
        Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer isSingleCompile
        if [ ! -n "$isSingleCompile" ]; then
            Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
            sleep 1s
            # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make tools/compile -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile1_tools.log
            is_complie_error=${PIPESTATUS[0]}
        else
            Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
            Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
            sleep 1s
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make tools/compile -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile1_tools.log
            is_complie_error=${PIPESTATUS[0]}
        fi
        
    else
        Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer isSingleCompile
        if [ ! -n "$isSingleCompile" ]; then
            Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
            sleep 1s
            # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            make tools/compile -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile1_tools.log
            is_complie_error=${PIPESTATUS[0]}
        else
            Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
            Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
            sleep 1s
            make tools/compile -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile1_tools.log
            is_complie_error=${PIPESTATUS[0]}
        fi
        # $PATH
    fi
    check_compile_error "$is_complie_error" "make tools"

    echo
    Func_LogMessage "\033[31m 开始make toolchain. \033[0m" "\033[31m Begin make toolchain \033[0m"
    sleep 2s
    echo
    if [[ $sysenv == 1 ]]
    then
        Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer isSingleCompile
        if [ ! -n "$isSingleCompile" ]; then
            Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
            sleep 1s
            # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make toolchain/compile -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile2_toolchain.log
            is_complie_error=${PIPESTATUS[0]}
        else
            Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
            Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
            sleep 1s
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make toolchain/compile -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile2_toolchain.log
            is_complie_error=${PIPESTATUS[0]}
        fi
        
    else
        Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer isSingleCompile
        if [ ! -n "$isSingleCompile" ]; then
            Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
            sleep 1s
            # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            make toolchain/compile -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile2_toolchain.log
            is_complie_error=${PIPESTATUS[0]}
        else
            Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
            Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
            sleep 1s
            make toolchain/compile -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile2_toolchain.log
            is_complie_error=${PIPESTATUS[0]}
        fi
        # $PATH
    fi

    check_compile_error "$is_complie_error" "make toolchain"

    # rm -rf .config* dl bin

    # make buildinfo
    # make diffconfig buildversion feedsversion

    # Func_LogMessage "\033[34m 开始执行make target! \033[0m" "\033[34m Start to execute make target! \033[0m"
    # sleep 1s
    # if [[ $sysenv == 1 ]]
    # then
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make target/compile -j$(nproc) $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile3_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make target/compile -j1 $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile3_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
        
    # else
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         make target/compile -j$(nproc) $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile3_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         make target/compile -j1 $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile3_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
    #     # $PATH
    # fi

    # check_compile_error "$is_complie_error" "make target"

    # Func_LogMessage "\033[34m 开始执行make packages! \033[0m" "\033[34m Start to execute make packages! \033[0m"
    # sleep 1s
    # if [[ $sysenv == 1 ]]
    # then
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/compile -j$(nproc) $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile4_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/compile -j1 $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile4_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
        
    # else
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         make package/compile -j$(nproc) $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile4_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         make package/compile -j1 $is_VS IGNORE_ERRORS="m n" | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile4_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
    #     # $PATH
    # fi

    # check_compile_error "$is_complie_error" "make packages"

    # make package/index

    # Func_LogMessage "\033[34m 开始执行install package! \033[0m" "\033[34m Start to execute install package! \033[0m"
    # sleep 1s
    # if [[ $sysenv == 1 ]]
    # then
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/install -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile5_install_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make package/install -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile5_install_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
        
    # else
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         make package/install -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile5_install_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         make package/install -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile5_install_packages.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
    #     # $PATH
    # fi

    # check_compile_error "$is_complie_error" "install package"

    # Func_LogMessage "\033[34m 开始执行install target! \033[0m" "\033[34m Start to execute install target! \033[0m"
    # sleep 1s
    # if [[ $sysenv == 1 ]]
    # then
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make target/install -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_install_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make target/install -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_install_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
        
    # else
    #     Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
    #     Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    #     read -t $timer isSingleCompile
    #     if [ ! -n "$isSingleCompile" ]; then
    #         Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
    #         sleep 1s
    #         # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    #         make target/install -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_install_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     else
    #         Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
    #         Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
    #         sleep 1s
    #         make target/install -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_install_target.log
    #         is_complie_error=${PIPESTATUS[0]}
    #     fi
    #     # $PATH
    # fi

    # check_compile_error "$is_complie_error" "install target"

    # make json_overview_image_info
    # make checksum


    Func_LogMessage "\033[34m 开始执行生成固件 \033[0m" "\033[34m Start to Generate Frimware! \033[0m"
    sleep 1s
    if [[ $sysenv == 1 ]]
    then
        Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer isSingleCompile
        if [ ! -n "$isSingleCompile" ]; then
            Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
            sleep 1s
            # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_Generate_Frimware.log
            is_complie_error=${PIPESTATUS[0]}
        else
            Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
            Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
            sleep 1s
            PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin make -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_Generate_Frimware.log
            is_complie_error=${PIPESTATUS[0]}
        fi
        
    else
        Func_LogMessage "\033[31m 是否启用单线程编译，如果不输入任何值默认否，输入任意值启用单线程编译 \033[0m" "\033[31m Whether to enable single-threaded compilation, if you do not enter any value, the default is No, enter any value to enable single-threaded compilation \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer isSingleCompile
        if [ ! -n "$isSingleCompile" ]; then
            Func_LogMessage "\033[34m OK，不执行单线程编译  \033[0m" "\033[34m OK, do not perform single-threaded compilation  \033[0m"
            sleep 1s
            # echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            make -j$(nproc) $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_Generate_Frimware.log
            is_complie_error=${PIPESTATUS[0]}
        else
            Func_LogMessage "\033[34m OK，执行单线程编译。 \033[0m" "\033[34m OK, execute single-threaded compilation. \033[0m"
            Func_LogMessage "\033[34m 准备开始编译 \033[0m" "\033[34m Ready to compile \033[0m"
            sleep 1s
            make -j1 $is_VS | tee -a /home/${userName}/${log_folder_name}/${folder_name}/log_Compile6_Generate_Frimware.log
            is_complie_error=${PIPESTATUS[0]}
        fi
        # $PATH
    fi

    check_compile_error "$is_complie_error" "Generate Frimware"
    
    Func_LogMessage "\033[34m 编译状态:${is_complie_error} \033[0m" "\033[34m Compile Status Code:${is_complie_error} \033[0m"
    
    Func_LogMessage "\033[34m make编译结束! \033[0m" "\033[34m Make compilation is over! \033[0m"
    sleep 1s
    
    end_date=结束时间$(date "+%Y-%m-%d-%H-%M-%S")
    echo -e $end_date >> /home/${userName}/${log_folder_name}/${folder_name}/${log_Compile_time_filename}

    ######是否提交编译结果到github Release
    # UpdateFileToGithubRelease



    Func_LogMessage "\033[31m 是否拷贝编译固件到${log_folder_name}/${folder_name}下？不输入默认不拷贝，输入任意值拷贝 \033[0m" "\033[31m Do you want to copy and compile the firmware to ${log_folder_name}/${folder_name}? Don’t copy by default, input any value to copy \033[0m"
    Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    read -t $timer iscopy
    if [ ! -n "$iscopy" ]; then
        Func_LogMessage "\033[34m OK，不拷贝 \033[0m" "\033[34m OK, don't copy \033[0m"
    else
        Func_LogMessage "\033[34m 开始拷贝 \033[0m" "\033[34m Start copying \033[0m"
        cp -r /home/${userName}/${ledeDir}/bin/targets /home/${userName}/${log_folder_name}/${folder_name}
        Func_LogMessage "\033[34m 拷贝完成 \033[0m" "\033[34m Copy completed \033[0m"
    fi

    # 将lede还原
    # Func_LogMessage "\033[34m 将lede源码还原到最后的hash状态! \033[0m" "\033[34m Restore the lede source code to the last hash state \033[0m"
    # git --git-dir=/home/${userName}/${ledeDir}/.git --work-tree=/home/${userName}/${ledeDir} checkout master
    # git --git-dir=/home/${userName}/${ledeDir}/.git --work-tree=/home/${userName}/${ledeDir} clean -xdf

}

# config文件夹的config文件列表函数
function Func_ConfigList(){
    key=0
    for conf in ${config_list[*]}; 
    do 
        key=$((${key} + 1))
        echo "$key: $conf"; 
        # echo "129 key的值："$key
    done
    read -t $timer configNameInp
    if [ ! -n "$configNameInp" ]; then
        i=1
        # configName=X86.config
        # ledeDir=lede_$configName
        # echo "135 configName的值："$configName
        for context in ${config_list[*]}; 
        do 
            if [[ $context == $configName ]]; then
                break
            fi
            i=$((${i} + 1))
            # echo "142 i的值："$i
        done
        configNameInp=$i
        # echo "145 configNameInp的值："$configNameInp
        Func_LogMessage "\033[34m 输入超时使用默认值$configName \033[0m" "\033[34m Use the default value $configName for input timeout \033[0m"
    else 
        if [[ $configNameInp -ge 1 && $configNameInp -le $key ]]; then
            configName=${config_list[$(($configNameInp-1))]}
            ledeDir=lede_$configName
            # echo $configNameInp
            # echo $configName
        fi
    fi
}

#清理日志文件夹函数
function Func_CleanLogFolder(){
    if [ -d "/home/${userName}/${log_folder_name}" ];
    then
        Func_LogMessage "\033[31m 是否清理存储超过$clean_day天的日志文件，默认删除，如果录入任意值不删除 \033[0m" "\033[31m Whether to clean up the log files stored for more than $clean_day days, delete by default, if you enter any value, it will not be deleted \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer isclean
        if [ ! -n "$isclean" ]; then
            cd /home/${userName}/${log_folder_name}
            find -mtime +$clean_day -type d | xargs rm -rf
            find -mtime +$clean_day -type f | xargs rm -rf
            Func_LogMessage "\033[31m 清理成功 \033[0m" "\033[31m Cleaned up successfully \033[0m"
        else
            Func_LogMessage "\033[34m OK，不清理超过$clean_day天的日志文件 \033[0m" "\033[34m OK, do not clean up log files older than $clean_day \033[0m"
        fi
    fi


}

#主函数
function Func_Main(){
    # GitSetting
    Func_GitSetting
    # 默认语言中文，其他英文
    echo -e "\033[31m 请选择默认语言，输入任意字符为英文，不输入默认中文 \033[0m"
    echo -e "\033[31m Please select the default language, enter any character as English, and do not enter the default Chinese. \033[0m"
    read -t $timer isChinese

    Func_LogMessage "\033[34m 注意，请确保当前linux账户为非root账户，并且已经安装相关编译依赖 \033[0m" "\033[34m Note, please make sure that the current linux account is a non-root account, and the relevant compilation dependencies have been installed \033[0m"
    Func_LogMessage "\033[34m 如果不符合上述条件，请安装依赖或ctrl+C退出 \033[0m" "\033[34m If the above conditions are not met, please Install dependencies or ctrl+C to exit \033[0m"
    Func_LogMessage "\033[31m 是否安装编译依赖，不输入默认不安装，输入任意值安装，将会在$timer秒后自动选择默认值 \033[0m" "\033[31m Whether to install the compilation dependencies. Do not enter the default. Do not install. Enter any value to install. The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer dependencies
        if [ ! -n "$dependencies" ]; then
            Func_LogMessage "\033[34m OK，不安装 \033[0m" "\033[34m OK, Not installed \033[0m"   
        else
            Func_LogMessage "\033[34m 开始安装 \033[0m" "\033[34m Start installation \033[0m"
            sudo apt update -y
            sudo apt full-upgrade -y
            sleep 5s
            sudo apt-get -y install $(curl -fsSL https://github.com/smallprogram/OpenWrtAction/raw/main/diy_script/depends)
            sleep 5s
            git config --global http.sslverify false
            git config --global https.sslverify false
            Func_LogMessage "\033[34m 安装完成 \033[0m" "\033[34m Installation Completed \033[0m" 
        fi

    
    Func_CleanLogFolder
    sleep 2s

    Func_LogMessage "\033[31m 是否创建新的编译配置，默认否，输入任意字符将创建新的配置 \033[0m" "\033[31m Whether to create a new compilation configuration, the default is no, input any character will create a new configuration \033[0m"
    Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    read -t $timer isCreateNewConfig
    if [ ! -n "$isCreateNewConfig" ]; then
        Func_LogMessage "\033[34m OK，不创建新的编译配置 \033[0m" "\033[34m OK, do not create a new compilation configuration \033[0m"
    else
        Func_LogMessage "\033[31m 请输入新的Config文件名，请以xxx.config命名，例如xiaomi3.config \033[0m" "\033[31m Please enter the new Config file name, please name it after xxx.config, for example xiaomi3.config \033[0m"
        read newConfigName
        for conf in ${config_list[*]}; 
        do 
            if [[ $newConfigName = $conf ]]; then
                newConfigName=''
            fi
        done
        until [[ -n "$newConfigName" ]]
        do
            Func_LogMessage "\033[34m 你输入的值为空或者与现有config文件名重复,请重新输入！ \033[0m" "\033[34m The value you entered is empty or duplicates the name of the existing config file, please re-enter! \033[0m"
            read  newConfigName
            for conf in ${config_list[*]}; 
            do 
            if [[ $newConfigName = $conf ]]; then
                newConfigName=''
            fi
            done
        done
    fi



    if [ ! -n "$isCreateNewConfig" ]; then
        echo
        Func_LogMessage "\033[31m 请输入默认OpenwrtAction中的config文件名，默认为$configName \033[0m" "\033[31m Please enter the config file name in the default OpenwrtAction, the default is $configName \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        Func_ConfigList
        until [[ $configNameInp -ge 1 && $configNameInp -le $key ]]
        do
            Func_LogMessage "\033[34m 你输入的 ${configNameInp} 是啥玩应啊，看好了序号，输入数值就行了。 \033[0m" "\033[34m What is the function of the ${configNameInp} you entered? Just take a good look at the serial number and just enter the value. \033[0m"
            Func_LogMessage "\033[31m 请输入默认OpenwrtAction中的config文件名，默认为$configName \033[0m" "\033[31m Please enter the config file name in the default OpenwrtAction, the default is $configName \033[0m"
            Func_ConfigList
        done

        Func_LogMessage "\033[31m 请输入默认lean源码文件夹名称,如果不输入默认$ledeDir,将在($timer秒后使用默认值) \033[0m" "\033[31m Please enter the default lean source folder name, if you do not enter the default $ledeDir, the default value will be used after ($timer seconds) \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        read -t $timer ledeDirInp
        if [ ! -n "$ledeDirInp" ]; then
            Func_LogMessage "\033[34m OK，使用默认值$ledeDir \033[0m" "\033[34m OK, use the default value $ledeDir \033[0m"
        else
            Func_LogMessage "\033[34m 使用 ${ledeDirInp} 作为lean源码文件夹名。 \033[0m" "\033[34m Use ${ledeDirInp} as the lean source folder name. \033[0m"
            echo -e  
            ledeDir=$ledeDirInp
        fi

    else
        configName=$newConfigName
    fi





    echo
    Func_LogMessage "\033[31m 开始同步lean源码.... \033[0m" "\033[31m Start to synchronize lean source code... \033[0m"
    sleep 2s

    cd /home/${userName}
    if [ ! -d "/home/${userName}/${ledeDir}" ];
    then
        git clone https://github.com/coolsnowwolf/lede ${ledeDir}
        cd ${ledeDir}/package/lean
        cd /home/${userName}
        isFirstCompile=1
    else 
        cd ${ledeDir}
        git stash
        git stash drop
        git pull --rebase
        cd /home/${userName}
        isFirstCompile=0
    fi

    # if [ ! -f "/home/${userName}/${ledeDir}/.config" ]; then
    #     isFirstCompile=1
    # else
    #     isFirstCompile=0
    # fi

    # echo $isFirstCompile "dfffffffffffffffffffffffffffff"


    echo 
    Func_LogMessage "\033[31m 准备就绪，请按照导航选择操作.... \033[0m" "\033[31m Ready, please follow the navigation options... \033[0m"
    sleep 2s


    Func_LogMessage "\033[31m 你的编译环境是WSL2吗？ \033[0m" "\033[31m Is your compilation environment WSL2? \033[0m"
    Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
    Func_LogMessage "\033[34m 1. 是(默认) \033[0m" "\033[34m 1. Yes (default) \033[0m" 
    Func_LogMessage "\033[34m 2. 不是  \033[0m" "\033[34m 2. NO \033[0m"
    read -t $timer sysenv
    if [ ! -n "$sysenv" ]; then
            sysenv=1
            Func_LogMessage "\033[34m 输入超时使用默认值 \033[0m" "\033[34m Use default value for input timeout \033[0m"
    fi
    until [[ $sysenv -ge 1 && $sysenv -le 2 ]]
    do
        Func_LogMessage "\033[34m 你输入的 ${sysenv} 是啥玩应啊，看好了序号，输入数值就行了。 \033[0m" "\033[34m What is the function of the ${sysenv} you entered? Just enter the value after taking a good look at the serial number. \033[0m"
        Func_LogMessage "\033[31m 你的编译环境是WSL2吗？ \033[0m" "\033[31m Is your compilation environment WSL2? \033[0m"
        Func_LogMessage "\033[34m 1. 是(默认) \033[0m" "\033[34m 1. Yes (default) \033[0m" 
        Func_LogMessage "\033[34m 2. 不是  \033[0m" "\033[34m 2. NO \033[0m"
        read -t $timer sysenv
        if [ ! -n "$sysenv" ]; then
            sysenv=1
            Func_LogMessage "\033[34m 使用默认值 \033[0m" "\033[34m Use default \033[0m"
        fi
    done
    echo 

    if [ ! -n "$isCreateNewConfig" ]; then
        Func_LogMessage "\033[31m 你接下来要干啥？？？ \033[0m" "\033[31m What are you going to do next? ? ? \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        Func_LogMessage "\033[34m 1. 根据config自动编译固件。(默认) \033[0m" "\033[34m 1. Automatically compile the firmware according to config. (default)  \033[0m"
        Func_LogMessage "\033[34m 2. 我要配置config，配置完毕后自动同步回OpenwrtAction。 \033[0m" "\033[34m 2. I want to configure config, and automatically synchronize back to OpenwrtAction after configuration. \033[0m"
        read -t $timer num
        if [ ! -n "$num" ]; then
                num=1
                Func_LogMessage "\033[34m 使用默认值 \033[0m" "\033[34m Use default \033[0m"
        fi
        # echo $num
        until [[ $num -ge 1 && $num -le 2 ]]
        do
            Func_LogMessage "\033[34m 你输入的 ${num} 是啥玩应啊，看好了序号，输入数值就行了。 \033[0m" "\033[34m What is the function of the ${num} you entered? Just enter the number after you are optimistic about the serial number. \033[0m"
            Func_LogMessage "\033[31m 你接下来要干啥？？？ \033[0m" "\033[31m What are you going to do next? ? ? \033[0m"
            Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
            Func_LogMessage "\033[34m 1. 根据config自动编译固件。(默认) \033[0m" "\033[34m 1.Automatically compile the firmware according to config. (default) \033[0m"
            Func_LogMessage "\033[34m 2. 我要配置config，配置完毕后自动同步回OpenwrtAction。 \033[0m" "\033[34m 2.I want to configure config, and automatically synchronize back to OpenwrtAction after configuration. \033[0m"
            read -t $timer num
            if [ ! -n "$num" ]; then
                num=1
                Func_LogMessage "\033[34m 使用默认值 \033[0m" "\033[34m Use default \033[0m"
            fi
        done

        if [[ $num == 1 ]]
        then
            Func_Compile_Firmware
        fi
    else
        num=2
    fi


    if [[ $num == 2 ]]
    then
        echo
        Func_LogMessage "\033[31m 开始将OpenwrtAction中的自定义feeds注入lean源码中.... \033[0m" "\033[31m Started injecting custom feeds in OpenwrtAction into lean source code... \033[0m"
        sleep 2s
        echo
        cat /home/${userName}/OpenWrtAction/feeds_config/custom.feeds.conf.default > /home/${userName}/${ledeDir}/feeds.conf.default
        cd /home/${userName}/${ledeDir}

        Func_DIY1_Script

        Func_LogMessage "\033[31m 开始clean feeds.... \033[0m" "\033[31m begin update feeds.... \033[0m"
        ./scripts/feeds clean
        echo
        Func_LogMessage "\033[31m 开始update feeds.... \033[0m" "\033[31m begin update feeds.... \033[0m"
        sleep 1s
        ./scripts/feeds update -a | tee -a /home/${userName}/${log_folder_name}/${folder_name}/${log_feeds_update_filename}
        echo
        Func_LogMessage "\033[31m 开始install feeds.... \033[0m" "\033[31m begin install feeds.... \033[0m"
        sleep 1s
        ./scripts/feeds install -a | tee -a /home/${userName}/${log_folder_name}/${folder_name}/${log_feeds_install_filename}
        echo



        Func_DIY2_Script

        if [ ! -n "$isCreateNewConfig" ]; then
            echo
            Func_LogMessage "\033[31m 开始将OpenwrtAction中config文件夹下的${configName}注入lean源码中.... \033[0m" "\033[31m Start to inject ${configName} under the config folder in OpenwrtAction into lean source code... \033[0m"
            sleep 2s
            echo
            cat /home/${userName}/OpenWrtAction/config/${configName} > /home/${userName}/${ledeDir}/.config
        fi

        cd /home/${userName}/${ledeDir}
        make menuconfig
        cat /home/${userName}/${ledeDir}/.config > /home/${userName}/OpenWrtAction/config/${configName}
        cd /home/${userName}/OpenWrtAction
        
        if [ ! -n "$(git config --global user.email)" ]; then
            Func_LogMessage "请输入git Global user.email:" "Please enter git Global user.email:"
            read  gitUserEmail
            until [[ -n "$gitUserEmail" ]]
            do
                Func_LogMessage "\033[34m 不能输入空值 \033[0m" "\033[34m Cannot enter a null value \033[0m"
                read  gitUserEmail
            done
            git config --global user.email "$gitUserEmail"
        fi

        if [ ! -n "$(git config --global user.name)" ]; then
            Func_LogMessage "请输入git Global user.name:" "Please enter git Global user.name:"
            read  gitUserName
            until [[ -n "$gitUserName" ]]
            do
                Func_LogMessage "\033[34m 不能输入空值 \033[0m" "\033[34m Cannot enter a null value \033[0m"
                read  gitUserName
            done
            git config --global user.email "$gitUserName"
        fi


        if [ -n "$(git status -s)" ]; then 
            git add .
            git commit -m "update $configName from local bash"
            git push origin
            Func_LogMessage "\033[31m 已将新配置的config同步回OpenwrtAction \033[0m" "\033[31m The newly configured config has been synchronized back to OpenwrtAction \033[0m"
            sleep 2s
        fi

        Func_LogMessage "\033[31m 是否根据新的config编译？ \033[0m" "\033[31m Is it compiled according to the new config? \033[0m"
        Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
        Func_LogMessage "\033[34m 1. 是(默认值) \033[0m" "\033[34m 1.Yes(Default) \033[0m"
        Func_LogMessage "\033[34m 2. 不编译了。退出 \033[0m" "\033[34m 2.NO, Exit \033[0m"
        read -t $timer num_continue
        if [ ! -n "$num_continue" ]; then
            num_continue=1
        fi
        until [[ $num_continue -ge 1 && $num_continue -le 2 ]]
        do
            Func_LogMessage "\033[34m 你输入的 ${num_continue} 是啥玩应啊，看好了序号，输入数值就行了。 \033[0m" "\033[34m What's the answer for the ${num_continue} you entered? Just enter the number after you are optimistic about the serial number. \033[0m"
            Func_LogMessage "\033[31m 是否根据新的config编译？ \033[0m" "\033[31m Is it compiled according to the new config? \033[0m"
            Func_LogMessage "\033[31m 将会在$timer秒后自动选择默认值 \033[0m" "\033[31m The default value will be automatically selected after $timer seconds \033[0m"
            Func_LogMessage "\033[34m 1. 是(默认值) \033[0m" "\033[34m 1. Yes(Default) \033[0m"
            Func_LogMessage "\033[34m 2. 不编译了。退出  NO, Exit \033[0m" "\033[34m 2.NO, Exit \033[0m"
            read -t $timer num_continue
                if [ ! -n "$num_continue" ]; then
                    num_continue=1
                    Func_LogMessage "\033[34m 使用默认值 \033[0m" "\033[34m Use default \033[0m"
                fi
        done
        
        if [[ $num_continue == 1 ]]; then
            Func_Compile_Firmware
        else
            exit
        fi

    fi

}

# 将编译的固件提交到GitHubRelease
# function UpdateFileToGithubRelease(){
#     # 没思路
# }

# 检测代码更新函数
# function CheckUpdate(){
#     # todo 感觉没啥必要先不写了
# }

#--------------------⬇⬇⬇⬇BashShell⬇⬇⬇⬇--------------------
Func_Main
Func_LogMessage "\033[34m 编译状态:${is_complie_error} \033[0m" "\033[34m Compile Status Code:${is_complie_error} \033[0m"
exit $is_complie_error
