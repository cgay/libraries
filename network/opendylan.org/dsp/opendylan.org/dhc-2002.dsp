<%dsp:taglib name="od"/>

<od:standard-header>Dylan Hackers Conference</od:standard-header>

<pre>
From: Andreas Bogk <andreas@andreas.org>
Subject: Dylan Hackers Conference - Report
To: gd-hackers@gwydiondylan.org
Date: Mon, 29 Jul 2002 16:11:08 +0000

Hi!

The first DHC is over, and I'm very happy with the result.  

On friday evening, we (that were Peter Housel, Gabor Greif, David
Lichteblau, Tim Pritlove and me) had a nice discussion at the c-base
about the compiler and it's future.  As far as I can remember, the
following issues came up:

- We need more libraries to attract people
- Some day, we want to have a native backend
- There's a lot of good code (DUIM, deuce) which we need to make work
- The decriptor_t representation makes multi-threading impossible
- Some day, we want to have our own, non-conservative GC
- We want an interactive compiler
- We want procedural macros

Also, we decided on friday that best use of our time would be to write
some useful code.  We chose to implement an interpreter for the
intermediate code that comes out of the optimizer, as something that
would bring us closer to the last two goals above.

So on saturday Peter, Gabor and me got hacking.  You can see the
results by checking out the branch "interpreter" from CVS, and then
doing something like:

$ d2c -i
gwydion> begin local fac(n :: <integer>) n == 0 & 1 | n * fac(n - 1) end; fac(5); end

And it will correctly calculate the answer:

evaluated expression: {literal extended-integer 120}

Access to non-local bindings doesn't work.  Defining functions,
classes and methods doesn't work.  Lots of the primitives are
unimplemented.  Every assigment makes the environment grow, as does
any iteration through a loop.  But we're already much better than the
built-in constant folding, which doesn't even know how to calculate 
"2 + 3 + 4".

Saturday ended sunday evening, so there's not much else that happened.
We fixed a bug that prevented testworks from compiling, so all that's
between us and Gwydion Dylan 2.4 is a lot of cleanup and testing.
Your help is needed to make it happen.

Thanks again to all the participants.

Andreas

-- 
"In my eyes it is never a crime to steal knowledge. It is a good
theft. The pirate of knowledge is a good pirate."
                                                       (Michel Serres)

</pre>


<od:standard-footer/>
