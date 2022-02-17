#!/bin/bash
#NFS утилиты
yum install nfs-utils -y
#включаем firewall и проверяем, что он работает
systemctl enable firewalld --now
systemctl status firewalld
#разрешаем в firewall доступ к сервисам NFS
firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent
firewall-cmd --reload
#включаем сервер NFS
systemctl enable nfs --now
#проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,20048/tcp, 111/udp, 111/tcp
#ss -tnplu
#создаем и настраиваем директорию, которая будет экспортирована
mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload
#создаем в файле __/etc/exports__ структуру, которая позволит экспортировать ранее созданную директорию
echo "/srv/share 192.168.50.11/32(rw,sync,root_squash)" >> /etc/exports
#экспортируем ранее созданную директорию
exportfs -r

