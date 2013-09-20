#
# spec file for package yast2-drbd
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
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
Version:        3.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

License:        GPL v2 or later
Group:          System/YaST
BuildRequires:  perl-XML-Writer ruby rubygem-racc update-desktop-files yast2 yast2-devtools yast2-testsuite
BuildRequires:  yast2-devtools >= 3.0.6
Requires:       yast2 
BuildArch:      noarch
Requires:       yast2-ruby-bindings >= 1.0.0

Summary:        YaST2 - DRBD Configuration

%description
YaST2 - Configuration of Distributed Replicated Block Devices. With
this module you can configure a distributed storage system, frequently
used on high availability (HA) clusters.


Authors:
--------
    cmeng@novell.com

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%{yast_yncludedir}/drbd/
%{yast_clientdir}/drbd.rb
%{yast_moduledir}/Drbd.*
%{yast_desktopdir}/drbd.desktop
%{yast_scrconfdir}/*.scr
%{yast_agentdir}/ag_drbd
%doc %{yast_docdir}

