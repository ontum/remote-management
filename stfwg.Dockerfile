# As a workaround we have to build on nodejs 18
# nodejs 20 hangs on build with armv6/armv7
# FROM docker.io/library/node:18-alpine AS build_node_modules

# #FailureMessage Object: 0x7e87753c
# #
# # Fatal error in , line 0
# # unreachable code
# #
# #
# #

FROM sitespeedio/node:ubuntu-20.04-nodejs-16.16.0@sha256:4d3306ada49b5b49968eb2e65ef315332c0ef14f7f13ec531080d9d7c3ea9a31 AS build_node_modules

# Copy Web UI
COPY src /app
WORKDIR /app
RUN npm ci --omit=dev &&\
    mv node_modules /node_modules

# Copy build result to a new image.
# This saves a lot of disk space.
FROM  sitespeedio/node:ubuntu-20.04-nodejs-16.16.0@sha256:4d3306ada49b5b49968eb2e65ef315332c0ef14f7f13ec531080d9d7c3ea9a31
COPY --from=build_node_modules /app /app

# Move node_modules one directory up, so during development
# we don't have to mount it in a volume.
# This results in much faster reloading!
#
# Also, some node_modules might be native, and
# the architecture & OS of your development machine might differ
# than what runs inside of docker.
COPY --from=build_node_modules /node_modules /node_modules

ENV TZ=Asia/Kolkata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone &&  apt-get update && apt-get install -yy iproute2 openresolv openssh-server \
   wireguard wireguard-tools curl wget adb \
  dumb-init iptables iputils-ping

# Use iptables-legacy
RUN update-alternatives --install /sbin/iptables iptables /sbin/iptables-legacy 10 --slave /sbin/iptables-restore iptables-restore /sbin/iptables-legacy-restore --slave /sbin/iptables-save iptables-save /sbin/iptables-legacy-save

# Expose Ports (If needed on buildtime)
#EXPOSE 51820/udp
#EXPOSE 51821/tcp

# Set Environment
ENV DEBUG=Server,WireGuard

# Run Web UI
WORKDIR /app
CMD ["/usr/bin/dumb-init", "node", "server.js"]
