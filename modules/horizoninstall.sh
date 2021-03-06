#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Julio del 2013
#
# Script de instalacion y preparacion de Horizon
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
	mkdir -p /etc/openstack-control-script-config
else
	echo "No puedo acceder a mi archivo de configuración"
	echo "Revise que esté ejecutando el instalador/módulos en el directorio correcto"
	echo "Abortando !!!!."
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/db-installed ]
then
	echo ""
	echo "Proceso de BD verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende de que el proceso de base de datos"
	echo "haya sido exitoso, pero aparentemente no lo fue"
	echo "Abortando el módulo"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/keystone-installed ]
then
	echo ""
	echo "Proceso principal de Keystone verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende del proceso principal de keystone"
	echo "pero no se pudo verificar que dicho proceso haya sido"
	echo "completado exitosamente - se abortará el proceso"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/horizon-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi


echo ""
echo "Instalando paquetes para Horizon"

yum install -y memcached python-memcached openstack-dashboard httpd

echo ""
echo "Listo"
echo ""

source $keystone_admin_rc_file

echo "Configurando el Dashboard"

mkdir -p /etc/openstack-dashboard
cat ./libs/local_settings >  /etc/openstack-dashboard/local_settings
cat ./libs/openstack-dashboard.conf > /etc/httpd/conf.d/openstack-dashboard.conf
cat ./libs/rootredirect.conf > /etc/httpd/conf.d/rootredirect.conf

mkdir /var/log/horizon
chown -R apache.apache /var/log/horizon

sed -r -i "s/CUSTOM_DASHBOARD_dashboard_timezone/$dashboard_timezone/" /etc/openstack-dashboard/local_settings
sed -r -i "s/CUSTOM_DASHBOARD_keystonehost/$keystonehost/" /etc/openstack-dashboard/local_settings
sed -r -i "s/CUSTOM_DASHBOARD_SERVICE_TOKEN/$SERVICE_TOKEN/" /etc/openstack-dashboard/local_settings
sed -r -i "s/CUSTOM_DASHBOARD_keystonememberrole/$keystonememberrole/" /etc/openstack-dashboard/local_settings

sync
sleep 5
sync
echo "" >> /etc/openstack-dashboard/local_settings
echo "SITE_BRANDING = '$brandingname'"  >> /etc/openstack-dashboard/local_settings
echo "" >> /etc/openstack-dashboard/local_settings

if [ $horizondbusage == "yes" ]
then
	case $dbflavor in
	"postgres")
		echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'" >> /etc/openstack-dashboard/local_settings
		echo "DATABASES = {" >> /etc/openstack-dashboard/local_settings
		echo "               'default': {" >> /etc/openstack-dashboard/local_settings
		echo "               'ENGINE': 'django.db.backends.postgresql_psycopg2'," >> /etc/openstack-dashboard/local_settings
		echo "               'NAME': '$horizondbname'," >> /etc/openstack-dashboard/local_settings
		echo "               'USER': '$horizondbuser'," >> /etc/openstack-dashboard/local_settings
		echo "               'PASSWORD': '$horizondbpass'," >> /etc/openstack-dashboard/local_settings
		echo "               'HOST': '$dbbackendhost'," >> /etc/openstack-dashboard/local_settings
		echo "               'default-character-set': 'utf8'" >> /etc/openstack-dashboard/local_settings
		echo "            }" >> /etc/openstack-dashboard/local_settings
		echo "}" >> /etc/openstack-dashboard/local_settings
		;;
	"mysql")
		echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'" >> /etc/openstack-dashboard/local_settings
		echo "DATABASES = {" >> /etc/openstack-dashboard/local_settings
		echo "               'default': {" >> /etc/openstack-dashboard/local_settings
		echo "               'ENGINE': 'django.db.backends.mysql'," >> /etc/openstack-dashboard/local_settings
		echo "               'NAME': '$horizondbname'," >> /etc/openstack-dashboard/local_settings
		echo "               'USER': '$horizondbuser'," >> /etc/openstack-dashboard/local_settings
		echo "               'PASSWORD': '$horizondbpass'," >> /etc/openstack-dashboard/local_settings
		echo "               'HOST': '$dbbackendhost'," >> /etc/openstack-dashboard/local_settings
		echo "               'default-character-set': 'utf8'" >> /etc/openstack-dashboard/local_settings
		echo "            }" >> /etc/openstack-dashboard/local_settings
		echo "}" >> /etc/openstack-dashboard/local_settings
		;;
	esac

	/usr/share/openstack-dashboard/manage.py syncdb --noinput
	/usr/share/openstack-dashboard/manage.py createsuperuser --username=root --email=root@localhost.tld --noinput
	mkdir -p /var/lib/dash/.blackhole
	/usr/share/openstack-dashboard/manage.py syncdb --noinput
else
	echo "CACHE_BACKEND = 'CUSTOM_DASHBOARD_memcached_spec'" >> /etc/openstack-dashboard/local_settings
	sed -r -i "s/CUSTOM_DASHBOARD_memcached_spec/$memcached_spec/" /etc/openstack-dashboard/local_settings
fi

echo "Listo"

echo ""
echo "Aplicando reglas de selinux para apache"
echo "este paso puede tardar algunos minutos"

setsebool -P httpd_can_network_connect on

echo ""

echo "Listo"
echo ""
echo "Aplicando reglas de IPTABLES"
echo ""

iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
service iptables save

echo "Listo"
echo ""
echo "Levantando Servicios"

chown -R apache.apache /var/log/horizon

sync
sleep 2
sync

service httpd restart
chkconfig httpd on

service memcached restart
chkconfig memcached on

testhorizon=`rpm -qi openstack-dashboard|grep -ci "is not installed"`
if [ $testhorizon == "1" ]
then
	echo ""
	echo "Falló la instalación de horizon - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/horizon-installed
	date > /etc/openstack-control-script-config/horizon
fi

echo "Listo"
echo ""
echo "Dashboard instalado - puede entrar al puerto 80 de cualquiera"
echo "de las interfaces de este equipo para poder iniciar el dashboard"
echo "Use la cuenta administrativa principal del Keystone"
echo "Cuenta: $keystoneadminuser"
echo ""



