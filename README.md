# Collection of snippets and commands

Collection of bash / sh / cli snippets and commands



### Common bash

##### Bash profile

```bash
# reload bashrc / bash_profile without logging out and back in
exec bash -l
```

###### Bash profile alias auto-registration

```bash
# automaticly register aliases to bashrc / bash_profile
# this snippet could be added to any script to add auto-register alias functionality

#################### Auto-registerer

PARAM_INSTALL_OPTION="-i"
SELF_SCRIPT_PATH="${BASH_SOURCE[0]}"
SELF_SCRIPT_FILENAME=`basename "${SELF_SCRIPT_PATH}"`

function autoRegisterer()
{
    local FILE_BASH_PROFILE=$1
    local ALIAS=$2

    if [[ ! -f "${FILE_BASH_PROFILE}" ]]; then
        touch "${FILE_BASH_PROFILE}"
    fi

    local LABEL_START="### auto-registered ${SELF_SCRIPT_FILENAME} >>>"
    local LABEL_END="### auto-registered ${SELF_SCRIPT_FILENAME} <<<"

    if grep -Fxq "${LABEL_START}" "${FILE_BASH_PROFILE}" && grep -Fxq "${LABEL_END}" "${FILE_BASH_PROFILE}"; then
        echo "Auto-registered sections already exist"
        exit
    else
        sh -c "cat >> ${FILE_BASH_PROFILE}" <<EOT

${LABEL_START}
alias ${ALIAS}="${SELF_SCRIPT_PATH}"
${LABEL_END}
EOT
    fi
}

########## Main

if [[ -n "${BASH_VERSION}" ]] && [[ "$1" == "${PARAM_INSTALL_OPTION}" ]]; then
    read -p "Pls, check you HOMEDIR [${HOME}]: " HOME_DIR
    HOME_DIR="${HOME_DIR:-"${HOME}"}"
    DEFAULT_ALIAS="${SELF_SCRIPT_FILENAME%.*}"
    read -p "Pls, check alias you wanted to link with [${DEFAULT_ALIAS}]: " ALIAS
    ALIAS=${ALIAS:-${DEFAULT_ALIAS}}

    FILE_BASH_PROFILE=".bashrc"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        FILE_BASH_PROFILE=".bash_profile"
        echo "MacOS was detected"
    fi
    FILE_BASH_PROFILE="${HOME_DIR}/${FILE_BASH_PROFILE}"

    autoRegisterer "${FILE_BASH_PROFILE}" "${ALIAS}"
    echo "Auto-registeration at file '${FILE_BASH_PROFILE}' has been completed!"
    echo "Don't forget to reload shell e.g. '. ${FILE_BASH_PROFILE}'"

    exec bash -l

    exit 0;
fi

#################### Auto-registerer

```



### Strings

##### Work with Grep

```bash
# show several lines before and after match
grep -B 2 -A 10 'wrong JSON'

# custom group separator
grep --group-separator=$'\n\n' 'wrong JSON'

```

##### Find substring occurrences in one or multiple strings

```bash
# source - file ~/enterprise.txt
awk -F'"po_description":"1 Gbps"' 'NF{print NF-1}' ~/enterprise.txt | awk '{sum+=$1} END {print sum}'

```

##### Find string occurrences in source folder

During search skip "Permission denied" warnings

```bash
# source - root dir
find / -type f -exec grep -il "needle" {} \; 2>&1 | grep -v "Permission denied"

```



### Networks

##### List open ports

```bash
lsof -i
```

##### List local IPs

```bash
# including 127.0.0.1
ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
# without 127.0.0.1
ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
```

##### Connect via FTP

```bash
ftp -4 192.168.0.101 2121
```

##### Check file exists via FTP

```bash
wget -S --spider ftp://192.168.0.101:2121/DCIM/Camera/ 2>&1 | grep 'IMG_20181223_000048.jpg'
```

##### Send request via cUrl

```bash
# get html body
curl -k -X POST https://website

# with Basic Auth
curl -k -X POST --user username:secret https://website

# get headers
curl -k -I -X POST https://website
```

##### Re-read OpenSSH keys for PhpStorm

```bash
ssh-add -K ~/.ssh/id_rsa

```



### Disks

For successful clone disk you have to do following:
- [Get disk's mount point](#get-disks-mount-point)
- [Unmount disk and drive (for USB)](#unmount-disk-and-drive-for-usb)
- [Makes disk's image](#makes-disks-image)

##### Get disk's mount point

```bash
diskutil list
```

##### Unmount disk and drive (for USB)

```bash
diskutil unmount /dev/disk1s2
diskutil unmountDisk /dev/disk1
```

##### Makes disk's image

**WARNING!!! Be careful with drives names! Check before run!!!** , see [Get disk's mount point](#get-disks-mount-point)

```bash
# direct clone disk
sudo dd if=/dev/sdd of=/dev/sdc

# simple creates and restore image
sudo dd if=/dev/sdd of=/hdd/dmini/_install/win10/win10.iso
sudo dd if=/hdd/dmini/_install/win10/win10.iso of=/dev/sdc


# creates and restore compressed image with progress
# WARNING doesn't work on MacOS
# WARNING could be wrong shown disk size
sudo dd if=/dev/sdc bs=32M status=progress | gzip > /hdd/dstorage/win10.iso
sudo dd if=/hdd/dstorage/win10.iso of=/dev/sdd bs=32M status=progress

```



### Files

##### Work with ls
```bash
# wrap ls results
ls | while read i; do echo \|$i\|yes\|yes\|; done
 
# list only files
ls -p | grep -v /
```

##### Get file's meta info

```bash
exiv2 pr IMG_20181223_000048.jpg
exiv2 pr IMG_20181223_000048.jpg | grep -oP 'Image timestamp : \K([0-9: ]+)'

```

##### Update file's date

```bash
touch -t 201812010000 IMG_20181223_000048.jpg

```

##### Unlock file changes

```bash
# single
chflags -R nouchg

# all in current path
sudo find . -type f -exec sh -c "chflags -R nouchg" {} +

```



### Docker

##### Containers list sorted by name

```bash
docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Status}}\t{{.Ports}}" | (read -r; printf "%s\n" "$REPLY"; sort -k 1 )
```
