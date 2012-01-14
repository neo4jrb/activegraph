#!/bin/sh

# Only follow symlinks if readlink supports it
if readlink -f "$0" > /dev/null 2>&1
then
  ZOOBIN=`readlink -f "$0"`
else
  ZOOBIN="$0"
fi

ZOOMAIN="org.apache.zookeeper.server.quorum.QuorumPeerMain"

ZOOBINDIR=`dirname "$ZOOBIN"`
JARDIR=`cd "${ZOOBINDIR}/lib"; pwd`

CLASSPATH=$JARDIR/log4j-1.2.16.jar:$JARDIR/zookeeper-3.3.2.jar
java -cp "$CLASSPATH" $ZOOMAIN conf/server1.cfg &
java -cp "$CLASSPATH" $ZOOMAIN conf/server2.cfg &
java -cp "$CLASSPATH" $ZOOMAIN conf/server3.cfg &
