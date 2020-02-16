# eqemu-server-docker
Dolalin's eqemu Docker image home. Builds a standalone Docker image of the EQEmu Server.

## How to Use

### Binaries Included

The following binaries are installed in /usr/local/bin:

- eqlaunch  
- export_client_files  
- import_client_files  
- loginserver
- queryserv  
- shared_memory  
- ucs  
- world  
- zone

Hence you can run any of them using this image. Just vary the ENTRYPOINT to match one of the above.

### Configuration

The WORKDIR is set to /home/eqemu, where the EQEmu configuration files are stored. All the executables will pick these up at run time:

- eqemu_config.json  
- log.ini  
- login.json  
- login_opcodes.conf  
- login_opcodes_sod.conf  

You probably want to edit the eqemu_config.json and/or login.json and mount them into the container as volumes at runtime with your own config. These are just the defaults copied out of the source tree.

The default ENTRYPOINT on the image is /bin/bash, at some point I will add a startup.sh shim script here and make everything configurable by ENV variables. For now, mount in your config files and vary the ENTRYPOINT to one of the above executables, depending on what you want to run (login server, zone server, world server, etc). 

## This is really complicated, can't you just give me a docker-compose.yml?

Yep I can.

Assuming you have a MySQL database with the Project EQ schema loaded up and accessible on 127.0.0.1, with a root login of root/root, you can use this docker-compose.yml to bring up a full PEQ stack:

https://github.com/dbsanfte/eqemu-server-docker/blob/master/conf/docker-compose.yml

- Create a /home/eqemu folder on your VM 
- Drop eqemu_conf.json, install_variables.txt and login.json in there (with good settings, see conf for examples)
- Drop the docker-compose.yml in there
- `mkdir -p /home/eqemu/shared`
- Then just do this: `cd /home/eqemu && docker-compose up -d --scale zone=10`

Change `10` in the above command to however many zone servers you want to run. 

## Setting up the MySQL server for the first time is really hard too. How did you do it?

Here's a simple default setup, obviously it's a bit insecure, but it gets you going:

- `sudo apt-get update`
- `sudo apt-get install -y wget curl vim mariadb-server`

Now:

- `mysql -u root` to connect to your mysql server once it's up
- Then enter this sql: `GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'; create database peq;`

Finally, to prime the db:

- `wget http://edit.peqtgc.com/weekly/peq_beta.zip -O /tmp/peq_beta.zip`
- `wget https://raw.githubusercontent.com/EQEmu/Server/master/loginserver/login_util/login_schema.sql -O /tmp/login_schema.sql`
- `cd /tmp/`
- `unzip -o peq_beta.zip`
- `mysql -h 127.0.0.1 -uroot -proot peq < peqbeta.sql`
- `mysql -h 127.0.0.1 -uroot -proot peq < player_tables.sql`
- `mysql -h 127.0.0.1 -uroot -proot peq < login_schema.sql`

Now you should have a db that will work with the docker-compose.yml above. 
