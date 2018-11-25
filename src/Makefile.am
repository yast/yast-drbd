# Sources for drbd

SUBDIRS = servers_non_y2

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
  include/drbd/lvm_conf.rb \
  include/drbd/wizards.rb

scrconf_DATA = \
  scrconf/drbd.scr \
  scrconf/drbd_lvm.scr

desktop_DATA = \
  desktop/drbd.desktop

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-drbd-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-drbd.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
