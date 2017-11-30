#!/bin/sh

#==================================================================================
#Created by Ramon Castillo - rcjr@uic.edu
#Univerisity of Illinois at Chicago
#Academic Computing and Communications Center
#Enterprise Architecture and Development - HPC
#==================================================================================
#This script counts the number of nodes available and 
#if it is under a set amount it restarts MOM on the downed nodes. 
#You can set this as a cron job or an alias to run it on demand. 
#This has been useful for us in those cases where MOM crashed on several nodes at once.
#If set as a cron job, it copies the name of the node to a file called momRestarted for later review
#Designed for Moab
#Script assumes user running it has sufficient privileges to restart mom remotely
#===================================================================================

nodeCount=$(showq |grep nodes |awk '{print $3}')

#Check if nodeCount is below set number of nodes
if [ $nodeCount -lt '203' ]; then
echo "Node count less than 203. Restarting mom on computes";

        for i in `mdiag -n |grep Down |awk '{print $1}'|sed '$d'`; do

                echo $i; ssh $i /etc/init.d/pbs_mom restart
                sleep 1
                echo $i >> /<your>/<home>/<dir>/fixnodesFiles/momRestarted
        done

fi
