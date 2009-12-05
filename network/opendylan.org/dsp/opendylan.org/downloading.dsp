<%dsp:taglib name="od"/>

<od:standard-header>Downloading Software</od:standard-header>

<h3>Contents</h3>
<ol>
<li><a href="#od">Open Dylan</a></li>
<li><a href="#gd">Gwydion Dylan</a></li>
<li><a href="#svn">Subversion Repository</a></li>
<li><a href="/downloads/">Browse Download Directory</a></li>
</ol>

<a name="od"></a>
<h2>Open Dylan</h2>

<p>
The current version of Open Dylan is <em>1.0beta5</em> for x86/Linux and
amd64/FreeBSD and <em>1.0beta4</em> for other platforms.  We're seeking
packagers for 1.0beta5 on other Unix platforms.  (There is a problem building
beta5 for Windows that needs research.)  The Open Dylan downloads include
source and binaries.
</p>

<blockquote>
  <a href="/downloads/opendylan/1.0beta5/">[download 1.0beta5]</a>
  <br><a href="/downloads/opendylan/1.0beta4/">[download 1.0beta4]</a>
</blockquote>

<h3>Open Dylan on Linux and FreeBSD</h3>

<p> The README file inside the tarball describes installation and
basic usage.  The easiest way is extracting the tarball in /usr/local.
The Linux platform should have binutils installed, in order to allow
linking.  Note that the Linux version has only a command-line compiler
and no IDE.
</p>

<h3>Open Dylan on Windows</h3>

<p>For installation, double-click on the installer, and follow instructions.
You need to have either the PellesC linker or the linker of VC++ 6.0, 7.0 or
the current .NET platform SDK installed.
</p>


<a name="gd"></a>
<h2>Gwydion Dylan</h2>

<P><EM>Gwydion Dylan <?php current_version();?></EM> is the current release
version of Gwydion Dylan. It still has some rough edges in terms of usability,
but code generation is extremely stable, and we consider the compiler to be of
production quality.  <a href="/downloads/binaries/">[download]</a></P>

<h3>Dependencies</h3>

<p>Gwydion Dylan uses a number of other tools which you will need to
obtain if your system doesn't already have them.  Mindy compiler and
interpreter binaries are stand-alone, but to use d2c to develop Dylan
programs you will of course require a C compiler, linker,
<code>make</code> and so forth.  Most platforms also require GNU
libtool, and we supply some utility scripts that use Perl.

<p>Using the d2c compiler to build compiled Dylan programs requires
the <a
href="http://www.hpl.hp.com/personal/Hans_Boehm/gc">Boehm-Demers-Weiser
conservative garbage collector</a>.  (Gwydion versions 2.3.9 and
earlier come with the GC library included, but starting from 2.3.10
and later we have decided for a number of reasons that it is better
for the user (or OS vendor) to supply the GC library.)</p>

<h3>Available Packages</h3>

<P>To use the d2c compiler, you'll normally want to download
precompiled binaries for your platform (d2c is written in
Dylan). Binary tarballs are available for a number of different
platforms in the <a href="/downloads/binaries/">binaries</a> directory
on the download server.</P>

<P>Please refer to <a href="http://wiki.opendylan.org/wiki/view.dsp?title=Installing%20Gwydion%20Dylan%20on%20Ubuntu">this tutorial</a> in order to install the
debian package in Ubuntu.</P>

<P>For unixoid systems such as Linux, those are meant to be extracted
in <tt>/usr/local</tt>.  This means that you extract them via commands
such as:
<pre>
# cd /usr/local
# tar zxf ~/gwydion-dylan-<?php current_version();?>-x86-linux.tar.gz
</pre>

<p>If you cannot put them there (for example, because you do not have
admin access), read the installation instructions in the source
tarball.</p>

<p>The source tree can be downloaded <a
href="/downloads/src/tar/gwydion-dylan-<?php current_version();?>.tar.gz">here</a>. Be warned that it will
bootstrap the compiler with an interpreter unless a pre-existing
binary of d2c is found. This may take some hours, but is the most
convenient route. Of course, you can also use this if you already have
an older version of d2c on your platform.</p>

<H4>Debian</H4>

<p>Gwydion Dylan is part of the standard distribution of woody and
sid. Just type:</p>
<pre>
# apt-get install gwydion-dylan-dev
</pre>

<H4>Fink</H4>

Gwydion Dylan is part of the
<A HREF="http://fink.sf.net/">Fink distribution</A>
for Darwin and MacOS X.
Just type <tt>apt-get install gwydion-dylan</tt>.

<H4>FreeBSD</H4>

Gwydion Dylan is available as the <tt>lang/dylan</tt> port in FreeBSD.

<H4>Microsoft Windows</H4>
There are no pre-built native binaries available, but Cygwin builds are
in the download archive.  In addition, Gwydion Dylan can be compiled 
with Microsoft Visual C++, or alternatively with gcc under Cygwin. Cygwin
build directions are <A HREF="building-win32-cygwin">here</A>.


<a name="svn"></a>
<H2>Subversion Source Repository</H2>

<P><A HREF="cgi-bin/viewcvs.cgi">Browse our Subversion source tree.</A> You can
also access the Subversion server directly, by checking out subdirectories of
<tt>svn://anonsvn.gwydiondylan.org/scm/svn/dylan</tt>.
</p>

<dl>
<dt>Gwydion Dylan trunk</dt>
<dd><tt>svn://anonsvn.gwydiondylan.org/scm/svn/dylan/trunk/gwydion</tt></dd>
<dt>Gwydion Dylan 2.4 branch (latest stable version)</dt>
<dd><tt>svn://anonsvn.gwydiondylan.org/scm/svn/dylan/branches/GD_2_4/gwydion</tt></dd>
<dt>Open Dylan trunk</dt>
<dd><tt>svn://anonsvn.gwydiondylan.org/scm/svn/dylan/trunk/fundev</tt></dd>
</dl>

<p>We generally recommend that people start from the most recent tagged version
under

<pre>
svn://anonsvn.gwydiondylan.org/scm/svn/dylan/tags
</pre>

which is currently <?php current_version();?>.  If that works for
you (or you're the type that doesn't read manuals before turning on
your new VCR) then you can try the stable branch or even the trunk
version.  We actually try pretty hard to make sure the trunk version
always works, but there are certainly even fewer guarantees with it
than usual.</p>

<p>Instructions on Subversion use for developers can be found <a
href="repository">here</a>.</p>

<od:standard-footer/>
