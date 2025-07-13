URL="https://raw.githubusercontent.com/GreatMedivack/files/master/list.out"
date=$(date +%d\%m\%y)
server="${1:-DefaultServer}"
list="/opt/tasks/list.out"

mkdir -p /opt/tasks

#1
wget -O "$list" "$URL"
#2
failed_file="/opt/tasks/${server}_${date}_failed.out"
awk '$3 == "CrashLoopBackOff" || $3 == "Error" {print $1}' "$list" > /opt/tasks/failed_fail.out
sed -E 's/-[a-z0-9]{9,}-[a-z0-9]{5,}$//' /opt/tasks/failed_fail.out > "$failed_file"
rm /opt/tasks/failed_fail.out
running_file="/opt/tasks/${server}_${date}_running.out"
awk '$3 == "Running" {print $1}' "$list" > /opt/tasks/running_file.out
sed -E 's/-[a-z0-9]{9,}-[a-z0-9]{5,}$//' /opt/tasks/running_file.out > "$running_file"
rm /opt/tasks/running_file.out
#3
report_file="/opt/tasks/${server}_${date}_report.out"
running_count=$(wc -l < "$running_file")
echo "Файлов в статусе running: $running_count" > "$report_file"
failed_count=$(wc -l < "$failed_file")
echo "Файлов в статусе failed: $failed_count" >> "$report_file"
user_name=$(whoami)
echo "Имя системного пользователя: $user_name" >> "$report_file"
echo "Дата: $date" >> "$report_file"
chmod a+r "$report_file"
#4
archive_dir="/opt/tasks/archives"
mkdir -p "$archive_dir"
archive_path="${archive_dir}/${server}_${date}.tar.gz"
if [ ! -f "$archive_path" ]; then
    tar -czf "$archive_path" \
        "$failed_file" \
        "$running_file" \
        "$report_file"
fi
#5
find /opt/tasks/* -maxdepth 1 ! -name "archives" ! -name "$(basename "$archive_path")" -exec rm -f {} +
#6
if tar -tzf "$archive_path" > /dev/null 2>&1; then
    echo "Архив успешно создан"
else
    echo "Ошибка: архив повреждён или не был создан."
    exit 1
fi
