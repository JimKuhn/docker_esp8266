FROM debian:jessie
MAINTAINER Jim Kuhn <j.kuhn@computer.org>
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y netcat-openbsd && mkdir /pp
RUN /bin/echo -e \
'HOST=$(ip route show default|grep via|head -1|awk '"'"'{print $3}'"'"')\n' \
'PROXY_FILE="/etc/apt/apt.conf.d/02proxy"\n' \
'echo -n "apt-get PROXY "\n' \
'if nc -w 1 $HOST 3142\n' \
'then\n' \
'echo "Acquire::http { Proxy \"http://$HOST:3142\"; };" >$PROXY_FILE\n' \
'echo "enabled"\n' \
'else\n' \
'echo "disabled"\n' \
'rm -f $PROXY_FILE\n' \
'fi\n' \
>/pp/enable_package_proxy.sh
RUN DIR=$(dirname $(which apt-get)); mv $(which apt-get) /pp; echo 'sh /pp/enable_package_proxy.sh && exec /pp/apt-get $*' >$DIR/apt-get; chmod +x $DIR/apt-get
RUN echo "America/Toronto"|tee /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
RUN apt-get update && apt-get install -y git-core
RUN apt-get update && apt-get install -y vim
RUN apt-get update && apt-get install -y make unrar-free autoconf automake libtool gcc g++ gperf flex bison texinfo gawk ncurses-dev libexpat-dev python3 python sed git wget bzip2 unzip python-serial
RUN echo 'root:docker'|chpasswd && useradd -ms /bin/bash user && echo 'user:user'|chpasswd && echo 'umask 000' >>/home/user/.profile
RUN if [ -f /etc/sudoers ]; then echo "user ALL=NOPASSWD: ALL" >> /etc/sudoers; fi
USER user
ENV HOME /home/user
WORKDIR /home/user
USER root
RUN chown user /opt
RUN usermod -a -G dialout user
USER user
RUN /bin/echo -e \
'cd /opt\n' \
'git clone https://github.com/pfalcon/esp-open-sdk.git --depth=1\n' \
'cd esp-open-sdk\n' \
'sed -i '"'"'s/configure --prefix.*/& --without-libtool/'"'"' Makefile\n' \
'sed -i '"'"'/^all/s/sdk sdk_patch //'"'"' Makefile\n' \
'make\n' \
'echo '"'"'export PATH=/opt/esp-open-sdk/xtensa-lx106-elf/bin:$PATH'"'"' >>~/.profile\n' \
| /bin/bash -l
RUN /bin/echo -e \
'cd /opt\n' \
'git clone https://github.com/nodemcu/nodemcu-firmware.git --depth=1\n' \
'cd node*\n' \
'make\n' \
| /bin/bash -l
# INLINE
# cd /opt
# git clone https://github.com/micropython/micropython.git --depth 1
# cd micropython/esp8266
# make
# ---
# CLEANUP - for squashing
# USER root
# RUN rm -rf /opt/esp-open-sdk/crosstool-NG
# RUN apt-get clean
# USER user
CMD ["/bin/bash", "-l" ]
