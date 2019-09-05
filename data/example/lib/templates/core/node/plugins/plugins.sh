#!/bin/bash

# Install Flight Manage
#yum -y install flight-manage

# Create scripts directory
#NODEDIR=/opt/service/nodescripts/<%= node.name %>scripts
#mkdir -p $NODEDIR
#mkdir -p /opt/service/flight/managedata

# Download scripts
curl <%= config.renderedurl %>/core/plugins/nfs.bash | /bin/bash -x
curl <%= config.renderedurl %>/core/plugins/flightenv.bash | /bin/bash -x
curl <%= config.renderedurl %>/core/plugins/slurm.bash | /bin/bash -x

# Set executable
#chmod +x -R $NODEDIR/*.bash
