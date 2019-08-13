# Collection of snippets, commands and tools

Collection of bash / sh / cli snippets, commands and tools



### Common bash

Return to one line up in terminal
```bash
printf '\e[A\e[K'
```

##### Bash profile

[Follow to separate file](bash_profile/README.md)



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



### System

##### RAM info

```bash
/usr/bin/vm_stat | sed 's/\.//' | awk '
            /page size of/ {BLOCK_SIZE = $8}
            /free/ {FREE_BLOCKS = $3}
            /Pages active/ {ACTIVE_BLOCKS = $3}
            /Pages inactive/ {INACTIVE_BLOCKS = $3}
            /speculative/ {SPECULATIVE_BLOCKS = $3}
            /wired/ {WIRED_BLOCKS = $4}
            /purgeable/ {PURGEABLE_BLOCKS = $3}
            /occupied by compressor/ {COMPRESSED_BLOCKS = $5}
            /backed/ {CACHED_FILES_BLOCKS = $3}
            /throttled/ {THROTTLED_BLOCKS = $3}
            /Swapouts/ {SWAPOUTS_BLOCKS = $2}
            END {
                WIRED=(( WIRED_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                COMPRESSED=(( COMPRESSED_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                APP=(( (ACTIVE_BLOCKS + INACTIVE_BLOCKS + SPECULATIVE_BLOCKS + THROTTLED_BLOCKS + PURGEABLE_BLOCKS) * BLOCK_SIZE / 1024 / 1024 - WIRED ))
                USED=(( APP + WIRED + COMPRESSED ))
                CACHED_FILES=(( (CACHED_FILES_BLOCKS + PURGEABLE_BLOCKS) * BLOCK_SIZE / 1024 / 1024 ))
                SWAP=(( SWAPOUTS_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                FREE=(( FREE_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                INACTIVE=(( INACTIVE_BLOCKS * BLOCK_SIZE / 1024 / 1024 ))
                printf "Free RAM %.1fG of %.1fG (page size %.1fK)\n", (( (FREE + INACTIVE) / 1024 )), (( (USED + CACHED_FILES + SWAP + FREE) / 1024 )), (( BLOCK_SIZE / 1024 ))
            }'
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



### Git

##### Clone repositories

[Follow to separate file](git_cloner/README.md)
