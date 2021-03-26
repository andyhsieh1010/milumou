# Filename: Backup_log.sh
# Author: Structure
# Version: 2020/10/13

if [ $(ls |grep -cvE ".sh|backup_log") -ne 0 ]; then
    folder_backup="backup_log_$(date +"%Y%m%d_%H%M")"
    mkdir $folder_backup
    mv $(ls |grep -vE ".sh|backup_log") $folder_backup
    echo -e "=== Test log backup is completed! ==="
else
    echo "=== There is no test log can be backed up ==="
fi
