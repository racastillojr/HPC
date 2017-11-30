#!/bin/bash
#Created by Ramon Castillo rcjr@uic.edu
#This script is used to manage user accounts (Moab and server)

#Check if the user is root
if [ "$EUID" -ne '0' ]; then
        echo "You are not root";
return 1
fi

OPTIONS=("Create a new user" "Add user to secondary account" "Add user to exclusive queue" "Remove user from secondary account" "Remove user account")
select opt in "${OPTIONS[@]}"; do
if [ "$opt" = "Create a new user" ]; then
	a='0'
	piEmail1='2'
        
	read -p "Enter Netid : " netId
        
	#Checks if the user is in AD
	userinAD=$(wbinfo -i $netId 2>/dev/null |wc -l)
	if [ $userinAD -eq '0' ]; then
		echo $netId "is not in AD. Exiting.";
	return 1
	fi
	
	STOREOPTIONS=("Store 1" "Store 2")
	select storeopt in "${STOREOPTIONS[@]}"; do
	if [ "$storeopt" = "Store 1" ]; then
		echo="Store 1 selected";
		storeNum="store1"
		break
        else
		echo="Store 2 selected";
		storeNum="store2"
		break
	fi
   	done
	if [ $piEmail1 -eq '2' ]; then

		read -p "Enter approvers email : " piEmail
		piVerify=$(cat /export/share/admin/extremeApprovers |grep "$piEmail"|awk '{print $2}' |wc -l)
	while [ $piVerify -eq '0' ];do

		echo $piEmail" is not a valid approver, try again";
		read -p "Enter approvers email : " piEmail
		piVerify=$(cat /export/share/admin/extremeApprovers |grep "$piEmail" |awk '{print $2}' |wc -l)

	done
	fi
	#Need to add moab creation account
	check4moabacct=$(glsuser $netId|wc -l)
	if [ $check4moabacct -eq '0' ]; then
		echo "Creating Moab account";
		if [ $piVerify -eq '2' ]; then
                	cat '/export/share/admin/extremeApprovers' |grep "$piEmail" |awk '{print $1}'

                	read -p "Copy and past account listed above : " moabAccount
			su - moab -c "gmkuser -A -a $moabAccount -u $netId"
			sleep 1
        	else
                	moabAccount=$(cat /export/share/admin/extremeApprovers |grep "$piEmail" |awk '{print $1}')
			su - moab -c "gmkuser -A -a $moabAccount -u $netId"
			sleep 1
		fi
	else
		echo "$netId already has a Moab account";
		glsuser $netId
		
	fi
	checkpasswd=$(cat /etc/passwd |grep $netId |wc -l)
	#Verify the user is not already in the passwd file
	if [ $checkpasswd -eq '0' ]; then
		wbinfo -i $netId >> /etc/passwd
		sleep 1
        	echo "User added to passwd file";
	else
		echo "$netId is already in the passwd file...skipping";
	fi

	sleep 1
	#Check if the user already has a home directory
	checkStore1=$(ls -l /mnt/store1/home/ |grep $netId|wc -l)
	checkStore2=$(ls -l /mnt/store2/home/ |grep $netId|wc -l)
	checkHomeLink=$(ls -l /export/home/ |grep $netId|wc -l)
	if [ $checkStore1 -eq '1' ] || [ $checkStore2 -eq '1' ] || [ $checkHomeLink -eq '1' ]; then  
		
		echo 'This person exists on the system. Verify they need an account';
		ls -l /export/home/$netId
	break
	else
		echo "creating home dir";
		mkdir /mnt/$storeNum/home/$netId
	
	sleep 1
		echo "Setting home directory perms...";
		chown -R $netId.root /mnt/$storeNum/home/$netId
		chmod u+wxr /mnt/$storeNum/home/$netId
	sleep 1
		#chmod g-wxr /mnt/$storeNum/home/$netId
	#sleep 1
		chmod o-wxr /mnt/$storeNum/home/$netId
		cd /export/home/
		ln -s /mnt/$storeNum/home/$netId
		cd -
	sleep 1
		ls -l /export/home/$netId
		echo " ";
		ls -ld /mnt/$storeNum/home/$netId
	
	sleep 2
		echo "Creating Lustre directory";
		mkdir /mnt/lustre/$netId
		chown -R $netId.root /mnt/lustre/$netId
	        echo " ";
		ls -ld /mnt/lustre/$netId

	fi
	
	echo "Adding $netId to HPC user group in Active Directory";
	adtool groupadduser "GroupName" $netId
	echo "$netId has been set up.";
	echo " ";
	echo "sending email to user telling them about the creation";
	
	mail -s 'Extreme Cluster Account Created for $netId' $netId@uic.edu < /export/share/admin/emailBody
	sleep 1
	echo "Email sent";
	
	return 1

elif [ "$opt" = "Add user to secondary account" ]; then
	piEmail2='2'
	read -p "Enter Netid : " netId

	if [ $piEmail2 -eq '2' ]; then

                read -p "Enter approvers email : " piEmail
                piVerify=$(cat /export/share/admin/extremeApprovers |awk '{print $2}'|grep "$piEmail" |wc -l)
        while [ $piVerify -eq '0' ];do

                echo $piEmail" is not a valid approver, try again";
                read -p "Enter approvers email : " piEmail
                piVerify=$(cat /export/share/admin/extremeApprovers |awk '{print $2}'|grep "$piEmail" |wc -l)

        done
        fi
        if [ $piVerify -eq '2' ]; then
        	cat '/export/share/admin/extremeApprovers' |grep "$piEmail" |awk '{print $1}'

		read -p "Copy and past account listed above : " moabAccount
		glsaccount |grep $moabAccount
	sleep 1
		su - moab -c "gchaccount --add-user $netId -a $moabAccount"
        sleep 1
        	glsaccount |grep $moabAccount
        break

	else
		moabAccount=$(cat /export/share/admin/extremeApprovers |grep "$piEmail" |awk '{print $1}')
		su - moab -c "gchaccount --add-user $netId -a $moabAccount"
	sleep 1
		glsaccount |grep $netId
	break
        fi
	return 1
elif [ "$opt" = "Add user to exclusive queue" ]; then
	read -p "Enter Netid : " netId
	ckMoabAccount=$(glsuser $netId|wc -l)
	if [ $ckMoabAccount -eq '0' ]; then	
		echo "$netId does not have a Moab account. Please create it."
	break
	else
		qstat -q |awk '{print $1}'|sed '1d;2d;3d;4d;5d;/-/d;$d'

		read -p "Enter excusive queue name from list above: " queueName
        	qmgr -c "set queue $queueName acl_users +=$netId"
	break
	fi
	return 1
elif [ "$opt" = "Remove user from secondary account" ]; then
	read -p "Enter Netid : " netId
		glsaccount |grep $netId
		read -p "Copy and past account you would like to remove the user from : " moabAccount
	sleep 1
		su - moab -c "gchaccount --del-user $netId -a $moabAccount"
        sleep 1
        	glsaccount |grep $moabAccount
        break
elif [ "$opt" = "Remove user account" ]; then
	read -p "Enter Netid : " netId
		glsuser |grep $netId
		echo "Removing $netId moab account";
	sleep 1
		su - moab -c "grmuser $netId"
        sleep 1
      		echo "Marking user directory for deletion";
		markDir=$(ls -l /export/home/$netId |awk '{print $11}')
                chgrp -R deleteFolder $markDir
		
		passwdNum=$(cat /etc/passwd |grep $netId':' |wc -l)
		passwdResult=$(cat /etc/passwd |grep $netId':')
		echo "$passwdNum entries found. ";
		echo "Removing the following entry"
		echo $passwdResult
		sleep 2
		echo "Backing up passwd file"
		cp -p /etc/passwd /mnt/store3/admin/bkfiles/"passwd.$(date +%Y%m%d)"
		echo "Removing $netId from passwd file";
		sleep 3
		sed -i "/^$netId:/d" /etc/passwd
		passwdDelVerify=$(cat /etc/passwd |grep $netId':' |wc -l)
		if [ $passwdDelVerify -eq '0' ]; then
			echo "$netId successfully removed from passwd file";
		else
			echo "Error $netId was not removed from passwd file";
		break
		fi
		
		echo "Removing user from AD group GroupName"
		sleep 1
		groupremoveuser groupName  $netId
        break

fi
done

