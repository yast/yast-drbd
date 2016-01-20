# Makefile.am for drbd/agents

agent_SCRIPTS = \
	ag_drbd drbd.rb.yy

#Comment due to buildrequires :rubygem-racc 
# In openSUSE 11.3 it used racc-1.4.5
# is neccary in yast ci(github)a but invalid in ibs
# Remember #!/usr/bin/ruby is necessary,
# need to add manually
#
#ag_drbd: drbd.rb.yy
#	rm -f drbd.rb
#	racc -e "/usr/bin/ruby" -v -g drbd.rb.yy -o ag_drbd
#	chmod ugo+x ag_drbd

EXTRA_DIST = $(agent_SCRIPTS)
