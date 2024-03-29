#!/bin/bash

#################################################################################################################################
#                                                                                                                               #
#    Name		: collect_spark_hwc_info.sh                                                                             #
#    Purpose		: Used to generate the spark-shell/pyspark command and run sample code in CDP cluster                   #
#    Author		: Ranga Reddy                                                                                           #
#    Created Date	: 02-Feb-2022                                                                                           #   
#    Version		: v1.0													#												        #
#                                                                                                                               #
#################################################################################################################################

# log_info() is used to log the message based on logging level. By default logging level will be INFO.
log_info() {
    if [[ "$#" -gt 0 ]]; then
        current_date_time=$(date +'%m/%d/%Y %T')
        info_level="INFO"
        info_message=${1}
        if [[ "$#" -gt 1 ]]; then
           info_level=${1}
           info_message=${2}
        fi
        Pattern="${current_date_time} ${info_level} : ${info_message}"
        echo "${Pattern}"
    fi
}

echo ""
log_info "Running $0 script"

hive_site_xml_file_path="/etc/hive/conf/hive-site.xml"
hive_site_xml_file=$(ls ${hive_site_xml_file_path})
beeline_site_xml_file=$(find /etc -name beeline-site.xml)
HWC_DIRECTORY="/opt/cloudera/parcels/CDH/lib/hive_warehouse_connector/"

IS_SPARK_SHELL="${IS_SPARK_SHELL:-true}"
IS_PYSPARK_SHELL="${IS_PYSPARK_SHELL:-false}"

`type klist > /dev/null;` && IS_KERBERIZED=true || IS_KERBERIZED=false

script_usage() {
    ERROR_MSG=""

    if [ ! -d "$HWC_DIRECTORY" ]; then
    	ERROR_MSG="HWC <$HWC_DIRECTORY> directory does not exist on this host or the current user <$(whoami)> does not have access to ${HWC_DIRECTORY directory} directory."
    fi

    if [ ! -f "$hive_site_xml_file" ]; then
    	ERROR_MSG="<hive-site.xml> file does not exist on this host or the current user <$(whoami)> does not have access to ${hive_site_xml_file_path} file."
    fi

    if [ ! -z "$ERROR_MSG" ]; then
        log_info "ERROR" ${ERROR_MSG}
        exit 1
    fi
}

script_usage

hive_jdbc_url=""
if [ -z "$beeline_site_xml_file" ]; then
    #log_info "WARN" "<beeline-site.xml> file does not exist on this host or the current user <$(whoami)> does not have access to the files."
    
    hive_zookeeper_quorum=$(grep "hive.zookeeper.quorum" -A1 "$hive_site_xml_file" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_zookeeper_port=$(grep "hive.zookeeper.client.port" -A1 "$hive_site_xml_file" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    
    IFS="," read -a zookeeper_quorums <<< $hive_zookeeper_quorum
    hosts=""
    for zookeeper_quorum in "${zookeeper_quorums[@]}"
    do
    	hosts+="${zookeeper_quorum}:${hive_zookeeper_port},"
    done
    
    if [ -z "${hosts}" ]; then
    	log_info "ERROR" "Unable to construct the hive.hiveserver2.jdbc.url"
    	exit 1
    fi
    hive_jdbc_url="jdbc:hive2://${hosts%?}/default;retries=5;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2"
    
    #hive_jdbc_url="jdbc:hive2://<domain name>:<port>/default;principal=hive/_HOST@ROOT.HWX.SITE;retries=5;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2"

else
    beeline_jdbc_url_default=$(grep "beeline.hs2.jdbc.url.default" -A1 "${beeline_site_xml_file}" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
    hive_jdbc_url=$(grep "beeline.hs2.jdbc.url.${beeline_jdbc_url_default}" -A1 "${beeline_site_xml_file}" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
fi

hive_metastore_uri=$(grep "thrift.*9083" "$hive_site_xml_file" |awk -F"<|>" '{print $3}')
hwc_jar=$(find $HWC_DIRECTORY -name hive-warehouse-connector-assembly-*.jar)

# Generating spark-shell script and code
generate_spark_shell_script() {
	echo ""
	log_info "Launch the spark-shell by coping the following command"
	echo "======================================================"
	echo "spark-shell --master yarn \ "
	echo "  --conf spark.sql.hive.hiveserver2.jdbc.url='${hive_jdbc_url}' \ "
	echo "  --conf spark.datasource.hive.warehouse.metastoreUri='${hive_metastore_uri}' \ "
	echo "  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \ "
	echo "  --conf spark.jars=${hwc_jar} \ "
	echo "  --conf spark.datasource.hive.warehouse.read.via.llap=false \ "
	echo "  --conf spark.datasource.hive.warehouse.read.mode=DIRECT_READER_V2 \ "
	echo "  --conf spark.sql.hive.hwc.execution.mode=spark \ "
	echo "  --conf spark.datasource.hive.warehouse.read.jdbc.mode=cluster \ "
	echo "  --conf spark.sql.extensions=com.hortonworks.spark.sql.rule.Extensions \ "
	#echo "  --conf spark.sql.extensions=com.qubole.spark.hiveacid.HiveAcidAutoConvershension \ "
	echo "  --conf spark.kryo.registrator=com.qubole.spark.hiveacid.util.HiveAcidKyroRegistrator \ "
	if [ ${IS_KERBERIZED} ]; then
	    echo "  --conf spark.security.credentials.hiveserver2.enabled=true \ "
	    user_prin=$(grep "hive.server2.authentication.kerberos.principal" -A1 "${hive_site_xml_file}" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
	    echo "  --conf spark.sql.hive.hiveserver2.jdbc.url.principal=${user_prin}"
	else
	    echo "  --conf spark.security.credentials.hiveserver2.enabled=false"
	fi
	echo "======================================================"
	echo ""

	echo "After launching the spark-shell run the following code"
	echo "------------------------------------------------------"
	echo ""
	echo "import com.hortonworks.hwc.HiveWarehouseSession"
	echo "import com.hortonworks.hwc.HiveWarehouseSession._"
	echo "val hwc = HiveWarehouseSession.session(spark).build()"
	echo "val tableName = \"hwc_test_table\""
	echo ""
	echo "// Creating a Hive table if not exists"
	echo "hwc.createTable(tableName).ifNotExists().column(\"id\", \"bigint\").column(\"name\", \"string\").column(\"age\", \"int\").create()"
	echo ""
	echo "// Saving the data to Hive table"
	echo "val dataFrame = Seq((1l, \"Ranga\", 34),(2l, \"Nishanth\", 30)).toDF(\"id\", \"name\", \"age\")"
	echo "dataFrame.write.format(\"com.hortonworks.spark.sql.hive.llap.HiveWarehouseConnector\").mode(\"overwrite\").option(\"table\", tableName).save()"
	echo ""
	echo "// Reading the data from Hive table"
	echo "hwc.executeQuery(s\"select * from \${tableName}\").show"
	echo ""
	echo "------------------------------------------------------"
	echo ""
}

# Generating Pyspark script and code
generate_pyspark_shell_script() {
	hwc_pyfile=$(find $HWC_DIRECTORY -name pyspark_hwc-*.zip)
	echo ""
	log_info "Launch the pyspark by coping the following command"
	echo "======================================================"
	echo "pyspark --master yarn \ "
	echo "  --conf spark.sql.hive.hiveserver2.jdbc.url='${hive_jdbc_url}' \ "
	echo "  --conf spark.datasource.hive.warehouse.metastoreUri='${hive_metastore_uri}' \ "
	echo "  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \ "
	echo "  --conf spark.jars=${hwc_jar} \ "
	echo "  --conf spark.submit.pyFiles=${hwc_pyfile} \ "
	echo "  --conf spark.datasource.hive.warehouse.read.via.llap=false \ "
	echo "  --conf spark.datasource.hive.warehouse.read.mode=DIRECT_READER_V2 \ "
	echo "  --conf spark.sql.hive.hwc.execution.mode=spark \ "
	echo "  --conf spark.datasource.hive.warehouse.read.jdbc.mode=cluster \ "
	echo "  --conf spark.sql.extensions=com.hortonworks.spark.sql.rule.Extensions \ "
	#echo "  --conf spark.sql.extensions=com.qubole.spark.hiveacid.HiveAcidAutoConvershension \ "
	echo "  --conf spark.kryo.registrator=com.qubole.spark.hiveacid.util.HiveAcidKyroRegistrator \ "
	if [ ${IS_KERBERIZED} ]; then
	    echo "  --conf spark.security.credentials.hiveserver2.enabled=true \ "
	    user_prin=$(grep "hive.server2.authentication.kerberos.principal" -A1 "${hive_site_xml_file}" |awk 'NR==2' | awk -F"[<|>]" '{print $3}')
	    echo "  --conf spark.sql.hive.hiveserver2.jdbc.url.principal=${user_prin}"
	else
	    echo "  --conf spark.security.credentials.hiveserver2.enabled=false"
	fi
	echo "======================================================"
	echo ""

	echo "After launching the pyspark run the following code"
	echo "------------------------------------------------------"
	echo ""
	echo "from pyspark.sql import SparkSession"
	echo "from pyspark_llap import HiveWarehouseSession"
	echo "hwc = HiveWarehouseSession.session(spark).build()"
	echo "tableName = \"hwc_test_table\""
	echo ""
	echo "// Creating a Hive table if not exists"
	echo "hwc.createTable(tableName).ifNotExists().column(\"id\", \"bigint\").column(\"name\", \"string\").column(\"age\", \"int\").create()"
	echo ""
	echo "// Saving the data to Hive table"
	echo "dataFrame = spark.createDataFrame([(1l, \"Ranga\", 34),(2l, \"Nishanth\", 30)], [\"id\", \"name\", \"age\"])"
	echo "dataFrame.write.format(\"com.hortonworks.spark.sql.hive.llap.HiveWarehouseConnector\").mode(\"overwrite\").option(\"table\", tableName).save()"
	echo ""
	echo "// Reading the data from Hive table"
	echo "hwc.executeQuery(\"select * from \"+tableName).show()"
	echo ""
	echo "------------------------------------------------------"
	echo ""
	echo ""
}

if [ ${IS_SPARK_SHELL} ]; then
	generate_spark_shell_script
fi

if [ ${IS_PYSPARK_SHELL} == true ]; then
	generate_pyspark_shell_script
fi

log_info "$0 script finished"
