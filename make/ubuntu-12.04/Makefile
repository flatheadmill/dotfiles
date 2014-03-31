#copy_targets = /etc/exim4/passwd.client /etc/aliases

#copy_sources = $(copy_targets:/%:%)

DIR = ${CURDIR}

HAPROXY = haproxy-1.5-dev21
NODE = node-v0.10.26

NODE_VERSION = $(NODE:node-v%=%)
HAPROXY_VERSION = $(filter-out dev%,$(subst -, ,$(HAPROXY:haproxy-%=%)))

ifndef SUDO_USER
$(error "must run via sudo")
endif

template_targets = /etc/exim4/passwd.client /etc/aliases /etc/ssh/sshd_config
template_sources = $(template_targets:/%:%.sh)

deploy: $(template_targets) \
	/etc/exim4/update-exim4.conf.conf \
	/usr/local/bin/node

#$(copy_targets): /%: %
#	cp $< $@
#	chown -R ubuntu:ubuntu /home/ubuntu
#	chown -R $(user):$(user) /home/$(user)

$(template_targets): /%: %.sh
	bash "$(DIR)/replace" $< > $@
	touch $@

# Build a Node.js.
/usr/local/bin/node: ~/src/node-v$(NODE_VERSION)/config.mk
	make -C ~/src/node-v$(NODE_VERSION) install

~/src/node-v$(NODE_VERSION)/config.mk: ~/src/node-v$(NODE_VERSION).tar.gz
	(cd ~/src && tar zxvf node-v$(NODE_VERSION).tar.gz)
	(cd ~/src/node-v$(NODE_VERSION) && ./configure)

~/src/node-v$(NODE_VERSION).tar.gz:
	mkdir -p /home/$(SUDO_USER)/src
	curl http://nodejs.org/dist/v$(NODE_VERSION)/node-v$(NODE_VERSION).tar.gz > /home/$(SUDO_USER)/src/node-v$(NODE_VERSION).tar.gz.tmp
	[ `sha1sum /home/$(SUDO_USER)/src/node-v$(NODE_VERSION).tar.gz.tmp | cut -f1 -d' '` = "2340ec2dce1794f1ca1c685b56840dd515a271b2" ] && mv /home/$(SUDO_USER)/src/node-v$(NODE_VERSION).tar.gz.tmp $@
	touch $@

# Configure EXIM4 for reporting.
/etc/exim4/update-exim4.conf.conf: etc/exim4/update-exim4.conf.conf.sh \
		/etc/exim4/passwd.client /etc/aliases
	bash "$(DIR)/replace" $< > $@
	touch $@
	update-exim4.conf
	invoke-rc.d exim4 restart

# Build an HAProxy.
/usr/local/bin/haproxy: /home/$(SUDO_USER)/src/$(HAPROXY)/haproxy
	cp $< $@

/home/$(SUDO_USER)/src/$(HAPROXY)/haproxy: /home/$(SUDO_USER)/src/$(HAPROXY)/README
	(cd $(<D) && make TARGET=linux2628 USE_OPENSSL=1)
	chown -R $(SUDO_USER):$(SUDO_USER) $(<D)

/home/$(SUDO_USER)/src/$(HAPROXY)/README: /home/$(SUDO_USER)/src/$(HAPROXY).tar.gz
	(cd /home/$(SUDO_USER)/src && tar zxvf $<)
	chown -R $(SUDO_USER):$(SUDO_USER) /home/$(SUDO_USER)/src
	touch $@

/home/$(SUDO_USER)/src/$(HAPROXY).tar.gz:
	mkdir -p $(@D)
	curl http://haproxy.1wt.eu/download/$(HAPROXY_VERSION)/src/devel/$(HAPROXY).tar.gz > $@
	chown -R $(SUDO_USER):$(SUDO_USER) $(@D)
