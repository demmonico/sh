# Collection of snippets, commands and tools

Collection of bash / sh / cli snippets, commands and tools



### Common bash

Return to one line up in terminal
```bash
printf '\e[A\e[K'
```

##### Bash profile

[Follow to separate file](bash_profile/README.md)

##### Watching dashboard

```shell script
# ps filtering cron processes
watch -n 1 ' ps faux | grep -E "(cron|PID)" | grep -v grep | tail -n $(($LINES - 3))'
 
# ps filtering cron processes with count lines
watch -n 1 'ps faux | grep -E "(cron|PID)" | grep -v grep | tail -n $(($LINES - 3)) | awk "{ print } END { print NR - 1 }"'
 
# combine ps and tail
watch -n10 -d 'tail -n 100 /var/log/syslog | grep voucher && printf "%s\n" -------------------- && ps -aux | grep -v grep | grep -E "(PID|voucher)" && printf "%s\n" -------------------- && tail -n 10 /tmp/test_cms.log /tmp/test_cms_update.log'
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

##### Fetch config key-value from YAML file

```bash
// fetch
sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g;s/""/"/g' ${FILE_CONFIG}
 
// export fetched as key=value
export $( sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g;s/""/"/g' ${FILE_CONFIG} | xargs )
```



### System

##### Get different types of system info

<details><summary>System info</summary>
<pre><code>
if [[ "$OSTYPE" == "darwin"* ]]; then
    system_profiler SPHardwareDataType | awk '
            /Model Identifier/ {MODEL = $3}
            /Serial Number/ {SN = $4}
            /Hardware UUID/ {UUID = $3}
            END {
                printf ">>> Model %s, UUID %s, SN %s\n", MODEL, UUID, SN
            }'
fi
 
\# TODO add other OS
</code></pre>
</details>



<details><summary>CPU info</summary>
<pre><code>
if [[ "$OSTYPE" == "darwin"* ]]; then
    system_profiler SPHardwareDataType | awk '
            /Processor Name/ {NAME = substr($0, index($0,$3))}
            /Total Number of Cores/ {CORES = $5}
            /Processor Speed/ {FREQ = substr($0, index($0,$3))}
            END {
                printf ">>> CPU %s %sx%s\n", NAME, CORES, FREQ
            }'
fi
 
\# TODO add other OS
</code></pre>
</details>



<details><summary>RAM info</summary>
<pre><code>
 
\# Ubuntu
awk '/MemFree/ { printf "%.3f GiB\n", $2/1024/1024 }' /proc/meminfo
 
\# bash_profile MacOS
if [[ "$OSTYPE" == "darwin"* ]]; then
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
fi
 
\# TODO add other OS
</code></pre>
</details>



<details><summary>Disk info</summary>
<pre><code>
if [[ "$OSTYPE" == "darwin"* ]]; then
    INFO=''
    DISCS=($( df -h | grep '/dev/disk' | sort -u -n -k2 | awk '{print $1}' ))
    for DISC in "${DISCS[@]}"; do
        [[ -n "${INFO}" ]] && INFO+=' | '
        INFO+="$( diskutil info ${DISC} | awk '
            /Device Identifier/ {ID = $3}
            /Volume Name/ {VOLUME = substr($0, index($0,$3))}
            /File System Personality/ {FSTYPE = substr($0, index($0,$4))}
            /Volume Free Space/ {FREE = substr($6, 2)}
            /Volume Total Space/ {TOTAL = substr($6, 2)}
            END {
                printf "%s (%s), %s, free %.1f/%.1fG (%.1f%%)", VOLUME, ID, FSTYPE, (( FREE / 1024 / 1024 / 1024 )), (( TOTAL / 1024 / 1024 / 1024 )), (( FREE / TOTAL * 100 ))
            }' )"
    done
    echo ">>> ${INFO:-No /dev/disk* devices was found}"
fi
 
\# TODO add other OS
</code></pre>
</details>



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

##### Get public IP via CLI

```bash
dig TXT +short o-o.myaddr.l.google.com @ns1.google.com
# or
dig +short myip.opendns.com @resolver1.opendns.com
```

**Note** to install `dig` on Alpine run `apk add --update bind-tools`

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

##### Looking the pts list

```bash
who
# root     pts/3        2019-12-06 13:45 (10.84.69.203)

```

##### Send message to pts

```bash
write root pts/3

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

##### Normalize file path

```bash
FILE_CONFIG="$( name="$( basename "$2" )"; dir="$( cd "$( dirname "$2" )" && pwd )"; echo "${dir}/${name}" )"
```

##### Open multiple files

```bash
tail -n 10 /tmp/test_cms.log /tmp/test_cms_update.log'

# or to fetch all content
`tail -n +1 /tmp/test_cms.log /tmp/test_cms_update.log'` 
```

##### Pack / Unpack

Pack
```bash
# pack file/dir
tar -czvf name-of-archive.tar.gz /path/to/directory-or-file
 
# pack multiple sources
tar -czvf archive.tar.gz /home/ubuntu/Downloads /usr/local/stuff
 
# pack with exclude
tar -czvf archive.tar.gz /home/ubuntu --exclude=*.mp4
```

Unpack
```bash
# unpack file/dir
tar -xzvf archive.tar.gz
 
# unpack to the target folder
tar -xzvf archive.tar.gz -C /tmp
```

##### Work with ls
```bash
# wrap ls results
ls | while read i; do echo \|$i\|yes\|yes\|; done
 
# list only files
ls -p | grep -v /
 
# list all files in DIR
find . -type f -exec ls --block-size=M -nls {} + | sort -k 10
```

##### Get file's meta info

```bash
exiv2 pr IMG_20181223_000048.jpg
exiv2 pr IMG_20181223_000048.jpg | grep -oP 'Image timestamp : \K([0-9: ]+)'

```

##### Update file's date

```bash
# modified date + creation only if it earlier then current
touch -t 201812010000 IMG_20181223_000048.jpg
 
# both
SetFile -d "07/15/2019 12:00 PM" -m "07/15/2019 12:00 PM" YDXJ0121.jpg 
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
