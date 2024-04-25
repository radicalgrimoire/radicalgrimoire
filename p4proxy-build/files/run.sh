#!/bin/bash

p4 trust -y -f

cat > ~perforce/.p4config <<EOF
P4USER=$P4USER
P4PORT=$P4PORT
P4PASSWD=$P4PASSWD
EOF

yes ${P4PASSWD} | p4 -p ${P4PORT} -u super login

pushd /opt/perforce
p4 trust -y -f
popd

sudo -E -u perforce p4p -d -S -p ${PORT} -t ${P4PORT} -r ${P4PCACHE} -L ${P4PLOGFILE} -v 3