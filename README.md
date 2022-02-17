# nfs-hw5

### Цель 
Научиться самостоятельно развернуть сервис NFS и подключить к нему клиента

- `vagrant up` должен поднимать 2 настроенных виртуальных машины
(сервер NFS и клиента) без дополнительных ручных действий;
- на сервере NFS должна быть подготовлена и экспортирована
директория;
- в экспортированной директории должна быть поддиректория
с именем __upload__ с правами на запись в неё;
- экспортированная директория должна автоматически монтироваться
на клиенте при старте виртуальноймашины (systemd, autofs или fstab -
любым способом);
- монтирование и работа NFS на клиенте должна быть организована
с использованием NFSv3 по протоколу UDP;
- firewall должен быть включен и настроен как на клиенте,
так и на сервере.

# Описание файлов .sh
# nfsc_script.sh
  
NFS утилиты:

`yum install nfs-utils -y`

Включаем firewall и проверяем, что он работает:

  `systemctl enable firewalld --now`
  `systemctl status firewalld`
  
Добавляем в __/etc/fstab__ строку_

  `echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab`
  
Автоматическая генерация systemd units в каталоге `/run/systemd/generator/`, которые производят монтирование при первом обращении к каталогу `/mnt/`:

  `systemctl daemon-reload`
  `systemctl restart remote-fs.target`
  
# nfss_script.sh
  
  NFS утилиты:

`yum install nfs-utils -y`

Включаем firewall и проверяем, что он работает:

  `systemctl enable firewalld --now`
  `systemctl status firewalld`
  
Разрешаем в firewall доступ к сервисам NFS
  
  `firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent`
  `firewall-cmd --reload`

Включаем сервер NFS

  `systemctl enable nfs --now`

Проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,20048/tcp, 111/udp, 111/tcp
  
  `ss -tnplu`

Создаем и настраиваем директорию, которая будет экспортирована

  `mkdir -p /srv/share/upload`
  `chown -R nfsnobody:nfsnobody /srv/share`
  `chmod 0777 /srv/share/upload`

Создаем в файле __/etc/exports__ структуру, которая позволит экспортировать ранее созданную директорию

  `echo "/srv/share 192.168.50.11/32(rw,sync,root_squash)" >> /etc/exports`

Экспортируем ранее созданную директорию
  
  `exportfs -r`
  
 # Vagrantfile
 
``` 
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
    config.vm.box = "centos/7"
    config.vm.box_version = "2004.01"

config.vm.provider "virtualbox" do |v|
    v.memory = 256
    v.cpus = 1
end

config.vm.define "nfss" do |nfss|
    nfss.vm.network "private_network", ip: "192.168.50.10",
virtualbox__intnet: "net1"
    nfss.vm.hostname = "nfss"
    nfss.vm.provision "shell", path: "nfss_script.sh"
end

config.vm.define "nfsc" do |nfsc|
    nfsc.vm.network "private_network", ip: "192.168.50.11",
virtualbox__intnet: "net1"
    nfsc.vm.hostname = "nfsc"
    nfsc.vm.provision "shell", path: "nfsc_script.sh"
end
end
```

# Проверка

# client (nfsc)

Проверям статус фаервола

  `systemctl status firewalld`

  ```
  ● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2022-02-17 16:16:10 UTC; 24min ago
     Docs: man:firewalld(1)
 Main PID: 3522 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3522 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

  ```

Проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,20048/tcp, 111/udp, 111/tcp 

  ```
  Netid  State      Recv-Q Send-Q                                                                                                              Local Address:Port                                                                                                                             Peer Address:Port              
  udp    UNCONN     0      0                                                                                                                               *:807                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                       127.0.0.1:323                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                               *:68                                                                                                                                          *:*                  
  udp    UNCONN     0      0                                                                                                                               *:60747                                                                                                                                       *:*                  
  udp    UNCONN     0      0                                                                                                                               *:111                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                       127.0.0.1:884                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                               *:54428                                                                                                                                       *:*                  
  udp    UNCONN     0      0                                                                                                                               *:930                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                           [::1]:323                                                                                                                                      [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:34635                                                                                                                                    [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:111                                                                                                                                      [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:930                                                                                                                                      [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:36347                                                                                                                                    [::]:*              
  ```
  
Заходим в директорию `/mnt/` и проверяем успешность монтирования

При успехе вывод должен примерно соответствовать этому

  ```
  systemd-1 on /mnt type autofs (rw,relatime,fd=49,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=26631)
  192.168.50.10:/srv/share/ on /mnt type nfs  (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)

  ```


# server (nfss)

Проверям статус фаервола

  `systemctl status firewalld`
  
  ```
  ● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2022-02-17 16:16:51 UTC; 24min ago
     Docs: man:firewalld(1)
 Main PID: 3525 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3525 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid
[vagrant@nfsc upload]$ 

  ```

Проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,20048/tcp, 111/udp, 111/tcp 

  ```
  Netid  State      Recv-Q Send-Q                                                                                                              Local Address:Port                                                                                                                             Peer Address:Port              
  udp    UNCONN     0      0                                                                                                                       127.0.0.1:323                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                               *:68                                                                                                                                          *:*                  
  udp    UNCONN     0      0                                                                                                                               *:20048                                                                                                                                       *:*                  
  udp    UNCONN     0      0                                                                                                                       127.0.0.1:877                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                               *:111                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                               *:928                                                                                                                                         *:*                  
  udp    UNCONN     0      0                                                                                                                               *:49337                                                                                                                                       *:*                  
  udp    UNCONN     0      0                                                                                                                               *:46047                                                                                                                                       *:*                  
  udp    UNCONN     0      0                                                                                                                               *:2049                                                                                                                                        *:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:43317                                                                                                                                    [::]:*                  
  udp    UNCONN     0      0                                                                                                                           [::1]:323                                                                                                                                      [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:20048                                                                                                                                    [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:111                                                                                                                                      [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:35696                                                                                                                                    [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:928                                                                                                                                      [::]:*                  
  udp    UNCONN     0      0                                                                                                                            [::]:2049                                                                                                                                     [::]:*                            
  ```
  
Проверяем экспортированную директорию следующей командои

`exportfs -s`

Вывод должен быть аналогичен этому:

  ```
  /srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
  ```
  
  
  
  # Проверка работоспособности
  
- заходим на сервер
- заходим в каталог `/srv/share/upload`
- создаём тестовыйфайл `touch check_file`
- заходим на клиент
- заходим в каталог `/mnt/upload`
- проверяем наличие ранее созданного файла
  ```
  -rw-r--r--. 1 root      root       0 Feb 17 16:51 check_file

  ```
- создаём тестовыйфайл `touch client_file`
- проверяем, что файл успешно создан

  ```
  -rw-r--r--. 1 root      root       0 Feb 17 16:51 check_file
  -rw-rw-r--. 1 vagrant   vagrant    0 Feb 17 16:52 client_file
  ```
