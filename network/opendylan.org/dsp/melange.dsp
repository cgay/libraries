<%dsp:taglib name="od"/>

<od:standard-header>Interfacing with C</od:standard-header>

<p>For Dylan to be useful, it must interface seamlessly with C.
Most interesting libraries are written in C, including all of the
significant APIs for Unix systems.  Ideally, it should be as easy to
call a C function from a Dylan program as it is to call one from a C
program.</p>

<p>We already have working callbacks from C to Dylan code, on both IA-32
and PowerPC&mdash;even with callbacks to closures.</p>

<p>The original Gwydion developers at CMU wrote a nifty tool called Melange.
It parses C header files and automatically generates Dylan interface files.
We&rsquo;ve been slowly enhancing Melange to handle more complicated header files,
and stomping out all the bugs which we find along the way.</p>

<p>Somewhere along we decided to rewrite parts of Melange, and a new project
called Pidgin was started.  Pidgin has a working C header parser, but is
missing the code generation part.  This project was later shelved.</p>

<p>Peter Housel is now working on a brand new C code representation
library called CPR (for C Program Representation), inspired by
SML/NJ&rsquo;s <a href="http://www.smlnj.org/doc/ckit/">ckit</a> and
George Necula&rsquo;s <a href="http://manju.cs.berkeley.edu/cil/">CIL</a>.
This library will be able to parse C code and make its structure
available to Dylan programs as an abstract syntax tree.</p>

<p>The current plan is that a new CPR-based FFI mechanism called
Collage will be replacing Melange in the hopefully near future.
Unlike Melange, Collage won&rsquo;t usually generate interface files;
instead, it will be built into <code>d2c</code> and DFMC.</p>

<p>For now, however, Melange is your best bet if you want to use a C
library from a Gwydion Dylan program.  If you are using Open Dylan, there
is currently no really good alternative to Melange.  The existing bindings
are all generated by direct pattern-based translation of C header files
into Dylan interface files.  This is accomplished by a script written in
an arguably arcane translation language called Gema.  As stated above,
the plan is for Collage to do this job better in the future.</p>

<od:standard-footer/>