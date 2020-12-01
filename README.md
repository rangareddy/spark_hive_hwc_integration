# Spark Hive Integration with HiveWarehouseConnector (HWC) 

## HiveWarehouseConnector setup

### Prerequisite
* LLAP Service needs to be installed and enabled.

#### Gathering initial Configuration
##### ThriftJDBC URL for LLAP HiveServer2
Navigate to Ambari UI -> Services -> Hive -> Summary --> **HIVESERVER2 JDBC URL** 
Example:
```
jdbc:hive2://localhost:10000
```
##### The Hive Metastore URI
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Custom hive-interactive-site --> **hive.metastore.uris**
Example:
```
thrift://host1:9083,thrift://host2:9083
```
##### The Zookeeper hosts used by LLAP
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Advanced hive-site > **hive.zookeeper.quorum**
Example:
```
host1:2181;host2:2181;host3:2181
```
##### Application name for LLAP service
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Advanced hive-interactive-site --> **hive.llap.daemon.service.hosts**
Example:
```
@llap0
```
##### If cluster is kerberized then there is an extra property to be collected
Navigate to Ambari UI -> Services -> Hive -> Configs --> ADVANCED --> Advanced hive-site > **hive.server2.authentication.kerberos.principal**
Example:
```
hive/_HOST@EXAMPLE.COM
```

### Configure Spark cluster using HWC settings
1. Cluster level configuration
2. Application level configuration

If cluster is kerberos enabled then we need to add two additional properties

1. **spark.security.credentials.hiveserver2.enabled** - **false** for **YARN client mode** and **true** for **YARN cluster mode**.
2. **spark.sql.hive.hiveserver2.jdbc.url.principal** - **hive/_HOST@EXAMPLE.COM**

##### Check the hive-warehouse-connector-assembly version
```shell
ls /usr/hdp/current/hive_warehouse_connector
hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar  pyspark_hwc-1.0.0.3.1.5.0-152.zip
```

#### 1. Cluster level configuration
Navigate to Ambari UI -> Services -> Spark2 --> Configs --> ADVANCED --> Custom spark2-defaults --> Select **Add Property...** > Click on **Bulk property add mode** --> Add the below properties and click on **Add** --> Save changes and restart all affected components.

```properties
spark.sql.hive.hiveserver2.jdbc.url=jdbc:hive2://localhost:10000
spark.datasource.hive.warehouse.metastoreUri=thrift://host1:9083,thrift://host2:9083
spark.hadoop.hive.llap.daemon.service.hosts=@llap0
spark.hadoop.hive.zookeeper.quorum=host1:2181;host2:2181;host3:2181
spark.datasource.hive.warehouse.load.staging.dir=/tmp
spark.jars=/usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar
spark.submit.pyfiles=/usr/hdp/current/hive_warehouse_connector/pyspark_hwc-1.0.0.3.1.5.0-152.zip
```

#### 2. Application level configuration

While passing hwc settings we need to use **--conf**
**Example:**

```shell
spark-shell --master yarn \
  --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://localhost:10000" \
  --conf spark.datasource.hive.warehouse.metastoreUri="thrift://host1:9083,thrift://host2:9083" \
  --conf spark.hadoop.hive.llap.daemon.service.hosts="@llap0" \
  --conf spark.hadoop.hive.zookeeper.quorum="host1:2181;host2:2181;host3:2181" \
  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar
```

Submitting application(s) currently supported for **spark-shell, pyspark,**, **spark-submit** and **Zeppelin**.

##### spark-shell usage:
```shell
spark-shell --master yarn \
  --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://localhost:10000" \
  --conf spark.datasource.hive.warehouse.metastoreUri="thrift://host1:9083,thrift://host2:9083" \
  --conf spark.hadoop.hive.llap.daemon.service.hosts="@llap0" \
  --conf spark.hadoop.hive.zookeeper.quorum="host1:2181;host2:2181;host3:2181" \
  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar
```

##### pyspark usage:
> For PySpark, additionally we need to add the connector's to submit application.

```shell  
pyspark --master yarn \
  --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://localhost:10000" \
  --conf spark.datasource.hive.warehouse.metastoreUri="thrift://host1:9083,thrift://host2:9083" \
  --conf spark.hadoop.hive.llap.daemon.service.hosts="@llap0" \
  --conf spark.hadoop.hive.zookeeper.quorum="host1:2181;host2:2181;host3:2181" \
  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar \
  --py-files /usr/hdp/current/hive_warehouse_connector/pyspark_hwc-1.0.0.3.1.5.0-152.zip
```

##### spark-submit:
```shell
spark-submit --master yarn \
  --class <APP_CLASS_NAME> \
  --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://localhost:10000" \
  --conf spark.datasource.hive.warehouse.metastoreUri="thrift://host1:9083,thrift://host2:9083" \
  --conf spark.hadoop.hive.llap.daemon.service.hosts="@llap0" \
  --conf spark.hadoop.hive.zookeeper.quorum="host1:2181;host2:2181;host3:2181" \
  --conf spark.datasource.hive.warehouse.load.staging.dir=/tmp \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar \
  <APP_JAR_PATH>/<APP_JAR_NAME>
```

##### Zeppelin 
* https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/integrating-hive/content/hive_zeppelin_configuration_hivewarehouseconnector.html
* https://docs.microsoft.com/en-us/azure/hdinsight/interactive-query/apache-hive-warehouse-connector-zeppelin
