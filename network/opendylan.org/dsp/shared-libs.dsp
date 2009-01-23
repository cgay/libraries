<%dsp:taglib name="od"/>

<od:standard-header>Shared Libraries</od:standard-header>

<P>We're working on two problems with shared libraries, one easy and one
very difficult. The easy problem is getting shared libraries to work; the
hard one involves fixing the fragile base class problem.</P>

<P>To add portable shared library support to Gwydion, we'll take advantage
of GNU libtool, which knows way too much about how shared libraries work on
a great variety of Unix systems. This is relatively easy, modulo any
gremlins with position idependent code.</P>

<P>Unfortunately, we need to solve a much harder problem to make shared
libraries truly useful. A Dylan shared libary implementation is faced with
two choices: make shared libraries slow but maintain compatibility between
releases (like Java) or make shared libraries fast but break binary
compatibility even for very small changes (like C++).</P>

<P>We're looking for a middle ground between these two options, but haven't
figured out exactly how to handle this yet.</P>

<od:standard-footer/>
