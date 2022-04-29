#!/bin/sh

# Override user ID lookup to cope with being randomly assigned IDs using
# the -u option to 'docker run'.

# reference:
# http://blog.dscpl.com.au/2015/12/unknown-user-when-running-docker.html

USER_ID=$(id -u)
GROUP_ID=$(id -g)

# set the new passwd and group files
export NSS_WRAPPER_PASSWD=/tmp/passwd.nss_wrapper
export NSS_WRAPPER_GROUP=/tmp/group.nss_wrapper
export LD_PRELOAD=/usr/lib/libnss_wrapper.so

cp /etc/passwd ${NSS_WRAPPER_PASSWD}
cp /etc/group ${NSS_WRAPPER_GROUP}

if [ x"$USER_ID" != x"0" -a x"$USER_ID" != x"1000" ]; then
    # overwrite the old uid and gid for the user
    sed -i -e "s/^user:x:1000:1000:/user:x:$USER_ID:$GROUP_ID:/" $NSS_WRAPPER_PASSWD
    sed -i -e "s/^user:x:1000:/user:x:$GROUP_ID:/" $NSS_WRAPPER_GROUP
fi

if [ -e /var/run/docker.sock ] ; then
    # allow users in the docker container to access /var/run/docker.sock
    sudo chmod 666 /var/run/docker.sock
fi

# add mitmproxy certificate to the system trusted certs
if [ x"$MITMPROXY_CERT" != x"" -a -r $MITMPROXY_CERT ]; then
    sudo cp $MITMPROXY_CERT /usr/local/share/ca-certificates/mitmproxy.crt
    sudo update-ca-certificates
fi

# run the user's command
exec "$@"
