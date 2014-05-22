# Sources for drbd

module_DATA = \
  modules/Drbd.rb

client_DATA = \
  clients/drbd_auto.rb \
  clients/drbd.rb \
  clients/drbd_proposal.rb

yncludedir = @yncludedir@/drbd
ynclude_DATA = \
  include/drbd/dialogs.rb \
  include/drbd/common.rb \
  include/drbd/complex.rb \
  include/drbd/startup_conf.rb \
  include/drbd/resource_conf.rb \
  include/drbd/helps.rb \
  include/drbd/global_conf.rb \
  include/drbd/wizards.rb

scrconf_DATA = \
  scrconf/drbd.scr

desktop_DATA = \
  desktop/drbd.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
