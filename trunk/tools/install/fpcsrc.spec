Name: fpcsrc
Version: LAZVERSION
Release: LAZRELEASE
Copyright: LGPL2
Group: Development/Languages
Source: %{name}-%{version}-%{release}.tgz
Summary: FreePascal sources
Packager: Mattias Gaertner (mattias@freepascal.org)
URL: http://www.freepascal.org/
BuildRoot: %{_tmppath}/fpcsrc-build%{version}

%define fpcsrcdir %{_datadir}/fpcsrc
%define destdir %{buildroot}%{fpcsrcdir}/

%description
The Free Pascal Compiler is a Turbo Pascal 7.0 and Delphi compatible 32bit
Pascal Compiler. It comes with fully TP 7.0 compatible run-time library.
Some extensions are added to the language, like function overloading. Shared
libraries can be linked. Basic Delphi support is already implemented (classes,
exceptions, ansistrings, RTTI). This package contains the sources for the
commandline compiler and utils. Provided units are the runtime library (RTL),
free component library (FCL), gtk, ncurses, zlib, mysql, postgres, ibase
bindings and many more.

%prep

%setup -c

%build

%install
if [ %{buildroot} != "/" ]; then
  rm -rf %{buildroot}
fi
mkdir -p %{destdir}
cp -a fpc/* %{destdir}/
# the palmos libcrt.a archive is making trouble
rm %{destdir}/rtl/palmos/libcrt.a

%clean
if [ %{buildroot} != "/" ]; then
  rm -rf %{buildroot}
fi

%files
%defattr(-,root,root)
%{fpcsrcdir}

%changelog


