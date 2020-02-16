# eqemu-server-docker
Builds a standalone Docker image of the EQEmu Server.

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

Create a /home/eqemu folder, drop eqemu_conf.json, install_variables.txt and login.json in there (with good settings, see conf for examples), then download docker-compose.yml there, and from /home/eqemu just do this:

`docker-compose up -d`

