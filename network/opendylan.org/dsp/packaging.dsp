<%dsp:taglib name="od"/>

<od:standard-header>Packages</od:standard-header>

<P>We're trying to build easy-to-install packages for as many operating
systems and architectures as we can. We want people to get up to speed with
Gwydion Dylan as quickly as possible.</P>

<?php
begin_progress_table();
progress("FreeBSD x86", 7);
progress("Linux x86 libc5 tgz", 10);
progress("Linux x86 libc6 tgz", 10);
progress("Linux x86 libc5 RPM", 10);
progress("Linux x86 libc6 RPM", 10);
progress("Linux PowerPC libc6 RPM", 10);
progress("Linux x86 libc6 deb", 10);
progress("Linux SPARC libc6 deb", 10);
progress("MacOS X/Darwin tgz", 10);
progress("MacOS X/Darwin package", 2);
progress("Solaris SPARC tgz", 10);
end_progress_table();
?>

<P>The libc6 packages are used by RedHat 5.1 and Debian 3.0. Older RedHat
and Debian versions and all other Linux distributions use the libc5
packages.</P>

<P>We'd like to add other operating systems to this list, but we <A
HREF="ports">need ports</A> to those platforms first.</P>

<od:standard-footer/>
