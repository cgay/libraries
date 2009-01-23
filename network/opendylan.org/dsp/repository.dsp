<%dsp:taglib name="od"/>

<od:standard-header>Repository Access</od:standard-header>

<p>The development source code for Gwydion Dylan, Open Dylan, and
collections of Dylan libraries and example code is
stored in a <a href="http://subversion.tigris.org/">Subversion</a>
repository.  For developers, the base URI of the repository is</p>

<pre>
svn+ssh://username@svn.gwydiondylan.org/scm/svn/dylan
</pre>

<p>For example, to check out <tt>gwydion/</tt> (Gwydion Dylan) from the
trunk, you can execute:</p>

<pre>
$ svn co svn+ssh://jones@svn.gwydiondylan.org/scm/svn/dylan/trunk/gwydion gwydion
</pre>

<p>To check out the fundev-2-1-jam branch of Open Dylan,</p>

<pre>
$ svn co svn+ssh://jones@svn.gwydiondylan.org/scm/svn/dylan/branches/fundev-2-1-jam/fundev fundev
</pre>

<p>You could also check out the entirety of trunk:</p>

<pre>
$ svn co svn+ssh://jones@svn.gwydiondylan.org/scm/svn/dylan/trunk gd
</pre>

<p>For non-developers, the base URI to check out is</p>

<pre>
svn://anonsvn.gwydiondylan.org/scm/svn/dylan
</pre>

<p>as described on the <a href="downloading">downloading page</a>.</p>

<h2>Repository Layout</h2>

<p>The repository layout is more-or-less conventional for Subversion
repositories.  The top level contains three directories:</p>

<dl>
  <dt><tt>trunk/</tt></dt>
  <dd>Latest development versions of all "modules"</dd>


  <dt><tt>tags/</tt></dt>
  <dd>Historic archival versions.  Tagging is done by copying a
  subtree from the trunk or a branch to a directory under tags/.  A
  repository pre-commit hook ensures only new copies, and not
  modifications, are permitted on tags.</dd>

  <dt><tt>branches/</tt></dt>

  <dd>One directory for each active development branch.  Like tags,
  branches are usually created by copying a subtree of the trunk to
  one of the directories under <tt>branches/</tt>.  Branches can be
  renamed if necessary, and it is conventional to delete "dead" or
  obsolete branches (e.g., after they've been merged onto
  <tt>trunk/</tt>)... after all, they're under version control.</dd>
</dl>

<h2>Currently Active Branches</h2>

<p>The currently active <a
href="http://www.opendylan.org/cgi-bin/viewcvs.cgi/branches/">branches</a>
are:</p>

<dl>
  <dt><tt>GD_2_4/</tt></dt>
  <dd>The Gwydion Dylan 2.4.x stable development branch.</dd>

  <dt><tt>gd-2-5-collection-optimization/</tt></dt>
  <dd>See <a href="http://www.opendylan.org/bugs/show_bug.cgi?id=7094">Bug #7094</a></dd>

  <dt><tt>fundev-2-1-gdb-nub</tt></dt>
  <dd>See <a href="http://www.opendylan.org/bugs/show_bug.cgi?id=7032">Bug #7032</a></dd>
</dl>

<h2 id="cvszilla">Using CVSZilla</h2>

<p>We use the <a href="http://www.cvszilla.org/">CVSZilla</a> tool to
track development "threads".  CVSZilla associates each commit to the
repository with a <a
href="http://www.opendylan.org/bugs/">Bugzilla</a> entry, and adds
commit log entries as comments to the associated bug(s).  The CVSZilla
database can also be <a
href="https://www.opendylan.org/cvszilla/query.cgi">searched</a>
in various ways.
</p>

<p>Most development work should be preceded by the <a
href="http://www.openndylan.org/bugs/enter_bug.cgi">filing</a> of a
bug or enhancement requrest in Bugzilla.  Small changes can be vetted
for comment by attaching patches to the bug and bringing it to the
attention of other developers.  (Larger development projects should be
associated with a branch, allowing it to be reviewed before it is
merged back to <tt>trunk/</tt>.</p>

<p>When changes are comitted, the first line of the commit log must be of
the form:</p>

<pre>
Bug: <var>bug-number</var> ...
</pre>

<p>so that CVSZilla can annotate the bug(s).</p>

<p>If a commit is a one-off change (not part of a development thread)
and doesn't fix a particular bug, you can use one of the <a
href="http://www.openndylan.org/cvszilla/job.cgi">general
development jobs</a>.  In this case the first line of the commit log
should look like:

<pre>
Job: <var>job-name</var> ...
</pre>

<h2>Line Endings</h2>

<p>Unlike CVS, Subversion does not convert line-ending styles unless
it is asked to; otherwise file contents are left alone no matter on
what platform you do a checkout.  To ensure that text files get LF
line-endings on Unix-line platforms and CRLF line-endings on Win32,
you need to add <a
href="http://svnbook.red-bean.com/svnbook-1.1/ch07s02.html#svn-ch-7-sect-2.3.5"><tt>svn:eol-style</tt>
properties</a> to text files.<p>

<p>The easy way to ensure that new files are added with this property
present is to use the Subversion <a
href="http://svnbook.red-bean.com/svnbook-1.1/ch07s02.html#svn-ch-7-sect-2.4">auto-props</a>
feature.  In your <tt>~/.subversion/config</tt> file you'll find
commented-out configuration entries for enabling auto-props.  For example,

<pre>
### Section for configuring miscellaneous Subversion options.
[miscellany]
### Set enable-auto-props to 'yes' to enable automatic properties
### for 'svn add' and 'svn import', it defaults to 'no'.
### Automatic properties are defined in the section 'auto-props'.
enable-auto-props = yes

### Section for configuring automatic properties.
### The format of the entries is:
###   file-name-pattern = propname[=value][;propname[=value]...]
### The file-name-pattern can contain wildcards (such as '*' and
### '?').  All entries which match will be applied to the file.
### Note that auto-props functionality must be enabled, which
### is typically done by setting the 'enable-auto-props' option.
[auto-props]
*.bat = svn:mime-type=text/plain;svn:eol-style=native
*.bmp = svn:mime-type=image/bmp
*.c = svn:mime-type=text/plain;svn:eol-style=native
*.css = svn:mime-type=text/css;svn:eol-style=native
*.cpp = svn:mime-type=text/plain;svn:eol-style=native
*.cxx = svn:mime-type=text/plain;svn:eol-style=native
*.dylan = svn:mime-type=text/plain;svn:eol-style=native
*.dylgram = svn:mime-type=text/plain;svn:eol-style=native
*.el = svn:mime-type=text/plain;svn:eol-style=native
*.gif = svn:mime-type=image/gif
*.h = svn:mime-type=text/plain;svn:eol-style=native
*.hdp = svn:mime-type=text/plain;svn:eol-style=native
*.htm = svn:mime-type=text/html;svn:eol-style=native
*.html = svn:mime-type=text/html;svn:eol-style=native
*.ico = svn:mime-type=image/x-icon
*.idl = svn:mime-type=text/plain;svn:eol-style=native
*.intr = svn:mime-type=text/plain;svn:eol-style=native
*.jam = svn:mime-type=text/plain;svn:eol-style=native
*.java = svn:mime-type=text/plain;svn:eol-style=native
*.jpeg = svn:mime-type=image/jpeg
*.jpg = svn:mime-type=image/jpeg
*.lid = svn:mime-type=text/plain;svn:eol-style=native
*.lisp = svn:mime-type=text/plain;svn:eol-style=native
*.lout = svn:mime-type=text/plain;svn:eol-style=native
*.m4 = svn:mime-type=text/plain;svn:eol-style=native
*.pdf = svn:mime-type=application/pdf
*.pl = svn:mime-type=text/plain;svn:eol-style=native;svn:executable
*.png = svn:mime-type=image/png
*.py = svn:mime-type=text/plain;svn:eol-style=native;svn:executable
*.rc = svn:mime-type=text/plain;svn:eol-style=native
*.sgm = svn:mime-type=text/sgml;svn:eol-style=native
*.sgml = svn:mime-type=text/sgml;svn:eol-style=native
*.sh = svn:mime-type=text/plain;svn:eol-style=native;svn:executable
*.spec = svn:mime-type=text/plain;svn:eol-style=native
*.sql = svn:mime-type=text/plain;svn:eol-style=native
*.tif = svn:mime-type=image/tiff
*.tiff = svn:mime-type=image/tiff
*.text = svn:mime-type=text/plain;svn:eol-style=native
*.txt = svn:mime-type=text/plain;svn:eol-style=native
*.xhtml = svn:eol-style=native
*.xml = svn:mime-type=text/xml;svn:eol-style=native
INSTALL = svn:mime-type=text/plain;svn:eol-style=native
Makefile = svn:mime-type=text/plain;svn:eol-style=native
Makefile.in = svn:mime-type=text/plain;svn:eol-style=native
README = svn:mime-type=text/plain;svn:eol-style=native
</pre>

<h2>For More Information</h2>

<ul>
  <li><a href="http://www.onlamp.com/pub/a/onlamp/2004/08/19/subversiontips.html">The Top Ten Subversion Tips for CVS Users</a></li>
  <li><a href="http://svnbook.red-bean.com/">Version Control with Subversion</a></li>
  <li><a href="http://svn.collab.net/repos/svn/trunk/doc/user/cvs-crossover-guide.html">CVS to SVN Crossover Guide</a></li>
  <li><a href="http://svn.collab.net/repos/svn/trunk/doc/user/svn-best-practices.html">Subversion Best Practices</a></li>
  <li><a href="http://subversion.tigris.org/faq.html">Subversion FAQ</a></li>
  <li><a href="http://www.cs.put.poznan.pl/csobaniec/Papers/svn-refcard.pdf">Subversion Quick Reference Card</a></li>
  <li><a href="http://tortoisesvn.tigris.org">TortoiseSVN</a> (Win32 Explorer shell integration)</li>
</ul>

<od:standard-footer/>
