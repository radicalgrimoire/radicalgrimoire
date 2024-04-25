#!/bin/bash

sudo -E -u perforce p4d -Gc
sudo -E -u perforce p4d -Gf
sudo -E -u perforce p4 trust -y
sudo -E -u perforce p4p -d -p ${PORT} -t ${P4PORT} -r ${P4PCACHE} -L ${P4PLOGFILE} -v 3