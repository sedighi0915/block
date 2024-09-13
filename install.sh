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
        "irancell")
            grep -E "MTN Irancell" iran_ips.html | awk -F'</td><td>' '{print $1}' | sed 's/<td>//g' > irancell_ips.txt
            ;;
        "mci")
            grep -E "MCI" iran_ips.html | awk -F'</td><td>' '{print $1}' | sed 's/<td>//g' > mci_ips.txt
            ;;
        "rightel")
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

# انتخاب ISP
echo "کدام ISP را می‌خواهید مسدود کنید؟ (irancell, mci, rightel)"
read isp

# اجرای مراحل
download_ranges
extract_ips $isp

case $isp in
    "irancell")
        block_ips "irancell_ips.txt"
        ;;
    "mci")
        block_ips "mci_ips.txt"
        ;;
    "rightel")
        block_ips "rightel_ips.txt"
        ;;
esac

echo "رنج‌های IP برای $isp مسدود شدند."
