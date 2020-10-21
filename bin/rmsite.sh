#!/usr/bin/env bash

#-----------------------------------------------------------#
# Remove virtual host from Apache web-server /var/www
#
# @author: demmonico <demmonico@gmail.com> <https://github.com/demmonico>
# @date: 16 Aug 2016
# @package: https://github.com/demmonico/sh
# @package-moved-from: https://github.com/demmonico/bash
#
# @use: sudo ./rmsite.sh [PARAMS]
# params:
# -n [SITENAME] (required)
# -g [USERGROUP] (owner's groupname, default - option -n [SITENAME])
#-----------------------------------------------------------#



# die
function die
{
    local msg=$@;
    if [ -n "$msg" ]; then
        msg="Error: $msg";
    fi;
    echo "$msg" 1>&2;
    exit 1;
}



# create user group
function rmGroup
{
    echo "Removing group for current site ...";

    # set required params
    groupname=$1;
    if [ -z "$groupname" ]; then
        echo "Sitename will be use as a groupname";
        groupname=$2;
    fi;

    # add group
    if ! grep -q $groupname /etc/group; then
        read -p "Group \"$groupname\" doesn't exists. Would you like to remove another group (y/n)? " choice
        case "$choice" in
            y|Y )
                read -p "Enter groupname which will be removed: " groupname;
                rmGroup $groupname $2;;
            * );;
        esac
    else
        sudo groupdel $groupname
        echo "Group \"$groupname\" was removed successfully";
    fi;
}



# remove site public directory
function rmSiteFolder
{
    echo "Removing website public directory \"/var/www/$sitename\" ...";

    # remove
    sudo rm -rf -- /var/www/$sitename;
    echo "Done";
}



# remove apache config
function rmConfigApache
{
    echo "Removing config apache ...";

    # remove apache config available
    ## disable website config
    #echo "Disabling website config ...";
    #sudo a2disconf $sitename
    #echo "Done";
    ## delete conf file
    echo "Deleting apache config file ...";
    sudo rm -f -- /etc/apache2/conf-available/$sitename.conf;
    echo "Done";

    # remove apache site config
    ## disable website
    echo "Disabling website ...";
    sudo a2dissite $sitename.conf
    echo "Done";
    ## delete conf file
    echo "Deleting website config file ...";
    sudo rm -f -- /etc/apache2/sites-available/$sitename.conf;
    echo "Done";

    # update hosts
    echo "Updating available hosts ...";
    local domain=`echo "$sitename" | sed 's/\./\\\\./g'`;       # shield dots
    sudo sed -i "/^127\.0\.0\.1\s*$domain$/d" /etc/hosts;       # remove lines by pattern
    echo "Done";

    # restart apache
    echo "Restart apache service ...";
    sudo service apache2 restart
    echo "Done";
}



# get valid DB name
function getDbName
{
    local t=$(echo $sitename | sed -r 's/[^A-Za-z0-9]+.*//g');
    echo $t;
}



# remove database
function rmDatabase
{
    echo "Removing database \"$sitename\" ...";

    # check for running MySQL
    UP=$(pgrep mysql | wc -l);
    if (( "$UP" < 1 )); then
        echo "MySQL is not running yet. Stop removing";
    else
        # get root password
        local mysqlRootPassword;
        read -s -p "Enter your MySQL password (ENTER for none): " mysqlRootPassword;
        until mysql -u root -p$mysqlRootPassword  -e ";" ; do
               read -p "Can't connect, please retry: " mysqlRootPassword
        done;
        # remove DB
        local dbName=$(getDbName);
        if [ -n "$mysqlRootPassword" ]; then
            mysql -uroot -p$mysqlRootPassword -e "drop database $dbName"
        else
            mysql -uroot -e "drop database $dbName"
        fi;
        echo "Done";
    fi;
}






#-----------------------------------------------------------#
#                           MAIN
#-----------------------------------------------------------#

# get params and options
while getopts ":n:g:" opt; do
    case $opt in
        n) sitename="$OPTARG";;
        g) groupname="$OPTARG";;
        \?) echo "Invalid option -$OPTARG" >&2;;
    esac
done

# validate required params
if [ -z "$sitename" ]; then
    die "Website name cannot be empty";
fi;
if [ "$EUID" -ne 0 ]; then
    die "Please run as root";
fi;



# remove site public directory
rmSiteFolder;

# remove new group for current site
rmGroup $groupname $sitename;

# remove apache config
rmConfigApache;

# remove database
read -p "Would you like to remove related MYSQL database (y/n)? " choice
case "$choice" in
    y|Y )
        rmDatabase;;
    * );;
esac



# finish
echo "";
echo "Your website \"$sitename\" with configs and relations was removed successfully. Have a nice day :)";
echo "";
