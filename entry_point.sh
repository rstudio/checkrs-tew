#!/bin/sh

# Override user ID lookup to cope with being randomly assigned IDs using
# the -u option to 'docker run'.

# reference:
# http://blog.dscpl.com.au/2015/12/unknown-user-when-running-docker.html

USER_ID=$(id -u)
GROUP_ID=$(id -g)

if [ x"$USER_ID" != x"0" -a x"$USER_ID" != x"1000" ]; then

    # set the new passwd and group files
    NSS_WRAPPER_PASSWD=/tmp/passwd.nss_wrapper
    NSS_WRAPPER_GROUP=/tmp/group.nss_wrapper

    # overwrite the old uid and gid for the user
    cat /etc/passwd | sed -e "s/^docker:x:1000:1000:/docker:x:$USER_ID:$GROUP_ID:/" > $NSS_WRAPPER_PASSWD
    cat /etc/group | sed -e "s/^docker:x:1000:/docker:x:$GROUP_ID:/" > $NSS_WRAPPER_GROUP

    export NSS_WRAPPER_PASSWD
    export NSS_WRAPPER_GROUP

    LD_PRELOAD=/usr/lib/libnss_wrapper.so
    export LD_PRELOAD
fi

# run the user's command
exec "$@"
