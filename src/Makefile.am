# Makefile.am for drbd/src

yncludedir = @yncludedir@/drbd

client_DATA =			\
	drbd.ycp

ynclude_DATA =	       \
	helps.ycp		   \
	common.ycp		   \
	wizards.ycp		   \
	dialogs.ycp		   \
	complex.ycp		   \
	global_conf.ycp	   \
	startup_conf.ycp   \
	resource_conf.ycp


desktop_DATA =			\
	drbd.desktop

module_DATA =			\
	Drbd.ycp		

# create a symlink for local build, #145327
drbd:
	ln -sf . $@
ycpchook = drbd

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
