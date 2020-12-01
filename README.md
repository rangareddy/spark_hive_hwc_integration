# Spark Hive Integration with Hive Warehouse Connector (HWC) 

## Hive Warehouse Connector setup

### Prerequisite
* LLAP Service needs to be installed and enabled.


From a web browser, navigate to https://LLAPCLUSTERNAME.azurehdinsight.net/#/main/services/HIVE where LLAPCLUSTERNAME is the name of your Interactive Query cluster.

### The URL for HiveServer2 Interactive
Navigate to Ambari UI -> Services -> Hive -> Summary --> **HIVESERVER2 JDBC URL** 
Example:
```
jdbc:hive2://c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
```
### The Hive Metastore URI
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Custom hive-interactive-site --> **hive.metastore.uris**
Example:
```
thrift://c2543-node3.coelab.cloudera.com:9083
```

### The Zookeeper hosts used by LLAP
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Advanced hive-site > **hive.zookeeper.quorum**
Example:
```
c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181
```

### Application name for LLAP service
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Advanced hive-interactive-site --> **hive.llap.daemon.service.hosts**
Example:
```
@llap0
```
### If cluster is kerberized then there is an extra property to be collected
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Advanced hive-site > **hive.server2.authentication.kerberos.principal**
Example:
```
hive/_HOST@EXAMPLE.COM
```

## Cluster wide configuration
Navigate to Ambari UI -> Services -> Spark2 --> Configs --> ADVANCED --> Custom spark2-defaults --> Add property... --> Click on Bulk property add mode --> Add the above collected properties to below mapped properties and click on **Add**

```
spark.sql.hive.hiveserver2.jdbc.url=jdbc:hive2://c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2
spark.datasource.hive.warehouse.metastoreUri=thrift://c2543-node3.coelab.cloudera.com:9083
spark.hadoop.hive.llap.daemon.service.hosts=@llap0
spark.hadoop.hive.zookeeper.quorum=c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181
spark.datasource.hive.warehouse.load.staging.dir=/tmp
spark.jars=/usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar
spark.submit.pyfiles=/usr/hdp/current/hive_warehouse_connector/pyspark_hwc-1.0.0.3.1.5.0-152.zip
```

## Application level configuration

### Scala/Java
```
spark-shell --master yarn \
  --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" \
  --conf spark.datasource.hive.warehouse.metastoreUri="thrift://c2543-node3.coelab.cloudera.com:9083" \
  --conf spark.hadoop.hive.llap.daemon.service.hosts="@llap0" \
  --conf spark.hadoop.hive.zookeeper.quorum="c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181" \
  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar
```

### Pyspark
```
pyspark --master yarn \
  --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2" \
  --conf spark.datasource.hive.warehouse.metastoreUri="thrift://c2543-node3.coelab.cloudera.com:9083" \
  --conf spark.hadoop.hive.llap.daemon.service.hosts="@llap0" \
  --conf spark.hadoop.hive.zookeeper.quorum="c2543-node2.coelab.cloudera.com:2181,c2543-node3.coelab.cloudera.com:2181,c2543-node4.coelab.cloudera.com:2181" \
  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar \
  --py-files /usr/hdp/current/hive_warehouse_connector/pyspark_hwc-1.0.0.3.1.5.0-152.zip
```
