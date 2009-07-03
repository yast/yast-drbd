#
# spec file for package yast2-drbd (Version 2.13.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
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

# norootforbuild


Name:           yast2-drbd
Url:            http://en.opensuse.org/YaST
Version:        2.15.0
Release:        214
License:        GPL v2 or later
Group:          System/YaST
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        yast2-drbd-%{version}.tar.bz2
Prefix:         /usr
BuildRequires:  perl-XML-Writer ruby ruby-racc update-desktop-files yast2 yast2-devtools yast2-testsuite
Requires:       yast2 
BuildArch:      noarch
Summary:        YaST2 - DRBD Configuration

%description
YaST2 - Configuration of Distributed Replicated Block Devices. With
this module you can configure a distributed storage system, frequently
used on high availability (HA) clusters.



Authors:
--------
    cmeng@novell.com

%prep
%setup -n yast2-drbd-%{version}

%build
%{prefix}/bin/y2tool y2autoconf
%{prefix}/bin/y2tool y2automake
autoreconf --force --install
export CFLAGS="$RPM_OPT_FLAGS -DNDEBUG"
export CXXFLAGS="$RPM_OPT_FLAGS -DNDEBUG"
%{?suse_update_config:%{suse_update_config -f}}
./configure --libdir=%{_libdir} --prefix=%{prefix} --mandir=%{_mandir}
make %{?jobs:-j%jobs}

%install
make install DESTDIR="$RPM_BUILD_ROOT"
pushd $RPM_BUILD_ROOT
rm -f $RPM_BUILD_ROOT/%{prefix}/lib/YaST2/servers_non_y2/drbd.rb.yy
rm -f $RPM_BUILD_ROOT/%{prefix}/share/YaST2/clients/drbd_auto.ycp
rm -f $RPM_BUILD_ROOT/%{prefix}/share/YaST2/clients/drbd_proposal.ycp
popd
[ -e "%{prefix}/share/YaST2/data/devtools/NO_MAKE_CHECK" ] || Y2DIR="$RPM_BUILD_ROOT/usr/share/YaST2" make check DESTDIR="$RPM_BUILD_ROOT"
for f in `find $RPM_BUILD_ROOT/%{prefix}/share/applications/YaST2/ -name "*.desktop"` ; do
    d=${f##*/}
    %suse_update_desktop_file -d ycc_${d%.desktop} ${d%.desktop}
done

%clean
rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(-,root,root)
%dir /usr/share/YaST2/include/drbd
/usr/share/YaST2/include/drbd/*
/usr/share/YaST2/clients/drbd.ycp
# /usr/share/YaST2/clients/heartbeat_*.ycp
/usr/share/YaST2/modules/Drbd.*
%{prefix}/share/applications/YaST2/drbd.desktop
/usr/share/YaST2/scrconf/*.scr
%{prefix}/lib/YaST2/servers_non_y2/ag_drbd
%doc %{prefix}/share/doc/packages/yast2-drbd

%changelog
* Thu Oct 02 2008 xwhu@suse.de
- Replace ReplaceNextButton with SetNextButton (bnc#429021)
* Wed Jul 16 2008 xwhu@suse.de
- pae was not recognized as a kernel arch (bnc#380074)
* Mon Apr 07 2008 xwhu@suse.de
- bugzilla 291490: typo in resource_conf.ycp
* Mon Jul 30 2007 cmeng@novell.com
- fix bug-295546: resource config get deleted
- refix bug-291766: check also iseries64 and ppc64
* Mon Jul 23 2007 cmeng@novell.com
- fix bug-291766: yast-drbd doesn't install drbd-kmp-<arch> pack
- fix bug-291778: yast-drbd recreate drbd.conf while it doesn't exist
- fix bug-291785: set the default val of protocol even 'advance page' not be accesed
- fix bug-291771: refine some error messages and logs
* Mon Jun 18 2007 xwhu@novell.com
- Change the instruction message about propagating configuration
- Reuse yast-iscsi-client.png
* Thu Apr 26 2007 xwhu@novell.com
- update to version 2.13.1
* Tue Apr 24 2007 xwhu@novell.com
- initial version 2.13.0
