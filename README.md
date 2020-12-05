# Spark Hive Integration with HiveWarehouseConnector (HWC) 

## HiveWarehouseConnector setup

### Prerequisite
* [LLAP Service needs to be installed and enabled](https://github.com/rangareddy/spark_hive_hwc_integration/blob/main/LLAP_Setup.md)

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

If cluster is Kerberized cluster then we need to add the following two additional properties.

1. **spark.security.credentials.hiveserver2.enabled** - **false** for **YARN client mode** and **true** for **YARN cluster mode**.
2. **spark.sql.hive.hiveserver2.jdbc.url.principal** - **hive/_HOST@EXAMPLE.COM**

a) In **client mode**, the driver will run in the spark client process and HWC in spark driver will use the principal for authentication. Since the driver does not use delegation token to authenticate, we won't need to set **spark.security.credentials.hiveserver2.enabled=true** to use **HiveServer2CredsProvider** 

b) In **cluster mode** the driver will run in Application Master and HWC in spark driver will use delegation token to authenticate. Since the driver uses delegation token to authenticate, we need **HiveServer2CredsProvider**, hence we set **spark.security.credentials.hiveserver2.enabled** true.

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

##### spark-shell:
```shell
spark-shell --master yarn \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar
```

##### pyspark:
> For PySpark, additionally we need to add the connector(**pyspark_hwc-*.zip**) to submit application.

```shell  
pyspark --master yarn \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar \
  --py-files /usr/hdp/current/hive_warehouse_connector/pyspark_hwc-1.0.0.3.1.5.0-152.zip
```

##### spark-submit:
```shell
spark-submit --master yarn \
  --class <APP_CLASS_NAME> \
  --jars /usr/hdp/current/hive_warehouse_connector/hive-warehouse-connector-assembly-1.0.0.3.1.5.0-152.jar \
  <APP_JAR_PATH>/<APP_JAR_NAME>
```

##### Zeppelin 
* https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/integrating-hive/content/hive_zeppelin_configuration_hivewarehouseconnector.html
* https://docs.microsoft.com/en-us/azure/hdinsight/interactive-query/apache-hive-warehouse-connector-zeppelin

#### Create a database 
```sql
CREATE DATABASE hwc_db;
```

#### Creating a Hive Table
```sql
USE hwc_db;
CREATE TABLE crimes(year INT, crime_rate DOUBLE);
```

#### Inserting data to Hive Table
```sql
INSERT INTO crimes VALUES (1997, 611.0), (1998, 567.6), (1999, 523.0), (2000, 506.5), (2001, 504.5), (2002, 494.4), (2003, 475.8);
INSERT INTO crimes VALUES (2004, 463.2), (2005, 469.0), (2006, 479.3), (2007, 471.8), (2008, 458.6), (2009, 431.9), (2010, 404.5);
INSERT INTO crimes VALUES (2011, 387.1), (2012, 387.8), (2013, 369.1), (2014, 361.6), (2015, 373.7), (2016, 386.3);
```

#### Selecting data
```
select * from crimes;
+--------------+--------------------+
| crimes.year  | crimes.crime_rate  |
+--------------+--------------------+
| 1997         | 611.0              |
| 1998         | 567.6              |
| 1999         | 523.0              |
| 2000         | 506.5              |
| 2001         | 504.5              |
| 2002         | 494.4              |
| 2003         | 475.8              |
| 2004         | 463.2              |
| 2005         | 469.0              |
| 2006         | 479.3              |
| 2007         | 471.8              |
| 2008         | 458.6              |
| 2009         | 431.9              |
| 2010         | 404.5              |
| 2011         | 387.1              |
| 2012         | 387.8              |
| 2013         | 369.1              |
| 2014         | 361.6              |
| 2015         | 373.7              |
| 2016         | 386.3              |
+--------------+--------------------+
```

### Giving hive permission to all files under /warehouse/tablespace/managed/hive directory.
```shell
hdfs dfs -chown -R hive:hadoop /warehouse/tablespace/managed/hive
```
