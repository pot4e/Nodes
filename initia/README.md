# Initia Validator Node Guildline

# Overview

Operating an Initia node demands significant server resources and is primarily necessary for specific tasks, such as developing dApps or functioning as validators. 

# Hardware

The minimum hardware requirements for running an Initia node are:

```bash
CPU: 4 cores

Memory: 16GB RAM

Disk: 1 TB SSD Storage

Bandwidth: 100 Mbps
```

# OS requirements

![os](./images/os.png)

# Building Initia

## Step 1

Update all the packages

```bash
sudo apt -q update && sudo apt -yq install curl git jq lz4 build-essential && sudo apt -yq upgrade
```

## Step2: 

Install go version 1.21.10

```bash
wget https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile
```

## Step 3

Clone and build the Initia [source code repo](https://github.com/initia-labs/initia).

```bash
cd $HOME
rm -rf initia # run if you have already cloned it.
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.14
```

Build binaries

```bash
make build
make install
```

After install successfully, check the initiad version

```bash
initiad version
```
if you encounter with `initiad not found`, 

Adding this under `.bashrc` file

```bash 

nano ~/.bashrc
```

then add this in the end of file. 

```bash
export PATH=$PATH:$(go env GOBIN):$(go env GOPATH)/bin
```

Finally, reload the file again

```bash
source ~/.bashrc
```

# Set up Enviroment

Because initia will open amount of file while running. By default, the ubuntu is only allow open 1024 files in paralel 

Therefore, we need to change to another higher number

Check current limitation

```bash
ulimit -n
```
![os](./images/limit.png)

Edit the limit

```bash
sudo nano /etc/security/limits.conf 
```

Add copy and paste to the file

```bash
# /etc/security/limits.conf
#
#Each line describes a limit for a user in the form:
#
#<domain>        <type>  <item>  <value>
#
#Where:
#<domain> can be:
#        - a user name
#        - a group name, with @group syntax
#        - the wildcard *, for default entry
#        - the wildcard %, can be also used with %group syntax,
#                 for maxlogin limit
#        - NOTE: group and wildcard limits are not applied to root.
#          To apply a limit to the root user, <domain> must be
#          the literal username root.
#
#<type> can have the two values:
#        - "soft" for enforcing the soft limits
#        - "hard" for enforcing hard limits
#
#<item> can be one of the following:
#        - core - limits the core file size (KB)
#        - data - max data size (KB)
#        - fsize - maximum filesize (KB)
#        - memlock - max locked-in-memory address space (KB)
#        - nofile - max number of open file descriptors
#        - rss - max resident set size (KB)
#        - stack - max stack size (KB)
#        - cpu - max CPU time (MIN)
#        - nproc - max number of processes
#        - as - address space limit (KB)
#        - maxlogins - max number of logins for this user
#        - maxsyslogins - max number of logins on the system
#        - priority - the priority to run user process with
#        - locks - max number of file locks the user can hold
#        - sigpending - max number of pending signals
#        - msgqueue - max memory used by POSIX message queues (bytes)
#        - nice - max nice priority allowed to raise to values: [-20, 19]
#        - rtprio - max realtime priority
#        - chroot - change root to directory (Debian-specific)
#
#<domain>      <type>  <item>         <value>
#

#*               soft    core            0
#root            hard    core            100000
#*               hard    rss             10000
#@student        hard    nproc           20
#@faculty        soft    nproc           20
#@faculty        hard    nproc           50
#ftp             hard    nproc           0
#ftp             -       chroot          /ftp
#@student        -       maxlogins       4

root                soft    nofile          65535
root                hard    nofile          65535

# End of file
```

then `ctrl+x`, hit `y` and `enter`.

then reboot to update the limit. 

After reboot, check it again

![os](./images/limit2.png)

