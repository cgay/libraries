<%dsp:taglib name="od"/>

<od:standard-header>What is Dylan?</od:standard-header>


<P>Peter Hinely wrote one of the more concise descriptions of Dylan:</P>

<BLOCKQUOTE>
<EM>Dylan is an advanced, object-oriented, dynamic language which supports
the rapid development of programs.  When needed, the programmer can later
optimize [his or her] programs for more efficient execution by supplying
type information to the compiler.  Nearly all entities in Dylan (including
functions, classes, and basic data types such as integers) are first class
objects. Additionally Dylan supports multiple inheritance, polymorphism,
multiple dispatch, keyword arguments, object introspection, and many other
advanced features...</EM>
</BLOCKQUOTE>

<P>Dylan is fast, flexible and capable of unusually sophisticated abstractions.
The <a href="books/drm/">Dylan Reference Manual</a> defines the language
standard and has an excellent <a href="books/drm/drm_7.html">overview</a> of
Dylan's features.</P>

<p>Some <a href="fragments">code examples</a> can give a quick feel for
the language.</p>

<p>The Dylan Hackers maintain two Dylan implementations: Gwydion Dylan and Open
Dylan.</p>

<a name="gd"></a>
<h3>Gwydion Dylan</h3>

<p>
Gwydion Dylan is a Dylan-to-C compiler <A
HREF="http://www.cs.cmu.edu/afs/cs/project/gwydion/docs/htdocs/gwydion/">originally</A>
created by a team at Carnegie Mellon University.  Our current release is a
technology preview, suitable for learning the Dylan programming language and
building command-line applications.  Gwydion Dylan produces high-performance
code, but has <a href="limitations">a number of limitations</a> that make
it difficult to use for the beginner.  Gwydion is highly portable, with <a
href="/downloads/binaries/">binaries</a> available for many versions of Linux,
FreeBSD, Mac OS X, Cygwin, etc.
</p>

[ <a href="/downloads/binaries/">Download</a>
| <a href="/about-gwydion">&rsaquo; Why &quot;Gwydion&quot;?</a>
| <a href="/maintainers">&rsaquo; Gwydion Maintainers</a>
| <a href="http://www.cs.cmu.edu/afs/cs/project/gwydion/docs/htdocs/gwydion/">&raquo; Gwydion at CMU</a>
| <a href="http://monday.sourceforge.net/wiki/index.php/DylanHistory">Dylan History</a>
]

<a name="od"></a>
<h3>Open Dylan</h3>

<p>
Open Dylan compiles to native code and has a full-featured IDE including an
incremental development mode, browsing of runtime objects, remote debugging,
etc.  Open Dylan currently only runs on the x86 platform and the IDE does not
yet run on the Linux version.  Open Dylan is in many ways a mature
implementation.  If you are new to the language, choose Open Dylan if you can.
</p>

<!-- TODO: add screen shot links here -->

[ <a href="/downloads/opendylan/">Download</a>
| <a href="http://monday.sourceforge.net/wiki/index.php/DylanHistory">Dylan History</a>
]

<od:standard-footer/>
