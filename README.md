# Hadoop-ansible
- Install Hadoop cluster with ansible
- Now Support CentOS 7.x
- JDK is  Openjdk-1.8
- Hadoop is the latest version 3.0.0

## Before Install
Use DNS Server or update /etc/hosts for all servers

## Install Hadoop
1. Download Hadoop to any path
2. Update the {{ download_path }} in vars/var_basic.yml
```
download_path: "/home/pippo/Downloads" # your local path 
hadoop_version: "3.0.0" # your hadoop version
hadoop_path: "/home/hadoop" # default in user "hadoop" home
hadoop_config_path: "/home/hadoop/hadoop-{{hadoop_version}}/etc/hadoop"
hadoop_tmp: "/home/hadoop/tmp"
hadoop_dfs_name: "/home/hadoop/dfs/name"
hadoop_dfs_data: "/home/hadoop/dfs/data"

```
3. Use ansible template to generate the hadoop configration, so If your want to add more properties, just update the vars/var_basic.yml.default is 

```
# hadoop configration 
hdfs_port: 9000
core_site_properties:
  - {
      "name":"fs.defaultFS",
      "value":"hdfs://{{ master_ip }}:{{ hdfs_port }}"
  }
  - {
      "name":"hadoop.tmp.dir",
      "value":"file:{{ hadoop_tmp }}"
  }
  - {
    "name":"io.file.buffer.size",
    "value":"131072"
  }

dfs_namenode_httpport: 9001
hdfs_site_properties:
  - {
      "name":"dfs.namenode.secondary.http-address",
      "value":"{{ master_hostname }}:{{ dfs_namenode_httpport }}"
  }
  - {
      "name":"dfs.namenode.name.dir",
      "value":"file:{{ hadoop_dfs_name }}"
  }
  - {
      "name":"dfs.namenode.data.dir",
      "value":"file:{{ hadoop_dfs_data }}"
  }
  - {
      "name":"dfs.replication",
      "value":"{{ groups['workers']|length }}"
  }
  - {
    "name":"dfs.webhdfs.enabled",
    "value":"true"
  }

mapred_site_properties:
 - {
   "name": "mapreduce.framework.name",
   "value": "yarn"
 }
 - {
   "name": "mapreduce.admin.user.env",
   "value": "HADOOP_MAPRED_HOME=$HADOOP_COMMON_HOME"
 }
 - {
   "name":"yarn.app.mapreduce.am.env",
   "value":"HADOOP_MAPRED_HOME=$HADOOP_COMMON_HOME"
 }

yarn_resourcemanager_port: 8040
yarn_resourcemanager_scheduler_port: 8030
yarn_resourcemanager_webapp_port: 8088
yarn_resourcemanager_tracker_port: 8025
yarn_resourcemanager_admin_port: 8141

yarn_site_properties:
  - {
    "name":"yarn.resourcemanager.address",
    "value":"{{ master_hostname }}:{{ yarn_resourcemanager_port }}"
  }
  - {
    "name":"yarn.resourcemanager.scheduler.address",
    "value":"{{ master_hostname }}:{{ yarn_resourcemanager_scheduler_port }}"
  }
  - {
    "name":"yarn.resourcemanager.webapp.address",
    "value":"{{ master_hostname }}:{{ yarn_resourcemanager_webapp_port }}"
  }
  - {
    "name": "yarn.resourcemanager.resource-tracker.address",
    "value": "{{ master_hostname }}:{{ yarn_resourcemanager_tracker_port }}"
  }
  - {
    "name": "yarn.resourcemanager.admin.address",
    "value": "{{ master_hostname }}:{{ yarn_resourcemanager_admin_port }}"
  }
  - {
    "name": "yarn.nodemanager.aux-services",
    "value": "mapreduce_shuffle"
  } 
  - {
    "name": "yarn.nodemanager.aux-services.mapreduce.shuffle.class",
    "value": "org.apache.hadoop.mapred.ShuffleHandler"
  }
```


---
Watch This
```
hdfs_site_properties:
  - {
      "name":"dfs.namenode.secondary.http-address",
      "value":"{{ master_hostname }}:{{ dfs_namenode_httpport }}"
  }
  - {
      "name":"dfs.namenode.name.dir",
      "value":"file:{{ hadoop_dfs_name }}"
  }
  - {
      "name":"dfs.namenode.data.dir",
      "value":"file:{{ hadoop_dfs_data }}"
  }
  - {
      "name":"dfs.replication",
      "value":"{{ groups['workers']|length }}"  # this is  the group "workers" you define in hosts/host 
  }
  - {
    "name":"dfs.webhdfs.enabled",
    "value":"true"
  }
```

### Install Master
check the master.yml
```
- hosts: master 
  remote_user: root
  vars_files:
   - vars/user.yml
   - vars/var_basic.yml
   - vars/var_master.yml
  vars:
     add_user: true        # add user "hadoop"
     generate_key: true    # generate the ssh key
     open_firewall: true   # for CentOS 7.x is firewalld
     install_hadoop: true  # install hadoop,if you just want to update the configuration, set to false
     config_hadoop: true   # Update configuration
  roles:
    - user                 # add user and generate the ssh key
    - fetch_public_key     # get the key and put it in your localhost
    - authorized           # push the ssh key to the remote server 
    - java                 # install jdk
    - hadoop               # install hadoop

```
run shell like

```
ansible-playbook -i hosts/host master.yml
```

### Install Workers

```
# Add Master Public Key   # get master ssh public key 
- hosts: master 
  remote_user: root
  vars_files:
   - vars/user.yml
   - vars/var_basic.yml
   - vars/var_workers.yml
  roles:
    - fetch_public_key

- hosts: workers 
  remote_user: root
  vars_files:
   - vars/user.yml
   - vars/var_basic.yml
   - vars/var_workers.yml
  vars:
    add_user: true
    generate_key: false # workers just use master ssh public key
    open_firewall: false 
    install_hadoop: true
    config_hadoop: true
  roles:
    - user
    - authorized
    - java
    - hadoop

```
run shell like:
```
master_ip:  your hadoop master ip
master_hostname: your hadoop master hostname

above two variables must be same like your real hadoop master

ansible-playbook -i hosts/host workers.yml -e "master_ip=172.16.251.70 master_hostname=hadoop-master"

```

### Install hive
1. **Create database first and give right authority**
2. check vars/var_hive.yml
```
---

# hive basic vars
download_path: "/home/pippo/Downloads"                                 # your download path
hive_version: "2.3.2"                                                  # your hive version
hive_path: "/home/hadoop"
hive_config_path: "/home/hadoop/apache-hive-{{hive_version}}-bin/conf"
hive_tmp: "/home/hadoop/hive/tmp"                                      # your hive tmp path

hive_create_path:
  - "{{ hive_tmp }}"

hive_warehouse: "/user/hive/warehouse"                                # your hdfs path
hive_scratchdir: "/user/hive/tmp"
hive_querylog_location: "/user/hive/log"

hive_hdfs_path: 
  - "{{ hive_warehouse }}"
  - "{{ hive_scratchdir }}"
  - "{{ hive_querylog_location }}"

hive_logging_operation_log_location: "{{ hive_tmp }}/{{ user }}/operation_logs"

# database
db_type: "postgres"                                              # use your db_type, default is postgres
hive_connection_driver_name: "org.postgresql.Driver"
hive_connection_host: "172.16.251.33"
hive_connection_port: "5432"
hive_connection_dbname: "hive"
hive_connection_user_name: "hive_user"
hive_connection_password: "nfsetso12fdds9s"
hive_connection_url: "jdbc:postgresql://{{ hive_connection_host }}:{{ hive_connection_port }}/{{hive_connection_dbname}}?ssl=false"
# hive configration                                             # your hive site properties
hive_site_properties:
  - {
      "name":"hive.metastore.warehouse.dir",
      "value":"hdfs://{{ master_hostname }}:{{ hdfs_port }}{{ hive_warehouse }}"
  }
  - {
      "name":"hive.exec.scratchdir",
      "value":"{{ hive_scratchdir }}"
  }
  - {
      "name":"hive.querylog.location",
      "value":"{{ hive_querylog_location }}/hadoop"
  }
  - {
      "name":"javax.jdo.option.ConnectionURL",
      "value":"{{ hive_connection_url }}"
  }
  - {
    "name":"javax.jdo.option.ConnectionDriverName",
    "value":"{{ hive_connection_driver_name }}"
  }
  - {
    "name":"javax.jdo.option.ConnectionUserName",
    "value":"{{ hive_connection_user_name }}"
  }
  - {
    "name":"javax.jdo.option.ConnectionPassword",
    "value":"{{ hive_connection_password }}"
  }
  - {
    "name":"hive.server2.logging.operation.log.location",
    "value":"{{ hive_logging_operation_log_location }}"
  }

hive_server_port: 10000                                    # hive port
hive_hwi_port: 9999
hive_metastore_port: 9083

firewall_ports:
  - "{{ hive_server_port }}"
  - "{{ hive_hwi_port }}"
  - "{{ hive_metastore_port }}"
```

3. check hive.yml

```
- hosts: hive                   # in hosts/host
  remote_user: root
  vars_files:
   - vars/user.yml
   - vars/var_basic.yml
   - vars/var_master.yml
   - vars/var_hive.yml            # var_hive.yml
  vars:
     open_firewall: true           
     install_hive: true           
     config_hive: true
     init_hive: true               # init hive database after install and config
  roles:
    - hive

```


### License

GNU General Public License v3.0