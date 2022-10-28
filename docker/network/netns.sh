#!/bin/bash
#####
# References:
#   - https://www.baeldung.com/linux/docker-network-namespace-invisible
#	- https://www.baeldung.com/linux/mount-unmount-filesystems
#	- https://www.linuxadictos.com/en/iptables-table-types.html
#####

ID=$(docker container run -itd alpine:3.16)

sleep 2s
docker container exec -it ${ID} /bin/sh -c "echo hello world > new_file"

pid=$(docker container inspect ${ID} --format='{{.State.Pid}}')
# Here we have the cgroup, ipc, mnt, net, pid, pid_for_children, user, uts
ls -al /proc/${pid}/ns

# We can't visualize the network namespace created by docker because it didn't reference the directory inside /proc/${pid}/ns/net
ls -al /var/run/netns

# Solving the issue
touch /var/run/netns/${ID}
mount -o bind /proc/${pid}/ns/net /var/run/netns/${ID}

ip netns ls
ip netns exec ${ID} ip address list
ip address list

# Clean-up of the network namespace bind that we have created.
umount /var/run/netns/${ID}
rm /var/run/netns/${ID}

## Docker uses CNM (Container Networking Model)
# CNM uses sandbox, endpoint, network concepts.
# A sandbox is a single unit having all networking components associated with a single container.
# If the sandbox wants to communicate to the network, it needs endpoints.
# A sandbox can have more than one endpoint; however, each endpoint can only connect to one network.
#
# There are two types of network drivers in Docker networking:
#	- Native network driver (Host, Bridge, Overlay, MACVLAN, None network driver)
#	- Remote Network Driver
#
# Host network driver doesn't need a netns because it uses host resources, so we can't expose more than one container on the same port and we don't have sanboxes, neither endpoints.
# Bridge network driver: eth0 -> Veth -> docker0 -> eth0 (host)

ls -al /var/run/docker/netns

netns=$(docker container inspect ${ID} --format='{{.SandboxKey}}')
echo "This is the path ${netns} for the container with ID ${ID}"

# This script doesn't make a lot of sense, but I was playing around with templates and container spec to familiarize with it.
while read x; do
	network_name=${x%% *}
	network_id=${x##* }
	echo "network stuff ${network_name} and ${network_id}"
	if [[ "$(docker network inspect ${network_name} --format='{{.ID}}')" == "${network_id}" ]]; then
		echo "Network ID in container spec is the same as network ID in network spec"
	fi
done < <(docker container inspect ${ID} --format='{{ range $key, $val := .NetworkSettings.Networks }} {{ $key }} {{ $val.NetworkID }} {{ end }}')

### Docker configuration
# Docker needs the property net.ipv4.ip_forward to be activated
cat /proc/sys/net/ipv4/ip_forward
sysctl net.ipv4.ip_forward

# If we configure the dockerd (docker daemon) with --ip-forward=false, we don't need ip_forward to be activated.

ID=$(docker container run --detach --publish-all nginx:stable-alpine)

# /usr/bin/docker-proxy handles the chain 'DOCKER' (iptables -L DOCKER)
# When dockerd --userland-proxy is enabled, then we are using docker-proxy to handle these connections
# If we disable that option, then we are using localhost to connect to containers.
cat /proc/sys/net/ipv4/conf/docker0/route_localnet
sysctl net.ipv4.conf.docker0.route_localnet

# /usr/bin/docker-proxy -proto <protocol> -host-ip <HostIp> -host-port <HostPort> -container-ip <ContainerIp> -container-port <ContainerPort>
while read line; do
	cInfo=${line%-*}
	hInfo=${line#*-}
	
	cProto=${cInfo#*/}
	cIp=${cInfo%:*}
	cPort=$(echo $cInfo | sed 's/.*:\(.*\)\/.*/\1/g')
	
	hIp=${hInfo%:*}
	hPort=${hInfo##*:}
	
	echo "/usr/bin/docker-proxy -proto ${cProto} -host-ip ${hIp} -host-port ${hPort} -container-ip ${cIp} -container-port ${cPort} => ${line}"
done < <(docker container inspect ${ID} --format='
	{{- $containerPort := .NetworkSettings.IPAddress -}}
	{{- range $key, $val := .NetworkSettings.Ports -}}
		{{- range $each := $val -}}
			{{ $containerPort }}:{{ $key }}-{{ $each.HostIp }}:{{ $each.HostPort }}
		{{ end -}}
	{{- end -}}' | grep -v '^\s*$')
