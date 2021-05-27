#!/bin/bash
set -e

echo "Running $0 script"

hive_site_xml_file="/etc/hive/conf/hive-site.xml"
cdp_directory="/opt/cloudera/parcels/CDH"
is_cdp_cluster=`[ -d $cdp_directory ] && echo true`

hwc_directory=""
if[ $is_cdp_cluster ]; then
  hwc_directory="${cdp_directory}/lib/hive_warehouse_connector/"
else
  hwc_directory=""
fi

if[ ! -d $hwc_directory ]; then
  echo "HWC directory $hwc_directory does not exist"
  exit 0
fi

if [ -r "$hive_site_xml_file" ]; then

    hive_metastore_uri=$(grep -e "thrift.*9083" "$hive_site_xml_file" |awk -F"<|>" '{print $3}')
    hive_jdbc_url=$(grep "hive.zookeeper.quorum" -A1 "$hive_site_xml_file" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hwc_jar=$(find $hwc_directory -name hive-warehouse-connector-assembly-*.jar)
    hwc_pyfile=$(find $hwc_directory -name pyspark_hwc-*.zip)

    #echo -e "To apply this configuration cluster wide, copy and paste the following list of properties in Ambari UI -> Spark2 -> Configs -> Advanced -> Custom spark2-defaults (Bulk Property Add mode)\n"
    echo -e "spark.sql.hive.hiveserver2.jdbc.url=jdbc:hive2://${hive_jdbc_url}"
    echo -e "spark.datasource.hive.warehouse.metastoreUri=${hive_metastore_uri}"
    echo -e "spark.datasource.hive.warehouse.load.staging.dir=/tmp"
    echo -e "spark.jars=${hwc_jar}"
    echo -e "spark.submit.pyFiles=${hwc_pyfile}"
    echo -e "spark.datasource.hive.warehouse.read.via.llap=false"
    echo -e "spark.datasource.hive.warehouse.read.mode=DIRECT_READER_V2"
    echo -e "spark.sql.hive.hwc.execution.mode=spark"
    echo -e "spark.datasource.hive.warehouse.read.jdbc.mode=cluster"
    echo -e "spark.security.credentials.hiveserver2.enabled=false"
    echo -e "spark.sql.extensions=com.qubole.spark.hiveacid.HiveAcidAutoConvershension"
    echo -e "spark.kryo.registrator=com.qubole.spark.hiveacid.util.HiveAcidKyroRegistrator"
   
    echo -e "\n### Save and restart."
    echo -e "\nNote: In a kerberized environment the property spark.security.credentials.hiveserver2.enabled has to be set to TRUE for deploy-mode cluster, i.e.:\n spark-submit --conf s
park.security.credentials.hiveserver2.enabled=true"

    echo -e "\nIf you'd like to test this per job instead of cluster wide, then use the following command as an example:\n"
    echo -e "spark-shell --master yarn \"
    echo -e "\t --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \" 
    echo -e "\t --conf spark.datasource.hive.warehouse.metastoreUri=$hive_metastore_uris \"
    echo -e "\t --conf spark.hadoop.hive.llap.daemon.service.hosts=$hive_llap_daemon_service_hosts \"
    echo -e "\t --conf spark.jars=$hwc_jar \"
    echo -e "\t --conf spark.submit.pyFiles=$hwc_pyfile \"
    echo -e "\t --conf spark.security.credentials.hiveserver2.enabled=false \"
    echo -e "\t --conf spark.sql.hive.hiveserver2.jdbc.url=\"$hive_jdbc_url \" 
    echo -e "\t --conf spark.sql.hive.zookeeper.quorum=\"$hive_zookeeper_quorum\" "

    echo -e "Once in the Scala REPL, run the following snippet example to test basic conectivity:\n"
    echo -e "import com.hortonworks.hwc.HiveWarehouseSession"
    echo -e "import com.hortonworks.hwc.HiveWarehouseSession._"
    echo -e "val hive = HiveWarehouseSession.session(spark).build()"
    echo -e "hive.showDatabases().show()\n"

else
     echo -e "$hive_site_xml_file doesn't exist on this host, or the current user $(whoami) doesn't have access to the files.\n"
fi
