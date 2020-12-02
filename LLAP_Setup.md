# Apache Hive LLAP Setup

### 1. Enable YARN preemption
You must enable YARN preemption before setting up Hive low-latency analytical processing (LLAP). YARN preemption directs the capacity scheduler to position an LLAP queue as the top-priority workload to run among cluster node resources. You do not need to label the nodes to ensure LLAP has top priority.
### 2. Enable interactive query
You need to enable interactive query to take advantage of low-latency analytical processing (LLAP) of Hive queries. When you enable interactive query, you select a host for HiveServer Interactive.
### 3. Set up multiple HiveServer Interactives for high availability
After enabling interactive query, you can optionally set up additional HiveServer Interactive instances for high-availablilty. One instance operates in active mode, the other in passive (standby) mode. The passive instance serves as a backup and takes over if the active instance goes down.
### 4. Configure an llap queue
Ambari generally creates and configures an interactive query queue named llap and points the Hive service to a YARN queue. You check, and if necessary, change the llap queue using YARN Queue Manager.
### 5. Add a Hive proxy
To prevent network connection or notification problems, you must add a hive user proxy for HiveServer Interactive service to access the Hive Metastore.
### 6. Configure other LLAP properties
Configuring LLAP involves setting properties in YARN and Hive. After you configure the llap queue, you need to go back to the Hive configuration to continue setting up low-latency analytical processing (LLAP).
### 7. Configure the HiveServer heap size
Generally, configuring HiveServer heap memory according to the recommendations in this topic ensures proper LLAP functioning. If HiveServer heap memory is set too low, HiveServer Interactive keeps going down.
### 8. Save LLAP settings and restart services
You need to save LLAP settings at the bottom of the Ambari wizard and restart services in the proper order to activate low-latency analytical processing (LLAP).
### 9. Run an interactive query
You connect to HiveServer through Beeline to run interactive queries, which are queries that take advantage of low-latency analytical processing (LLAP). In the connection string, you specify the FQDN of the node that runs HiveServer Interactive.
