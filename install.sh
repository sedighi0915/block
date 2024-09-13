#!/bin/bash

# نصب پیش‌نیازها
sudo apt update
sudo apt install -y curl ufw

# دریافت رنج‌های IP از IP2Location
download_ranges() {
    echo "دریافت رنج‌های IP از IP2Location..."
    curl -o iran_ips.html "https://lite.ip2location.com/iran-(islamic-republic-of)-ip-address-ranges"
}

# استخراج رنج‌های IP از HTML
extract_ips() {
    local isp=$1
    case $isp in
        1) # Irancell
            grep -E "MTN Irancell" iran_ips.html | awk -F'</td><td>' '{print $1}' | sed 's/<td>//g' > irancell_ips.txt
            ;;
        2) # MCI (Hamrah Aval)
            grep -E "MCI" iran_ips.html | awk -F'</td><td>' '{print $1}' | sed 's/<td>//g' > mci_ips.txt
            ;;
        3) # Rightel
            grep -E "Rightel" iran_ips.html | awk -F'</td><td>' '{print $1}' | sed 's/<td>//g' > rightel_ips.txt
            ;;
        *)
            echo "ISP نامعتبر است!"
            exit 1
            ;;
    esac
}

# مسدود کردن IPها
block_ips() {
    local file=$1
    while read -r ip_range; do
        sudo ufw deny from "$ip_range"
    done < "$file"
    sudo ufw reload
}

# بازنشانی تنظیمات UFW
reset_ufw() {
    echo "بازنشانی تنظیمات UFW به حالت اولیه..."
    sudo ufw reset
    sudo ufw enable
}

# انتخاب عملیات
echo "چه کاری می‌خواهید انجام دهید؟"
echo "1. مسدود کردن رنج‌های IP"
echo "2. بازنشانی تنظیمات به حالت اولیه"
read action

if [ "$action" -eq 1 ]; then
    # انتخاب ISP
    echo "کدام ISP را می‌خواهید مسدود کنید؟"
    echo "1. ایرانسل"
    echo "2. همراه اول"
    echo "3. رایتل"
    read isp

    # اجرای مراحل
    download_ranges
    extract_ips $isp

    case $isp in
        1)
            block_ips "irancell_ips.txt"
            ;;
        2)
            block_ips "mci_ips.txt"
            ;;
        3)
            block_ips "rightel_ips.txt"
            ;;
    esac

    echo "رنج‌های IP برای ISP انتخابی مسدود شدند."
    
elif [ "$action" -eq 2 ]; then
    reset_ufw
    echo "تنظیمات UFW به حالت اولیه بازنشانی شد."
else
    echo "عملیات نامعتبر است!"
fi
