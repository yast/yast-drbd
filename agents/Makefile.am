# Makefile.am for drbd/agents

agent_SCRIPTS = \
	ag_drbd

scrconf_DATA = \
	drbd.scr

ag_drbd: drbd.rb.yy
	rm -f drbd.rb
	racc -e "/usr/bin/ruby" -v -g drbd.rb.yy -o ag_drbd
	chmod ugo+x ag_drbd

EXTRA_DIST = $(agent_SCRIPTS) $(scrconf_DATA) drbd.rb.yy
