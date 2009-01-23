<%dsp:taglib name="od"/>

<od:standard-header>Working with Other tools</od:standard-header>

<P>The <EM>Gwydion Dylan</EM> developers use a wide range of tools to
develop source code.  The following is a set of helpful links and snippets
of information to get you up to speed in these disparate environments:</p>

<H3>Source Editing</H3>
<p>The most important tool for any developer (aside from the compiler!) is the
editing environment.  Dylan is well-supported by a number of tools, both
Free and commercial.</p>

<H4>Emacs</H4>
<p>Most developers use one of the various <a href="http://www.gnu.org/directory/emacs.html">
Emacs</a> <a href="http://www.xemacs.org">flavors</a>.  We include a full
Emacs editing <a href="http://www.opendylan.org/cgi-bin/viewcvs.cgi/trunk/gwydion/tools/elisp">mode</a> in the standard source release.  Look for it in the <tt>gwydion/tools/elisp</tt> directory.</p>
<H4>Vim</H4>
<p>At least one developer likes to use <a href="http://www.vim.org">Vim</a>.
Vim comes out-of-the-box in Version 6.2 with Dylan editing and indentation
support.</p>
<H4>Codewarrior</H4>
<p>Several of the developers use <a href="http://www.metrowerks.com">Metrowerks</a> 
<a href="http://www.metrowerks.com/MW/Develop/Desktop/Macintosh/Professional/mac9.htm">CodeWarrior</a>.  A
<a href="http://www.opendylan.org/cgi-bin/viewcvs.cgi/trunk/gwydion/d2c/compiler/Macintosh/">plugin</a> 
is available (in the main source distribution) to use CodeWarrior
as a full Dylan IDE.</p>
<H4>Open Dylan</H4>
<p>The premier Dylan environment.  Though this tool set does not currently support
Gwydion Dylan natively, it
is an excellent Windows (and Linux) development platform for Dylan development.</p>

<H3>Source Conversion</H3>

<H4>LTD</H4>

<P><a href="http://www.norvig.com/">Peter Norvig</a>'s <a
href="http://www.norvig.com/ltd/doc/ltd.html">LTD</a> tool can convert
legacy code from Common Lisp to Dylan, or at least greatly reduce the
amount of manual labor required.</P>

<H3>Source Viewing</H3>
Life isn't all about hacking -- sometimes you need to research or review
other people's code.
<H4>enscript</H4>
<p>This powerful GNU program can format source code, convert between various
page formats, and render HTML-ized versions of source code.  We wrote a
<a href="/downloads/contributions/dylan.st">
template</a> so that Enscript can render Dylan sources.  We use this plugin
behind the scenes to power our installation of <a href="http://viewcvs.sourceforge.net">
ViewCVS</a>.</p>

<od:standard-footer/>
