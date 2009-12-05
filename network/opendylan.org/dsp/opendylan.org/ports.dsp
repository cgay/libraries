<%dsp:taglib name="od"/>

<od:standard-header>Ports</od:standard-header>

<h3>Open Dylan</h3>

<p>The Open Dylan command-line compiler is supported on Windows XP, Linux,
FreeBSD, and Mac OS X.  However, Windows XP is the only platform on which there is
GUI support (e.g., the IDE) and full debugging support.  GUI support on
non-Windows platforms needs a gtk+ backend for DUIM.  Debugging support on
non-Windows platforms needs a debugger nub.  Until then debugging on
non-Windows platforms is accomplished with gdb and/or printf.</p>

<h3>Gwydion Dylan</h3>

<p>Currently supported platforms are</p>

<ul>
  <li>Linux (x86, PowerPC), with packages as tarballs, RPMs and DEBs
  <li>FreeBSD (it's in the ports)
  <li>Solaris
  <li>Mac OS X/Darwin
  <li>Windows with Cygwin/gcc
  <li>HP-UX
</ul>

<p>The most popular and actively-supported ports are those to Linux and the
BSD's (including Mac OS X/Darwin). Unfortunately, several previously supported
platforms have been neglected due to none of the current volunteers using
them. If you're interested in one of these platforms the position of
maintainer is open and it's probably not a big deal to update them to the
latest and greatest:</p>

<ul>
  <li>Windows with Visual C++
  <li>OpenBSD
  <li>Mac OS X
  <li>BeOS
</ul>

<p>If there is no binary for the current version of Gwydion Dylan for your
platform, get an older binary and compile the sources. Alternatively, if
you've got a lot of time on your hands you can use our &quot;Mindy&quot;
Dylan interpreter for bootstrapping&mdash;this takes several hours on a 700
MHz Athlon and up to several days on early model Pentiums and PowerPCs.</p>

<p>Please announce your efforts on our hackers mailing list, let us know
of any problems you have (we may have seen them before). When you're done,
let us know as well, so we can put your binary on the server.</p>

<od:standard-footer/>
