export HIVE_HOME={{hive_path}}/apache-hive-{{hive_version}}-bin
export PATH=$HIVE_HOME/bin:$PATH
export CLASSPATH=$CLASSPATH.:$HIVE_HOME/lib
export HIVE_CONF_DIR={{ hive_path }}/apache-hive-{{ hive_version}}-bin/conf