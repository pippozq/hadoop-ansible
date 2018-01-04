export HADOOP_HOME={{hadoop_path}}/hadoop-{{hadoop_version}}
export PATH=$HADOOP_HOME/sbin:$HADOOP_HOME/bin:$PATH
export HADOOP_LOG_DIR={{ hadoop_log_path }}
export YARN_LOG_DIR=$HADOOP_LOG_DIR