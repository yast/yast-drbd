# Makefile.am for drbd/agents

agent_SCRIPTS = \
	ag_drbd drbd.rb.yy

#Comment due to buildrequires :rubygem-racc 
# is neccary in yast ci(github)a but invalid in ibs
#
#ag_drbd: drbd.rb.yy
#	rm -f drbd.rb
#	racc -e "/usr/bin/ruby" -v -g drbd.rb.yy -o ag_drbd
#	chmod ugo+x ag_drbd

EXTRA_DIST = $(agent_SCRIPTS)
