#!/bin/bash

log_info() {
    current_date_time=$(date +'%m/%d/%Y %H:%M:%S')
    info=${1}
    echo "${current_date_time} INFO : ${info}"
}

echo ""
log_info "Running $0 script"
echo ""

hive_site_xml_file=$(ls /etc/hive/conf/hive-site.xml)
beeline_site_xml_file=$(find /etc -name beeline-site.xml)
cdp_directory="/opt/cloudera/parcels/CDH"
is_cdp_cluster=$([ -d $cdp_directory ] && echo true)

hwc_directory=""
if [ "$is_cdp_cluster" == true ]; then
  hwc_directory="${cdp_directory}/lib/hive_warehouse_connector/"
else
  hwc_directory=""
fi

script_usage() {
  if [ ! -d "$hwc_directory" ]; then
    echo "HWC <$hwc_directory> directory does not exist"
    exit 1
  fi
}

script_usage

[ ! -f "$hive_site_xml_file" ] && { echo "<hive-site.xml> file does not exist on this host or the current user <$(whoami)> does not have access to the files."; exit 1; }
hive_jdbc_url=""
if [ -z "$beeline_site_xml_file" ]; then
    echo "<beeline-site.xml> file does not exist on this host or the current user <$(whoami)> does not have access to the files."
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site_xml_file" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_port=$(grep "hive.zookeeper.client.port" -A1 "$hive_site_xml_file" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    IFS="," read -a zookeeper_quorums <<< $hive_zookeeper_quorum
    hosts=""
    for zookeeper_quorum in "${zookeeper_quorums[@]}"
    do
      hosts+="${zookeeper_quorum}:${hive_zookeeper_port},"
    done
    hive_jdbc_url="jdbc:hive2://${hosts%?}/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2"
else
    hive_jdbc_url=$(grep "beeline.hs2.jdbc.url.hive" -A1 "$beeline_site_xml_file" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
fi

hive_metastore_uri=$(grep "thrift.*9083" "$hive_site_xml_file" |awk -F"<|>" '{print $3}')
hwc_jar=$(find $hwc_directory -name hive-warehouse-connector-assembly-*.jar)
hwc_pyfile=$(find $hwc_directory -name pyspark_hwc-*.zip)

echo ""
echo "spark-shell --master yarn \ "
echo "  --conf spark.sql.hive.hiveserver2.jdbc.url='${hive_jdbc_url}' \ "
echo "  --conf spark.datasource.hive.warehouse.metastoreUri='${hive_metastore_uri}' \ "
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

echo "Run the above command to test HWC in CDP"
