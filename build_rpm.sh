#!/bin/bash

VERSION=1.0
RELEASE=1

if [ "$1" == "clean" ]; then
  rm ${HOME}/rpmbuild/SOURCES/catmandu-meercat-${VERSION}.tar.gz
  rm catmandu-meercat-${VERSION}-${RELEASE}.noarch.rpm 
  rm -rf ${HOME}/rpmbuild/BUILD/catmandu-meercat
  exit 0
fi

rm ${HOME}/rpmbuild/SOURCES/catmandu-meercat-${VERSION}.tar.gz

tar cvf ${HOME}/rpmbuild/SOURCES/catmandu-meercat-${VERSION}.tar.gz  --gzip \
	--exclude='*.rpm' \
	--exclude='.git' \
	--exclude='.gitignore' \
	--exclude='data' \
	--exclude='exampledocs' \
	-C .. catmandu-meercat

cat | rpmbuild -v -bb /dev/stdin <<EOF
%define __jar_repack %{nil}

Name:           catmandu-meercat
Version:        ${VERSION}
Release:        ${RELEASE}
Summary:       	Meercat Indexer
Packager:	Patrick Hochstenbach <patrick.hochstenbach@ugent.be>
Distribution:   Meercat
License:	Perl Artistic 2.0
BuildArch:      noarch
Prefix: 	/opt
Source:		catmandu-meercat-${VERSION}.tar.gz

%description
Meercat Indexer

%prep
%setup -n catmandu-meercat 

%filter_provides_in -P .
%filter_requires_in -P .
%filter_setup

%build

%install
mkdir -p %{buildroot}/etc/init.d
mkdir -p %{buildroot}/etc/sysconfig
mkdir -p %{buildroot}/opt/catmandu-meercat

cp -rf * %{buildroot}/opt/catmandu-meercat
cp bin/meercat %{buildroot}/etc/init.d
cp etc/meercat.sysconfig %{buildroot}/etc/sysconfig/meercat

%post
chkconfig --add meercat
chown -R search:search /opt/catmandu-meercat

%files
/opt/catmandu-meercat
/etc/init.d/meercat
/etc/sysconfig/meercat

%changelog
* Thu Aug 16 2012 Patrick Hochstenbach <patrick.hochstenbach@ugent.be> ${VERSION}
- Initial version
EOF

mv ${HOME}/rpmbuild/RPMS/noarch/catmandu-meercat-${VERSION}-${RELEASE}.noarch.rpm .
