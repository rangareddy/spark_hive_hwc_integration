#!/bin/bash

echo ""
echo "Running $0 script"
echo ""

hive_site_xml_file=$(ls /etc/hive/conf/hive-site.xml)
beeline_site_xml_file=$(ls /etc/hive/*_tez/beeline-site.xml)
cdp_directory="/opt/cloudera/parcels/CDH"
is_cdp_cluster=$([ -d $cdp_directory ] && echo true)

hwc_directory=""
if [ "$is_cdp_cluster" == true ]; then
  hwc_directory="${cdp_directory}/lib/hive_warehouse_connector/"
else
  hwc_directory=""
fi

if [ ! -d "$hwc_directory" ]; then
  echo "HWC directory $hwc_directory does not exist"
  exit 1
fi

[ ! -f "$hive_site_xml_file" ] && { echo "${hive_site_xml_file} does not exist on this host, or the current user <$(whoami)> does not have access to the files."; exit 1; }
[ ! -f "$beeline_site_xml_file" ] && { echo "${beeline_site_xml_file} does not exist on this host, or the current user <$(whoami)> does not have access to the files."; exit 1; }

hive_metastore_uri=$(grep "thrift.*9083" "$hive_site_xml_file" |awk -F"<|>" '{print $3}')
hive_jdbc_url=$(grep "beeline.hs2.jdbc.url.hive" -A1 "$beeline_site_xml_file" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
hwc_jar=$(find $hwc_directory -name hive-warehouse-connector-assembly-*.jar)
hwc_pyfile=$(find $hwc_directory -name pyspark_hwc-*.zip)

echo ""
echo "spark-shell --master yarn \ "
echo "  --conf spark.sql.hive.hiveserver2.jdbc.url=jdbc:hive2://${hive_jdbc_url} \ "
echo "  --conf spark.datasource.hive.warehouse.metastoreUri=${hive_metastore_uri} \ "
echo "  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \ "
echo "  --conf spark.jars=${hwc_jar} \ "
echo "  --conf spark.submit.pyFiles=${hwc_pyfile} \ "
echo "  --conf spark.datasource.hive.warehouse.read.via.llap=false \ "
echo "  --conf spark.datasource.hive.warehouse.read.mode=DIRECT_READER_V2 \ "
echo "  --conf spark.sql.hive.hwc.execution.mode=spark \ "
echo "  --conf spark.datasource.hive.warehouse.read.jdbc.mode=cluster \ "
echo "  --conf spark.security.credentials.hiveserver2.enabled=false \ "
echo "  --conf spark.sql.extensions=com.qubole.spark.hiveacid.HiveAcidAutoConvershension \ "
echo "  --conf spark.kryo.registrator=com.qubole.spark.hiveacid.util.HiveAcidKyroRegistrator"
echo ""

#echo "spark.sql.hive.hiveserver2.jdbc.url=${hive_jdbc_url}"
#echo "spark.datasource.hive.warehouse.metastoreUri=${hive_metastore_uri}"
#echo "spark.datasource.hive.warehouse.load.staging.dir=/tmp"
#echo "spark.jars=${hwc_jar}"
#echo "spark.submit.pyFiles=${hwc_pyfile}"
#echo "spark.datasource.hive.warehouse.read.via.llap=false"
#echo "spark.datasource.hive.warehouse.read.mode=DIRECT_READER_V2"
#echo "spark.sql.hive.hwc.execution.mode=spark"
#echo "spark.datasource.hive.warehouse.read.jdbc.mode=cluster"
#echo "spark.security.credentials.hiveserver2.enabled=false"
#echo "spark.sql.extensions=com.qubole.spark.hiveacid.HiveAcidAutoConvershension"
#echo "spark.kryo.registrator=com.qubole.spark.hiveacid.util.HiveAcidKyroRegistrator"
