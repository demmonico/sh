# Bash / sh collection

Collection of bash / sh / cli snippets, commands and tools



### Common bash

Return to one line up in terminal
```shell script
printf '\e[A\e[K'
```

##### Watching dashboard

```shell script
# ps filtering cron processes
watch -n 1 'ps faux | grep -E "(cron|PID)" | grep -v grep | tail -n $(($LINES - 3))'
 
# ps filtering cron processes with count lines
watch -n 1 'ps faux | grep -E "(cron|PID)" | grep -v grep | tail -n $(($LINES - 3)) | awk "{ print } END { print NR - 1 }"'
 
# combine ps and tail
watch -n10 -d 'tail -n 100 /var/log/syslog | grep voucher && printf "%s\n" -------------------- && ps -aux | grep -v grep | grep -E "(PID|voucher)" && printf "%s\n" -------------------- && tail -n 10 /tmp/test_cms.log /tmp/test_cms_update.log'
```

##### Runs script and measure time

```shell script
date && /usr/bin/php5 script.php && date
```

##### Backgrounding shell session

Use screen command

```shell script
# list sessions
screen -ls
# start named session
screen -S name
# resume named session
screen -r name
```
 



### Strings

##### Work with Grep

```shell script
# show several lines before and after match
grep -B 2 -A 10 'wrong JSON'

# custom group separator
grep --group-separator=$'\n\n' 'wrong JSON'

```

##### Find substring occurrences in one or multiple strings

```shell script
# source - file ~/enterprise.txt
awk -F'"po_description":"1 Gbps"' 'NF{print NF-1}' ~/enterprise.txt | awk '{sum+=$1} END {print sum}'

```

##### Fetch config key-value from YAML file

```shell script
// fetch
sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g;s/""/"/g' ${FILE_CONFIG}
 
// export fetched as key=value
export $( sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g;s/""/"/g' ${FILE_CONFIG} | xargs )
```

##### Show lines between selected

```shell script
$ cat file.txt
line 1
line 2
...
line 49
line 50
 
$ cat file.txt | awk '/line 1/{f=1;next} /line 50/{f=0} f'
line 2
...
line 49
```

##### Mask all secrets at the K8s secrets template

```shell script
// using select between lines
eval "${HELM_UPGRADE_CMD}" | awk '/type: "Opaque"/{f=1;next} /---/{f=0} f' | grep '^\s' | sed -E "s/([A-Za-z0-9_]+):\s[^,]+([',])/\1: <MASKED_SECRET>\2/g"
 
// using line-by-line processing
function maskSecretsAtLine() {
  local line="$1"
  local SEPARATOR=':[[:space:]]*'

  while IFS= read -r secret; do
    pattern="^[[:space:]]+${secret}:[[:space:]]+"
    if [[ "$line" =~ $pattern ]]; then
      line="$( echo "$line" | sed "s/\(^[[:space:]]*${secret}${SEPARATOR}\).*$/\1<MASKED_SECRET>/" )"
    fi
  done <<< "${SECRETS_LIST}"

  echo "$line"
}
helm upgrade ... | while IFS= read -r line; do maskSecretsAtLine "$line"; done
```

##### Mask all secrets from string

```shell script
// string like Helm's --set-string argument ('SECRET=secret value,SECRET2=Another value')
function maskSecrets() {
  local SEPARATOR='='
  # secrets SHOULD NOT contain single quotes (')
  echo "$1" | sed -E "s/([A-Za-z0-9_]+)${SEPARATOR}[^,]+([',])/\1${SEPARATOR}<MASKED_SECRET>\2/g"
}

echo "$( maskSecrets HELM_UPGRADE_CMD )"
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

```shell script
lsof -i
```

##### List local IPs

```shell script
# including 127.0.0.1
ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'
# without 127.0.0.1
ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
```

##### Get public IP via CLI

```shell script
dig TXT +short o-o.myaddr.l.google.com @ns1.google.com
# or
dig +short myip.opendns.com @resolver1.opendns.com
```

**Note** to install `dig` on Alpine run `apk add --update bind-tools`

##### Connect via FTP

```shell script
ftp -4 192.168.0.101 2121
```

##### Check file exists via FTP

```shell script
wget -S --spider ftp://192.168.0.101:2121/DCIM/Camera/ 2>&1 | grep 'IMG_20181223_000048.jpg'
```

##### Send request via cUrl

```shell script
# get html body
curl -k -X POST https://website

# with Basic Auth
curl -k -X POST --user username:secret https://website

# get headers
curl -k -I -X POST https://website
```

##### Check which TLS version website supports
```shell script
curl -I --tls-max 1.1 https://website
# 
# if response is 
# curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to
# then TLS version less or equal to 1.1 is rejected (but we still don't know about higher, e.g. TLSv1.2)
#
# if response is
# HTTP/2 200
# then TLS version started with 1.1 is supported (but we still don't know about lower, e.g. TLSv1.0)
 
# so to validate that you should consequencely check
curl -I --tls-max 1.0 https://website
curl -I --tls-max 1.1 https://website
curl -I --tls-max 1.2 https://website
```

##### Check which HTTP version website supports
```shell script
curl -sI https://website -o/dev/null -w '%{http_version}\n'
# response is '2' or '1.1'
# e.g.
curl -sI https://curl.haxx.se -o/dev/null -w '%{http_version}\n'
# 2
curl -sI http://curl.haxx.se -o/dev/null -w '%{http_version}\n'
# 1.1
```

##### Re-read OpenSSH keys for PhpStorm

```shell script
ssh-add -K ~/.ssh/id_rsa

```

##### Generate self-signed SSL certificate

```shell script
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
 
# non-verbosy w/o password phrase and for localhost
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj '/CN=localhost'
```

##### Looking the pts list

```shell script
who
# root     pts/3        2019-12-06 13:45 (10.84.69.203)

```

##### Send message to pts

```shell script
write root pts/3

```



### Disks

For successful clone disk you have to do following:
- [Get disk's mount point](#get-disks-mount-point)
- [Unmount disk and drive (for USB)](#unmount-disk-and-drive-for-usb)
- [Makes disk's image](#makes-disks-image)

##### Get disk's mount point

```shell script
diskutil list
```

##### Unmount disk and drive (for USB)

```shell script
diskutil unmount /dev/disk1s2
diskutil unmountDisk /dev/disk1
```

##### Makes disk's image

**WARNING!!! Be careful with drives names! Check before run!!!** , see [Get disk's mount point](#get-disks-mount-point)

```shell script
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

##### Get disk free space

Get disk mount points + free space

```shell script
lsblk
```

Get the disk's free space by each of the mount points

```shell script
df -h
```

Get the disk's free space for the particular folder

```shell script
df -h /builds
df -h /var/lib/docker
```

List the folders having more than 1Gb of the used disk space

```shell
du -h / 2>/dev/null | grep '^[0-9]\+G' | sort -n -r
```



### Files

##### Normalize file path

```shell script
FILE_CONFIG="$( name="$( basename "$2" )"; dir="$( cd "$( dirname "$2" )" && pwd )"; echo "${dir}/${name}" )"
```

##### Open multiple files

```shell script
tail -n 10 /tmp/test_cms.log /tmp/test_cms_update.log'

# or to fetch all content
`tail -n +1 /tmp/test_cms.log /tmp/test_cms_update.log'` 
```

##### Find string occurrences in source folder

During search skip "Permission denied" warnings

```shell script
# source - root dir
find / -type f -exec grep -il "needle" {} \; 2>&1 | grep -v "Permission denied"

```

##### Pack / Unpack

Pack
```shell script
# pack file/dir
tar -czvf name-of-archive.tar.gz /path/to/directory-or-file
 
# pack multiple sources
tar -czvf archive.tar.gz /home/ubuntu/Downloads /usr/local/stuff
 
# pack with exclude
tar -czvf archive.tar.gz /home/ubuntu --exclude=*.mp4
```

Unpack
```shell script
# unpack file/dir
tar -xzvf archive.tar.gz
 
# unpack to the target folder
tar -xzvf archive.tar.gz -C /tmp
```

##### Work with ls
```shell script
# wrap ls results
ls | while read i; do echo \|$i\|yes\|yes\|; done
 
# list only files
ls -p | grep -v /
 
# list all files in DIR
find . -type f -exec ls --block-size=M -nls {} + | sort -k 10
```

##### Get file's meta info

```shell script
exiv2 pr IMG_20181223_000048.jpg
exiv2 pr IMG_20181223_000048.jpg | grep -oP 'Image timestamp : \K([0-9: ]+)'

```

##### Update file's date

```shell script
# modified date + creation only if it earlier then current
touch -t 201812010000 IMG_20181223_000048.jpg
 
# both
SetFile -d "07/15/2019 12:00 PM" -m "07/15/2019 12:00 PM" YDXJ0121.jpg 
```

##### Unlock file changes

```shell script
# single
chflags -R nouchg

# all in current path
sudo find . -type f -exec sh -c "chflags -R nouchg" {} +
```

##### Sort file in-place
```shell script
sort -o file file

# Without repeating the filename
sort -o file{,}
```
