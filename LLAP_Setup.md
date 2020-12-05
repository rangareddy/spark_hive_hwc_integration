# Apache Hive LLAP Setup

### 1. Enable YARN preemption

1. In Ambari, select **Services** > **YARN** > **Configs** tab > **Settings** subtab
2. In **YARN Features**, set **Pre-emption** to **Enabled** (the default).

![yarn_features_ambari_ui.png](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/yarn_features_ambari_ui.png)

3. Click **SAVE** in the upper right area of the window.

### 2. Enable interactive query

1. In Ambari, select **Services** > **Hive** > **Configs** > **Settings**.
2. In Interactive Query, set Enable Interactive Query to Yes:

![Enable interactive query](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/interactive-query-ambari-nontp.png)

3. In Select HiveServer Interactive Host, accept the default server to host HiveServer Interactive, or from the drop-down, select a different host.

![hiveserver2_interactive_host_window](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hiveserver2_interactive_host_window.png)

### 3. Set up multiple HiveServer Interactives for high availability

1. In Select **HiveServer Interactive** Host, after selecting one HiveServer2 Interactive host, click **+** to add another.

![High Availability](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_add_multiple_hsi.png)

2. Accept the default server to host the additional HiveServer Interactive, or from the drop-down, select a different host.
3. Optionally, repeat these steps to add additional HiveServer Interactives.

### 4. Configure an llap queue

1. In **Ambari**, select **Hive > Configs**.
2. In Interactive Query Queue, choose the llap queue if it appears as a selection, and save the Hive configuration changes.:

![hive_start_hive_interactive_query](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_start_hive_interactive_query.png)

Depending on your YARN Capacity Scheduler settings, a queue named llap might or might not appear. This setting dedicates all LLAP daemons and all YARN Application Masters (AMs) of the system to the single, specified queue.

3. In **Ambari**, select **Services** > **YARN** > **Configs**.
4. From the **hamburger** menu Views, select **YARN Queue Manager**.

![hive-llap-yarn-queue-manager](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive-llap-yarn-queue-manager.png)

5. If an llap queue does not exist, add a queue named llap. Otherwise, proceed to the next step.
6. If the llap queue is stopped, change the state to running.
7. Check the llap queue capacity, and accept or change the value as follows:
*. If the llap queue capacity is zero, you might have too few nodes for Ambari to configure llap queue capacity. Go to the next step to configure llap queue capacity and max capacity.

![hive-llap-add-queue2](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive-llap-add-queue2.png)

*. If Ambari set the llap capacity to greater than zero, no change is necessary. Skip the next step. For example, in a 7-node cluster, Ambari allocates llap queue capacity as follows:

![hive-llap-add-queue3](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive-llap-add-queue3.png)

8. If llap queue capacity is zero, increase the capacity allocated to your llap queue, and also change max capacity to the remainder of the allocated llap capacity minus 100 percent.
For example, set max capacity to 100 percent minus 50 percent = 50 percent.

![hive-llap-queue-capacity](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive-llap-queue-capacity.png)

Allocating 15-50 percent of cluster to the llap queue is common.

9. Select the llap queue under Add Queue, and in Resources that appears on the right, set User Limit Factor to 1, and set Priority to greater than 0 (1 for example).
10. Select Actions > Save and Refresh Queues.
11. In **Services > YARN > Summary** restart any YARN services as prompted.

### 5. Add a Hive proxy

1. In Ambari, select **Services > HDFS > Configs > Advanced**.
2. In **Custom core-site**, add the FQDNs of the HiveServer Interactive host or hosts to the value of hadoop.proxyuser.hive.hosts.
3. Save the changes.

### 6. Configure other LLAP properties

Memory per Daemon
YARN container size for each daemon (MB)
In-Memory Cache per Daemon
Size of the cache in each container (MB)
Number of executors per LLAP Daemon
The number of fragments that can execute in parallel on a daemon
Use the slider controls to change or restore settings:

![hive_configs_controls](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_configs_controls.png)

To set the value outside the slider range, you move your pointer over the field to enable the hover actions, and select Override.

1. Accept or change the Number of Nodes Used By Hive LLAP (num_llap_nodes property). For example, accept using 2 nodes for LLAP.

![hive_num_nodes_interactive_query](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_num_nodes_interactive_query.png)

2. Accept the Maximum Total Concurrent Queries (hive.server2.tez.sessions.per.default.queue property), or make changes.
3. Check Memory per Daemon (hive.llap.daemon.yarn.container.mb property) and In-Memory Cache per Daemon (hive.llap.io.memory.size property).

![hive_other_interactive_query](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_other_interactive_query.png)

This memory (hive.llap.daemon.yarn.container.mb) plus the cache (hive.llap.io.memory.size) must fit within the container size specified for the YARN container. The YARN container configuration setting appears in **Services > YARN > Configs > Settings**.

4. Accept the Number of Executors per LLAP Daemon (hive.llap.daemon.num.executors), or change this setting if you know what you are doing, and check that the hive.llap.io.threadpool.size is the same value.
5. Save any Hive configuration changes, and in **Services > YARN > Settings > Memory** - Node, check that the Minimum Container Size (Memory) for YARN is low.
The value should rarely exceed 1024 MB.
6. Set the Maximum Container Size (Memory) to the same value as the Memory Allocated for All YARN Containers on a Node.

![hive_yarn_container](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_yarn_container.png)

7. In Ambari, select **Services > YARN > Configs > Advanced**.
8. In **Custom yarn-site**, add the following properties unless, upon attempting to add these properties, Ambari indicates the properties are already added:
**yarn.resourcemanager.monitor.capacity.preemption.natural_termination_factor** (value = 1) and **yarn.resourcemanager.monitor.capacity.preemption.total_preemption_per_round** (as described below).
Calculate the value of the total preemption per round by dividing 1 by the number of cluster nodes. Enter the value as a decimal.
For example, if your cluster has 3 nodes, then divide 1 by 3 and enter 0.33 as the value of this property setting.
9. **Save YARN** changes, and go back to the Hive configuration.

### 7. Configure the HiveServer heap size

1. In Ambari, go to **Services > Hive > Config**.
2. In Optimization, adjust the slider to set the heap size.

![hive_hiveserver_heap_size](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hiveserver_heap_size.png)

For **1 to 20** concurrent executing queries, set to **6 GB heap size**; **21 to 40** concurrent executing queries: Set to **12 GB heap size**.

### 8. Save LLAP settings and restart services

1. Click **SAVE** at the bottom of the wizard.
2. If the Dependent Configurations window appears, review recommendations and accept or reject the recommendations.
3. Navigate to the each service, starting with the first one listed under Ambari Services, and restart any services as required.
4. Select **Services > Hive > Summary** and verify that the single or multiple HiveServer Interactive instances you set up started.
For example, the following screenshot shows a single HiveServer Interactive.

![hive_hive_interactive](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hive_interactive.png)

The following screenshot shows two HiveServer Interactives.

![hive_hsi_ha_2](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hsi_ha_2.png)

5. If HiveServer Interactive is stopped, click the link to the stopped HiveServer Interactive instance. In Components, click Action for the stopped HiveServer2 Interactive, and click Start.

![hive_hsi_ha_3](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hsi_ha_3.png)

If you set up multiple HiveServer Interactives, after instances start, one is designated Active HiveServer2 Interactive. Others operate in passive mode.

![hive_hsi_ha_4](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hsi_ha_4.png)

6. In Ambari, select **Services > Hive > Summary** and in **Quick Links**, click **HiveServer Interactive UI** to check that the **LLAP** application is running.

![hive_hsi2interactiveui](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hsi2interactiveui.png)

The **HiveServer Interactive UI** shows **LLAP running** on **two daemons** (instances).

![hive_hsi2uiexample](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hsi2uiexample.png)

7. If LLAP is not running, in **Summary**, click the **HiveServer Interactive** link (the active HiveServer Interactive link in the case of multiple instances), and then, choose Restart LLAP from the Action menu.

![hive_restart_llap](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_restart_llap.png)

### 9. Run an interactive query

* You set up LLAP and restarted services.
* You checked the HiveServer Interactive UI, which you access from **Summary > Quick Links > HiveServer Interactive UI**, and you see that LLAP is running.

![hive_hsi2uiexample](https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/how-to/images/hive_hsi2uiexample.png)

1. On the Command-line of a node in the cluster, connect to HiveServer Interactive on port 10500 through Beeline.
For example, enter the following beeline command, but replace my_hiveserver_interactive.com with the FQDN of your HiveServer Interactive node:
```shell
$ beeline -n hive -u jdbc:hive2://localhost:10500/;transportMode=binary
```
2. At the Hive prompt, create a table and insert data.
```sql
CREATE TABLE students (name VARCHAR(64), age INT, gpa DECIMAL(3,2));
INSERT INTO TABLE students VALUES ('fred flintstone', 35, 1.28), ('barney rubble', 32, 2.32);             
```
> Hive inserted the data much faster using the LLAP interactive query than using a conventional Hive query.

### References:
* https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.1.5/performance-tuning/content/hive_run_llap_query.html
* https://docs.cloudera.com/HDPDocuments/HDP2/HDP-2.6.3/bk_command-line-installation/content/install_llap_secure.html
