#!/usr/bin/env bash

#-----------------------------------------------------------#
# Init new virtual host under Apache web-server /var/www
#
# @author: demmonico <demmonico@gmail.com> <https://github.com/demmonico>
# @date: 16 Aug 2016
# @package: https://github.com/demmonico/sh
# @package-moved-from: https://github.com/demmonico/bash
#
# @use: sudo ./newsite.sh [PARAMS]
# params:
# -n [SITENAME] (required)
# -u [USERNAME] (owner's username, default - current username)
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
function createGroup
{
    echo "Creating new group for current site ...";

    # set required params
    groupname=$1;
    if [ -z "$groupname" ]; then
        echo "Sitename will be use as a groupname";
        groupname=$2;
    fi;

    # add group
    if ! grep -q $groupname /etc/group; then
        sudo groupadd $groupname
        echo "Group \"$groupname\" was added successfully";
    else
        read -p "Group \"$groupname\" already exists. Would you like to create another group (y/n)? " choice
        case "$choice" in
            y|Y )
                read -p "Enter new groupname which will own this site folder: " groupname;
                createGroup $groupname $2;;
            * );;
        esac
    fi;
}



# create user to group
function addGroupUser
{
    echo "Adding user to group ...";

    # set username
    if [ -z "$1" ]; then
        if [ -z "$isForceMode" ]; then
            if [ -z "$SUDO_USER" ]; then
                while [ -z "$username" ]; do
                    read -p "Enter username which will be added to group \"$groupname\": " username
                done;
            else
                username=$SUDO_USER;
            fi;
        else
            $username=$(whoami);
        fi;
    else
        $username=$1;
    fi;

    # add user to group
    if getent group $username | grep &>/dev/null $groupname; then
        echo "User \"$username\" already exists in group \"$groupname\"";
    else
        sudo usermod -a -G $groupname $username
        echo "User \"$username\" was added to group \"$groupname\" successfully";
    fi;

    # add webuser to group
    local webservername;
    echo "Detecting webserver username ...";
    if id -u www-data > /dev/null 2>&1; then
        webservername="www-data";
    elif id -u apache > /dev/null 2>&1; then
        webservername="apache";
    else
        read -p "Enter webserver username to add it to \"$groupname\": " webservername
    fi;
    if [ -n "$webservername" ]; then
        sudo usermod -a -G $groupname $webservername
        echo "User \"$webservername\" was added to group \"$groupname\" successfully";
    else
        die "Webserver username is required";
    fi;
}



# create site public directory
function createSiteFolder
{
    # create website folder
    echo "Create website public directory \"/var/www/$sitename\" ...";
    sudo mkdir -p /var/www/$sitename
    echo "Done";

    # git init
    echo "Initiate git ...";
    cd /var/www/$sitename && git init && cd -
    echo "Done";
    
    # create log folder
    echo "Create website log directory \"/var/www/$sitename/log\" ...";
    mkdir -p /var/www/$sitename/log
    echo "Done";
    
    # FIX permissions
    echo "Set website public directory owner and permissions ...";
    #sudo chown -R $USER:$USER /var/www
    sudo chown -R $username:$groupname /var/www/$sitename
    #sudo chmod -R g+rw /var/www
    sudo chmod -R 02775 /var/www/$sitename
    echo "Done";
}



# add apache config
function configApache
{
    echo "Configuring apache to make website available ...";

    # set apache site config
    echo "Writing apache config ...";
    (
        echo "<VirtualHost *:80>";
        echo "    ServerAdmin admin@$sitename";
        echo "    ServerName $sitename";
        echo "    ServerAlias www.$sitename";
        echo "    DocumentRoot /var/www/$sitename";
        echo "    <Directory /var/www/$sitename/>";
        echo "        Options Indexes FollowSymLinks MultiViews";
        echo "        AllowOverride All";
        echo "        Order allow,deny";
        echo "        allow from all";
        echo "    </Directory>";
        echo "    #LogLevel info ssl:warn";
        echo "    ErrorLog /var/www/$sitename/log/error.log";
        echo "    CustomLog /var/www/$sitename/log/access.log combined";
        echo "    #Include conf-available/serve-cgi-bin.conf";
        echo "</VirtualHost>";
    ) | sudo tee /etc/apache2/sites-available/$sitename.conf
    echo "Done";
    ## enable website
    echo "Enabling website ...";
    sudo a2ensite $sitename.conf
    echo "Done";

    # add apache config available (to avoid AH00558 error)
    #echo "Adding apache config available ...";
    #echo "ServerName $sitename" | sudo tee /etc/apache2/conf-available/$sitename.conf
    #echo "Done";
    ## enable website config
    #echo "Enabling website config ...";
    #sudo a2enconf $sitename
    #echo "Done";

    # update hosts
    echo "Updating available hosts ...";
    echo "127.0.0.1        $sitename" | sudo tee -a /etc/hosts;
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



# add mysql database
function createDatabase
{
    echo "Creating database \"$sitename\" ...";

    # check for running MySQL
    UP=$(pgrep mysql | wc -l);
    if (( "$UP" < 1 )); then
        echo "MySQL is not running yet. Stop creating";
    else
        ## get root password
        local mysqlRootPassword;
        read -s -p "Enter your MySQL password (ENTER for none): " mysqlRootPassword;
        until mysql -u root -p$mysqlRootPassword  -e ";" ; do
               read -s -p "Can't connect, please retry: " mysqlRootPassword
        done;
        ## create DB
        local dbName=$(getDbName);
        if [ -n "$mysqlRootPassword" ]; then
            mysql -uroot -p$mysqlRootPassword -e "create database $dbName"
        else
            mysql -uroot -e "create database $dbName"
        fi;
        echo "Done";
    fi;
}






#-----------------------------------------------------------#
#                           MAIN
#-----------------------------------------------------------#

# get params and options
#while  ":n:u:g:" opt; do
#    case $opt in
#        n) sitename="$OPTARG";;
#        u) username="$OPTARG";;
#        g) groupname="$OPTARG";;
#        \?) echo "Invalid option -$OPTARG" >&2;;
#    esac
#done
while [[ $# -gt 1 ]] 
do
        key="$1"
    case $key in
        -f) isForceMode='true';;
        -n|--name)
            if [ ! -z "$2" ]; then
                export sitename="$2"
            fi
            shift
            ;;
        -u|--username)
            if [ ! -z "$2" ]; then
                export username="$2"
            fi
            shift
            ;;
        -g|--groupname)
            if [ ! -z "$2" ]; then
                export groupname="$2"
            fi
            shift
            ;;
        *)
            echo "Invalid option -$1"
            break
            ;;
    esac
        shift
done


# validate required params
if [ -z "$sitename" ]; then
    die "Website name cannot be empty";
fi;
if [ "$EUID" -ne 0 ]; then
    die "Please run as root";
fi;



# create new group for current site
createGroup $groupname $sitename;

# add user to new group for current site
if [ -z "$isForceMode" ]; then
    addGroupUser $username;
else
    addGroupUser;
fi;

# create site public directory
createSiteFolder;

# add apache config
configApache;

# create database only at manual (not force) mode
if [ -z "$isForceMode" ]; then
    read -p "Would you like to create related MYSQL database (y/n)? " choice
    case "$choice" in
        y|Y )
            createDatabase;;
        * );;
    esac
fi;



# finish
echo "";
echo "Now you can see your new website at \"http://$sitename/\"";
echo "All done. Have a nice day :)";
echo "";
