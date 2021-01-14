#!/bin/bash

# Set path to your GAMADV-XTD3 install
gam="/Users/alfie/bin/gamadv-xtd3/gam"

printf "Please enter the email of the user you wish to archive: "
read user

# Verify that a valid user email was entered
email_verification() {
    if $gam info user $user >/dev/null 2>&1; then
        return
    else
        printf "$user does not exist in Google Workplace."
    fi
    printf %s\\n "Please enter a valid email address."
    exit 1
}

# Create a log file and record all outputs of the script
start_log() {
    exec &> >(tee $user.log)
    echo "$(whoami) conducting offboarding for $user on $(date)"
}

# Find who the users manager was
identify_manager(){
    printf "\nFinding the manager of the $user..."
    manager=$($gam user $user print fields relations | grep manager | cut -d "," -f4)
    printf "\nManager found: $manager\n"
}

# Move the user to the Past Employees OU
move_ou() {
    printf "\nMoving $user to the Past Employees OU...\n"
    $gam update user $user ou Past\ Employees
}

# Change the users password to something random
change_password() {
    printf "\nResetting $user password to something random...\n"
    $gam update user $user password random
}

# Ask if you wish to transfer Google Drive files to manager
transfer_files_to_manager () {
    printf "\nDo you want to transfer user data to the manager? [yes or no]: "
    read yn
    case $yn in
        [yY][eE][sS] )
            echo "You said yes, transferring data...";
            $gam create datatransfer $user gdrive $manager privacy_level shared,private;;
        [nN][oO] )
            echo "You said no, continuing...";;
        * ) echo "Invalid input, exiting...";
            exit;;
    esac
} 

# Delete application specific passwords, backup verification codes, access tokens
# disable POP and IMAP access, sign user out and lastly turn off 2-Step verification
deprovision_user(){
    printf "\nDeprovisioning $user...\n"
    # We have to unsuspend the user first to allow us to turn off 2SV
    $gam update user $user suspended off 
    $gam user $user deprovision popimap signout turnoff2sv
    # Re-suspend the user after deprovisioning completed
    $gam update user $user suspended off 
}

# Wipe company user data from mobile devices
wipe_mobile_devices() {
    printf "\nWiping company user data from connected mobile devices...\n"
    $gam print mobile query "email:$user" > /tmp/$user-devices.csv
    $gam csv /tmp/$user-devices.csv gam update mobile ~resourceId action account_wipe
}

# Find what groups a user is a member of and then remove them from all found groups
remove_groups() {
    printf "\nRemoving $user from all groups...\n"
    purge_groups=$($gam print groups member $user | sed -e '1d')
    for i in $purge_groups; do
        $gam update group $i remove member $user
    done;
}

# Remove user from the global address list (GAL)
remove_from_directory() {
    printf "\nRemoving user from the directory...\n"
    $gam update user $user gal false
}

# Archive the user and update licences to reflect
archive_user() {
    printf "\nArchiving $user...\n"
    $gam update user $user archived true
    # We have to manually remove the user licence and then apply an archived licence
    printf "\nUpdating licence to an archive licence...\n"
    $gam user $user delete licence gau # gau = [SKU] Google-Apps-Unlimted (G Suite Business)
    $gam user $user add licence gsbau # gsbau = [SKU] 101034002 (G Suite Business Archived)
}

# Run all functions of the script, comment a function out here if you wish to not perform a particular step
email_verification
start_log
identify_manager
move_ou
change_password
transfer_files_to_manager
deprovision_user
wipe_mobile_devices
remove_groups
remove_from_directory
archive_user