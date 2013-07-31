# Sources for drbd

module_DATA = \
  modules/Drbd.rb

client_DATA = \
  clients/drbd.rb

yncludedir = @yncludedir@/drbd
ynclude_DATA = \
  include/drbd/resource_conf.rb \
  include/drbd/wizards.rb \
  include/drbd/global_conf.rb \
  include/drbd/startup_conf.rb \
  include/drbd/common.rb \
  include/drbd/dialogs.rb \
  include/drbd/complex.rb \
  include/drbd/helps.rb

scrconf_DATA = \
  scrconf/drbd.scr

desktop_DATA = \
  desktop/drbd.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common