#
# spec file for package yast2-drbd
#
# Copyright (c) 2018 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-drbd
Version:        4.0.3
Release:        0

%define _fwdefdir %{_libexecdir}/firewalld/services
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2
Source1:        drbd.firewalld.xml

BuildRequires:  perl-XML-Writer
BuildRequires:  ruby
BuildRequires:  update-desktop-files
# SuSEFirewall2 replaced by Firewalld(fate#323460)
BuildRequires:  yast2 >= 4.0.39
BuildRequires:  yast2-devtools >= 3.1.10
BuildRequires:  yast2-testsuite
BuildRequires:  firewall-macros
# SuSEFirewall2 replaced by Firewalld(fate#323460)
Requires:       yast2 >= 4.0.39
Requires:       drbd >= 9.0
BuildArch:      noarch
Requires:       yast2-ruby-bindings >= 1.0.0

Summary:        YaST2 - DRBD Configuration
License:        GPL-2.0-or-later
Group:          System/YaST

%description
YaST2 - Configuration of Distributed Replicated Block Devices. With
this module you can configure a distributed storage system, frequently
used on high availability (HA) clusters.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install

mkdir -p $RPM_BUILD_ROOT/%{_fwdefdir}
install -m 644 %{S:1} $RPM_BUILD_ROOT/%{_fwdefdir}/drbd.xml

%post
%firewalld_reload

%files
%defattr(-,root,root)
%{yast_yncludedir}/drbd/
%{yast_clientdir}/drbd.rb
%{yast_clientdir}/drbd_*.rb
%{yast_moduledir}/Drbd.*
%{yast_desktopdir}/drbd.desktop
%{yast_scrconfdir}/*.scr
%{yast_agentdir}/ag_drbd
%{yast_agentdir}/drbd.rb.yy
%doc %{yast_docdir}
%license COPYING
%dir %{_libexecdir}/firewalld
%dir %{_fwdefdir}
%{_fwdefdir}/drbd.xml

%changelog
