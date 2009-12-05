<%dsp:taglib name="od"/>

<od:standard-header>Current Limitations</od:standard-header>

<p>Here are some limitations of our Dylan implementations:</p>

<h3>Open Dylan</h3>

<ul>

<li>The IDE only runs on Windows because there is only a win32 backend
for DUIM.  There is a mostly-completed gtk+ backend.</li>

<li>The generated code doesn't run as fast as it could.  More
optimizations are needed.</li>

</ul>

<h3>Gwydion Dylan</h3>

<ul>

<li>d2c (the Gwydion compiler) generates fast code slowly.  This
problem was solved in the Open Dylan compiler by supporting
incremental compilation.  We'd like to do the same in d2c
eventually.</li>

<li>The Dylan-to-C interface is good, but sometimes has problems with
unusual constructs in system header files.</li>
<!-- What kind of problems?  How does it manifest?  -->

<li><strong>Debugging is uncomfortable.</strong> Although there's
support on most platforms for dybug, a gdb wrapper that understands
Dylan, this can hardly be called elegant. But at least it's there.</li>

<li>d2c supports most of the Dylan language as specified in the
<a href="books/drm/">Dylan Reference Manual</a> (DRM), but is lacking
support for some features, such as limited collections.</li>

</ul>

<h3>Mindy</h3>

<ul>

<li><strong>Mindy generates slow code quickly.</strong> You can
compile an enormous program into bytecodes in a blink of an eye, but
it won't run as fast as the average Perl script&mdash;it certainly
won't compete with GCC. Because Mindy has such a short turn-around
time (and a built-in debugger), some developers use it to prototype
programs, or just to make sure source files will compile before
subjecting them to a (relatively slow) d2c compile.</li>

<li><strong>Mindy doesn't support Dylan macros</strong> and a number
of other useful features.</li>

<li>No further work will be done on Mindy, and it will not be included
with 2.5.0 and later versions. All current work is focused on d2c and
Open Dylan.</li>

</ul>

<od:standard-footer/>
