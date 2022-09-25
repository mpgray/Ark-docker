FROM cm2network/steamcmd:root

MAINTAINER motey

# Var for first config
# Server Name
ENV SESSIONNAME "Ark Docker"
# Map name
ENV SERVERMAP "TheIsland"
# Server password
ENV SERVERPASSWORD ""
# Admin password
ENV ADMINPASSWORD "adminpassword"
# Nb Players
ENV NBPLAYERS 30
# If the server is updating when start with docker start
ENV UPDATEONSTART 1
# if the server is backup when start with docker start
ENV BACKUPONSTART 1
#  Tag on github for ark server tools
ENV GIT_TAG v1.6.57
# Server PORT (you can't remap with docker, it doesn't work)
ENV SERVERPORT 27015
# Steam port (you can't remap with docker, it doesn't work)
ENV STEAMPORT 7778
# if the server should backup after stopping
ENV BACKUPONSTOP 0
# If the server warn the players before stopping
ENV WARNONSTOP 0
# Number of Players allowed on the server at once.
ENV NBPLAYERS 30
# UID of the user steam
ENV UID 1000
# GID of the user steam
ENV GID 1000

# Install dependencies
RUN apt-get update &&\
    apt-get install -y sudo git curl wget cron

# Enable passwordless sudo for users under the "sudo" group
RUN sed -i.bkp -e \
	's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
	/etc/sudoers

# Add to sudo group
RUN usermod -a -G sudo steam

# Copy & rights to folders
COPY run.sh /home/steam/run.sh
COPY user.sh /home/steam/user.sh
COPY crontab /home/steam/crontab
COPY arkmanager-user.cfg /home/steam/arkmanager.cfg

RUN touch /root/.bash_profile
RUN chmod 777 /home/steam/run.sh
RUN chmod 777 /home/steam/user.sh
RUN mkdir /ark &&\
    mkdir /cluster


# We use the git method, because api github has a limit ;)
RUN  git clone https://github.com/arkmanager/ark-server-tools.git /home/steam/ark-server-tools
WORKDIR /home/steam/ark-server-tools/
RUN  git checkout $GIT_TAG
# Install
WORKDIR /home/steam/ark-server-tools/tools
RUN chmod +x install.sh
RUN ./install.sh steam

# Allow crontab to call arkmanager
RUN ln -s /usr/local/bin/arkmanager /usr/bin/arkmanager

# Define default config file in /etc/arkmanager
COPY arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg

# Define default config file in /etc/arkmanager
COPY instance.cfg /etc/arkmanager/instances/main.cfg

RUN chown steam -R /ark && chmod 755 -R /ark

# Fix permissions for config files
RUN chown steam -R /etc/arkmanager/instances && chmod 755 -R /etc/arkmanager/instances

EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}
# Add UDP
EXPOSE ${STEAMPORT}/udp ${SERVERPORT}/udp

VOLUME  /ark
VOLUME  /cluster

# Change the working directory to /arkd
WORKDIR /ark

# Update game launch the game.
ENTRYPOINT ["/home/steam/user.sh"]
