#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Julio del 2013
#
# Script de instalacion y preparacion de indentidades Keystone para Quantum
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

if [ -f /etc/openstack-control-script-config/keystone-extra-idents ]
then
	echo ""
	echo "Aparentemente todas las identidades ya fueron creadas"
	echo "Saliendo del módulo"
	echo ""
	exit 0
fi

source $keystone_admin_rc_file

echo ""
echo "Creando Identidades para QUANTUM"
echo ""

echo "Creando Usuario para Quantum"
keystone user-create --name $quantumuser --pass $quantumpass --email $quantumemail
sync
sleep 5
sync

keystonequantumuserid=`keystone user-list|grep $quantumuser|awk '{print $2}'`
keystoneadminroleid=`keystone role-get $keystoneadminuser|grep id|awk '{print $4}'`
keystoneservicetenantid=`keystone tenant-get $keystoneservicestenant|grep id|awk '{print $4}'`

echo "Agregando Rol para usuario de Quantum"
keystone user-role-add --user-id $keystonequantumuserid --role-id $keystoneadminroleid --tenant-id $keystoneservicetenantid
sync
sleep 5
sync

echo "Creando Servicio para Quantum"
keystone service-create --name $quantumsvce --type network --description "Quantum Networking Service"
sync
sleep 5
sync

keystonequantumserviceid=`keystone service-get $quantumsvce|grep id|awk '{print $4}'`

echo "Creando Endpoint para Quantum"
keystone endpoint-create --region $endpointsregion --service-id $keystonequantumserviceid --publicurl "http://$quantumhost:9696" --adminurl "http://$quantumhost:9696" --internalurl "http://$quantumhost:9696"

echo "Listo"

echo ""
echo "Todas las identidades para QUANTUM han sido creadas"
echo ""
