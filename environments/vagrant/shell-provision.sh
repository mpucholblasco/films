#!/bin/bash

# Shell provision used to configure Vagrant box with films installed on it.

PUPPET_VERSION=3.7.3-1puppetlabs1

###
# FUNCTIONS
###

function install_puppet {
	local RETRIES=$1
cat << EOF > /etc/apt/sources.list.d/puppetlabs.list
deb http://apt.puppetlabs.com precise main
deb-src http://apt.puppetlabs.com precise main
deb http://apt.puppetlabs.com precise dependencies
deb-src http://apt.puppetlabs.com precise dependencies
EOF
        for ((C=$RETRIES; C>0; C--)); do
                wget --quiet --tries=3 -O - https://apt.puppetlabs.com/pubkey.gpg | apt-key add -
                wget --quiet --tries=3 -O - http://ntq.ubuntu.private.s3-website-us-east-1.amazonaws.com/public.gpg.key | apt-key add -
                apt-get update
                /usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install puppet=$PUPPET_VERSION puppet-common=$PUPPET_VERSION
                if [ $? -eq 0 ]; then
                        return 0
                fi
                sleep 5
        done
}

###
# MAIN
###

install_puppet 5

# Install puppet modules
puppet module install puppetlabs-apt
puppet module install puppetlabs-vcsrepo
puppet module install puppetlabs-mysql
puppet module install puppetlabs-apache

puppet apply --templatedir=/vagrant/templates/ /vagrant/films.pp
