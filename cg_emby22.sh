#!/bin/bash
#=============================================================
# https://github.com/cgkings/script-store
# bash <(curl -sL git.io/cg_emby)
# File Name: cg_emby.sh
# Author: cgkings
# Created Time : 2021.3.4
# Description:swap一键脚本
# System Required: Debian/Ubuntu
# 感谢wuhuai2020、moerats、github众多作者，我只是整合代码
# Version: 1.0
#=============================================================

#set -e #异常则退出整个脚本，避免错误累加
#set -x #脚本调试，逐行执行并输出执行的脚本命令行

################## 备份emby ##################
bak_emby() {
  remote_choose
  systemctl stop jellyfin-service #结束 jellyfin 进程
  #rm -rf /var/lib/jellyfin/.cache/* #清空cache
  cd /var/lib && tar -cvf jellyfin_bak_"$(date "+%Y-%m-%d")".tar jellyfin #打包/var/lib/jellyfin
  rclone move jellyfin_bak_"$(date "+%Y-%m-%d")".tar "$my_remote":  -vP #上传文件
  systemctl start jellyfin-service
  echo -e "${curr_date} [INFO] jellyfin备份完毕."
}

################## 还原jellyfin ##################
revert_emby() {
    remote_choose
    rclone lsf "$my_remote":/ --include 'jellyfin_bak*' --files-only -F "pt" | sed 's/ /_/g;s/\;/    /g' > ~/.config/rclone/bak_list.txt
    bak_list=($(cat ~/.config/rclone/bak_list.txt))
    bak_name=$(whiptail --clear --ok-button "选择完毕,进入下一步" --backtitle "Hi,欢迎使用。有关脚本问题，请访问: https://github.com/cgkings/script-store 或者 https://t.me/cgking_s (TG 王大锤)。" --title "备份文件选择" --menu --nocancel "注：上下键回车选择,ESC退出脚本！" 18 62 10 \
    "${bak_list[@]}" 3>&1 1>&2 2>&3)
    if [ -z "$bak_name" ]; then
      rm -f ~/.config/rclone/bak_list.txt
      myexit 0
  else
      systemctl stop jellyfin-service #结束 jellyfin 进程
      rclone copy "$my_remote":"$bak_name" /root -vP
      rm -rf /var/lib/jellyfin
      tar -xvf "$bak_name" -C /var/lib && rm -f "$bak_name"
      systemctl start jellyfin-service
      rm -rf ~/.config/rclone/bak_list.txt
      echo -e "${curr_date} [INFO] jellyfin还原完毕."
  fi
}

################## 卸载emby ##################
del_emby() {
  systemctl stop emby-server #结束 emby 进程
  dpkg --purge emby-server
}

################## 主菜单 ##################
main_menu() {
  Mainmenu=$(whiptail --clear --ok-button "选择完毕,进入下一步" --backtitle "Hi,欢迎使用cg_emby。有关脚本问题，请访问: https://github.com/cgkings/script-store 或者 https://t.me/cgking_s (TG 王大锤)。" --title "cg_emby 主菜单" --menu --nocancel "本机emby版本号:$emby_local_version\n挂载进程:$mount_info\n注：本脚本适配emby$emby_version，ESC退出" 19 50 7 \
    "Install" "==>安 装 emby" \
    "Crack" "==>破 解 emby" \
    "Bak" "==>备 份 emby" \
    "Revert" "==>还 原 emby" \
    "Uninstall" "==>卸 载 emby" \
    "Automation" "自用无人值守" \
    "Exit" "退 出" 3>&1 1>&2 2>&3)
  case $Mainmenu in
    Install)
      check_emby
      ;;
    Crack)
      crack_emby
      ;;
    Bak)
      bak_emby
      ;;
    Revert)
      revert_emby
      ;;
    Uninstall)
      del_emby
      ;;
    Automation)
      whiptail --clear --ok-button "回车开始执行" --backtitle "Hi,欢迎使用cg_toolbox。有关脚本问题，请访问: https://github.com/cgkings/script-store 或者 https://t.me/cgking_s (TG 王大锤)。" --title "无人值守模式" --checklist --separate-output --nocancel "请按空格及方向键来多选，ESC退出" 20 54 13 \
        "Back" "返回上级菜单(Back to main menu)" off \
        "mount" "挂载gd" off \
        "swap" "自动设置2倍物理内存的虚拟内存" off \
        "install" "安装emby" off \
        "revert" "还原emby" off 2> results
      while read choice; do
        case $choice in
          Back)
            main_menu
            break
            ;;
          mount)
            remote_choose
            td_id_choose
            dir_choose
            bash <(curl -sL git.io/cg_mount.sh) s $my_remote $td_id $mount_path
            ;;
          swap)
            bash <(curl -sL git.io/cg_swap) a
            ;;
          install)
            check_emby
            ;;
          revert)
            revert_emby
            ;;
          *)
            myexit 0
            ;;
        esac
      done < results
      rm results
      ;;
    Exit | *)
      myexit 0
      ;;
  esac
}

################## 执行命令 ##################
check_sys
check_rclone
check_mount
main_menu
