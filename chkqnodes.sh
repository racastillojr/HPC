#!/bin/bash

#==================================================================================
#Created by Ramon Castillo - rcjr@uic.edu
#Univerisity of Illinois at Chicago
#Academic Computing and Communications Center
#Enterprise Architecture and Development - HPC
#==================================================================================

#The moab-server config path is set to get a list of queues and their assigned nodes
#When running, the script will output the node(s) status and running jobid for every node in the queue specified
#Designed for Moab
#Script assumes user running it has sufficient privileges to run checknode and view the moab-server.cfg file
# NODECFG example: NODECFG[compute-0-3.ibnet]    NODETYPE=G1 FEATURES=qname
#===================================================================================


queueName=$1
if [ "$1" != "" ]
then
        for i in `cat /opt/moab/etc/moab.d/moab-server.cfg |grep FEATURES=$queueName |awk '{print $1}' |sed 's/NODECFG//;s/.//;s/.$//'`; do
                liststate=$(checknode $i |grep State |awk '{print $2'})
                listJobId=$(checknode $i |grep Jobs |awk '{print $2'})
                listjobshow=$(checknode $i |grep "Jobs" |awk '{print $2'})
                if [ $liststate != "Busy" ]; then
                        echo "$i is not busy";
                else
                        tput setaf 1; echo "$i : is $liststate running job $listJobId"; tput sgr0
                        showq |grep $listjobshow
                fi
                #mdiag -n |grep $i;
        done

#Need to get list of accounts from mam-list-accounts(Moab v9)
#elif [ "$1" == "all" ];
#then
#        for i in `more /opt/moab/etc/moab.d/moab-server.cfg |grep "FEATURES=" |awk '{print $1}' |sed 's/NODECFG//;s/.//;s/.$//'`; do

#                mdiag -n |grep $i;
#        done
#elif [ "$1" == "draining" ];
#then
#        for i in `more /opt/moab/etc/moab.d/moab-server.cfg |grep "FEATURES=" |awk '{print $1}' |sed 's/NODECFG//;s/.//;s/.$//'`; do
#
#                mdiag -n |grep "Draining" |grep $i;
#        done

fi

