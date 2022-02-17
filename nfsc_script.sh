#!/bin/bash
#NFS утилиты
yum install nfs-utils -y
#включаем firewall и проверяем, что он работает
systemctl enable firewalld --now
#systemctl status firewalld
#добавляем в __/etc/fstab__ строку_
echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
#автоматическая генерация systemd units в каталоге `/run/systemd/generator/`, которые производят монтирование при первом обращении к каталогу `/mnt/`
systemctl daemon-reload
systemctl restart remote-fs.target















