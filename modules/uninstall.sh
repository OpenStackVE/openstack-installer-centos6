#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Julio del 2013
#
# Script de desinstalacion de OS para Centos 6
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
else
	echo "No puedo acceder a mi archivo de configuración"
	echo "Revise que esté ejecutando el instalador en su directorio"
	echo "Abortando !!!!."
	echo ""
	exit 0
fi

clear

echo "Bajando y desactivando Servicios de OpenStack"

/usr/local/bin/openstack-control.sh stop
/usr/local/bin/openstack-control.sh disable
service mongod stop
chkconfig mongod off
killall -9 -u mongodb
killall -9 mongod
killall -9 dnsmasq

echo "Eliminando Paquetes de OpenStack"

yum -y erase openstack-glance \
	openstack-utils \
	openstack-selinux \
	openstack-keystone \
	python-psycopg2 \
	qpid-cpp-server \
	qpid-cpp-server-ssl \
	qpid-cpp-client \
	scsi-target-utils \
	sg3_utils \
	openstack-cinder \
	openstack-quantum \
	openstack-quantum-* \
	openstack-nova-* \
	openstack-swift-* \
	openstack-ceilometer-* \
	mongodb-server \
	mongodb \
	haproxy \
	rabbitmq-server \
	openstack-dashboard \
	openstack-packstack \
	sysfsutils \
	genisoimage \
	libguestfs \
	rabbitmq-server \
	python-django-openstack-auth \
	python-keystone*

if [ $cleanundeviceatuninstall == "yes" ]
then
	rm -rf /srv/node/$swiftdevice/accounts
	rm -rf /srv/node/$swiftdevice/containers
	rm -rf /srv/node/$swiftdevice/objects
	rm -rf /srv/node/$swiftdevice/tmp
	chown -R root:root /srv/node/
	restorecon -R /srv
fi

echo "Eliminando Usuarios de Servicios de OpenStack"

userdel -f -r keystone
userdel -f -r glance
userdel -f -r cinder
userdel -f -r quantum
userdel -f -r nova
userdel -f -r mongodb
userdel -f -r ceilometer
userdel -f -r swift
userdel -f -r rabbitmq

echo "Eliminando Archivos remanentes"

rm -fr /etc/glance \
	/etc/keystone \
	/var/log/glance \
	/var/log/keystone \
	/var/lib/glance \
	/var/lib/keystone \
	/etc/cinder \
	/var/lib/cinder \
	/var/log/cinder \
	/etc/sudoers.d/cinder \
	/etc/tgt \
	/etc/quantum \
	/var/lib/quantum \
	/var/log/quantum \
	/etc/sudoers.d/quantum \
	/etc/nova \
	/var/log/nova \
	/var/lib/nova \
	/etc/sudoers.d/nova \
	/etc/openstack-dashboard \
	/var/log/horizon \
	/etc/sysconfig/mongod \
	/var/lib/mongodb \
	/etc/ceilometer \
	/var/log/ceilometer \
	/var/lib/ceilometer \
	/etc/ceilometer-collector.conf \
	/etc/swift/ \
	/var/lib/swift \
	/tmp/keystone-signing-swift \
	/etc/openstack-control-script-config \
	/var/lib/keystone-signing-swift \
	/var/lib/rabbitmq \
	$dnsmasq_config_file \
	/usr/local/bin/vm-number-by-states.sh \
	/usr/local/bin/vm-total-cpu-and-ram-usage.sh \
	/usr/local/bin/vm-total-disk-bytes-usage.sh \
	/usr/local/bin/node-cpu.sh \
	/usr/local/bin/node-memory.sh \
	/etc/cron.d/openstack-monitor.crontab \
	/etc/dnsmasq-quantum.d \
	/var/tmp/node-cpu.txt \
	/var/tmp/node-memory.txt \
	/var/tmp/packstack \
	/var/tmp/vm-cpu-ram.txt \
	/var/tmp/vm-disk.txt \
	/var/tmp/vm-number-by-states.txt

service crond restart

rm -f /root/keystonerc_admin
rm -f /root/ks_admin_token
rm -f /usr/local/bin/openstack-control.sh
rm -f /usr/local/bin/openstack-log-cleaner.sh
rm -f /etc/httpd/conf.d/openstack-dashboard.conf*
rm -f /etc/httpd/conf.d/rootredirect.conf*

if [ -f /etc/snmp/snmpd.conf.pre-openstack ]
then
	rm -f /etc/snmp/snmpd.conf
	mv /etc/snmp/snmpd.conf.pre-openstack /etc/snmp/snmpd.conf
	service snmpd restart
else
	service snmpd stop
	yum -y erase net-snmp
	rm -rf /etc/snmp
fi

echo "Reiniciando Apache sin archivos del Dashboard"

service httpd restart
service memcached restart

echo "Limpiando IPTABLES"

service iptables stop
echo "" > /etc/sysconfig/iptables

if [ $dbinstall == "yes" ]
then

	echo ""
	echo "Desinstalando software de Base de Datos"
	echo ""
	case $dbflavor in
	"mysql")
		service mysqld stop
		sync
		sleep 5
		sync
		yum -y erase mysql-server
		userdel -r mysql
		rm -f /root/.my.cnf /etc/my.cnf
		;;
	"postgres")
		service postgresql stop
		sync
		sleep 5
		sync
		yum -y erase postgresql-server
		userdel -r postgres
		rm -f /root/.pgpass
		;;
	esac
fi

echo ""
echo "Desinstalación completada"
echo ""

