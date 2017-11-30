#HPC Scripts to use with Moab


These script were created to manage user access to a HPC cluster using Moab. 

usermanagement.sh
The user management script also assumes adtools are installed becasue it adds users to specific groups.

If users are not being picked up by the script, make sure that winbind is working properly on the server. You may need to rebind the server using "net ads join" to rebind.

fixnodes.sh
This script checks to see how many of your nodes are offline. The number in this script is based on the number of nodes I had when I built the script. You can change the number to what ever is relevent to your cluster. If the number of nodes are lower than the number that should be up, the script will login to each node labelled as "Down" by mdiag and restart pbs_mom. Once pbs_mom is restarted, your node should come back up and rejoin the cluster. This script can be ran manually or set as a cron job.

chkqnodes.sh
When running, the script will output the node(s) status and running jobid for every node in the queue specified. This is helpful when a queue owner wants to know what jobs and nodes are currently using their queue.


More scripts coming soon!
