<%dsp:taglib name="od"/>

<od:standard-header>Building Gwydion Dylan on Microsoft Windows (Cygwin)</od:standard-header>

<p>One option for running Gwydion Dylan on the Microsoft Windows operating system is by utilizing <a href="http://www.cygwin.com/">Cygwin</a>, a Linux-like environment for Windows. The following steps should allow you to build you a working Gwydion Dylan compiler on Windows.</p>

<h3>1) Install Cygwin</h3>

<p>Download the current version of the Cygwin <a href="http://www.cygwin.com/setup.exe">setup</a> program from the
Cygwin web site.</p>

<p>Run the setup program and install the default Cygwin packages plus
these additional packages (at a minimum):</p>

<ul>
  <li>Devel/autoconf</li>
  <li>Devel/automake</li>
  <li>Devel/bison</li>
  <li>Devel/flex</li>
  <li>Devel/gcc</li>
  <li>Devel/gcc-g++</li>
  <li>Devel/gdb</li>
  <li>Devel/libtool</li>
  <li>Devel/make</li>
</ul>

<p>If you download the Gwydion Dylan source code using Subversion, you will want to also install the following package:</p>

<ul>
  <li>Devel/subversion</li>
</ul>

<h3>2) Install the Boehm-Demers-Weiser conservative garbage collector</h3>

<p>Download the version 6.2 source package from <a href="http://www.hpl.hp.com/personal/Hans_Boehm/gc/gc_source/">http://www.hpl.hp.com/personal/Hans_Boehm/gc/gc_source/</a> and save it into your Cygwin user home directory</p>

<p>Start a Cygwin bash shell from the Windows start menu</p>

<p>Execute commands similar to the following:</p>

<pre>tar -zxvf gc6.2.tar.gz
cd gc6.2
./configure
make
make install</pre>

<h3>3) Retrieve the source code</h3>

<p>These instructions assume you will place the Gwydion Dylan source code in the directory <code>~/gd/src</code></p>

<p>You have two options for obtaining the Gwydion Dylan source code:
downloading a <a href="http://www.opendylan.org/downloads/src/tar/">tarball</a>
of the source code, or alternatively, by retrieving the Gwydion Dylan source code from
the repository using the CVS version control system.</p>

<p>To get the source code via SVN, checkout the 2.4 branch of the source:</p>

<pre>mkdir gd
cd gd
svn checkout svn://anonsvn.gwydiondylan.org/scm/svn/dylan/branches/GD_2_4/gwydion src</pre>

<h3>4) Build the dbclink tool</h3>

<p>For the Windows version of Gwydion Dylan you need to compile and install a special program to allow Gwydion Dylan&#8217;s Mindy byte compiler to work correctly:</p>

<pre>
cd ~gd/src/tools/win32-misc
make dbclink
cp dbclink.exe /usr/local/bin</pre>

<p>Now you are ready for the main part of the build.</p>

<h3>5) Build the system</h3>

<p>Since you don't already have a working copy of Gwydion Dylan you need to do a 'bootstrap' from Mindy. Mindy is a Dylan bytecode interpreter. It compiles Dylan to a bytecode and interprets that bytecode. When bootstrapping, Mindy is used to compile Gwydion Dylan and then that bytecode version is used to re-compile Gwydion Dylan to C. That c-compiled version becomes the final Gwydion Dylan compiler that is installed.</p>
<p>If it sounds like a long process, that's because it is. Mindy interpreted programs are quite slow. Don't despair though. Run it overnight and you'll have a super fast Gwydion Dylan compiler in the morning. Once you have this bootstrapped compiler you need never bootstrap again. Just use the existing Gwydion Dylan binary to rebuild the system if you want to modify the compiler.</p>

<p>To bootstrap, perform the following steps:</p>

<pre>cd ../..                                  (this should return you into ~/gd/src)
./autogen.sh --with-gc-prefix=/usr/local
make</pre>

<p>This will bootstrap d2c. It will take a long time.</p>

<p>After <code>make</code> completes, execute the following:</p>

<pre>make install</pre>

<h3>6) Rebuild with the new d2c</h3>

<p>Using the newly bootstrapped d2c, try rebuilding d2c again to test that it works okay. This should work faily quickly as you are not using Mindy to do the build. If you ever want to re-bootstrap with Mindy, pass the <code>--enable-mindy-bootstrap</code> argument to <code>configure</code>.</p>

<pre>
cd ~/gd/src
./configure --with-gc-prefix=/usr/local
make
make install</pre>

<h3>7) Test the system</h3>

<p>Test the system with a simple 'hello world' application:</p>

<pre>cd
make-dylan-app hello
cd hello
make
./hello</pre>

<p>You should see <code>Hello, World!</code> appear on the console.</p>

<h3>8) Done!</h3>

<p>Well done, you've successfully built Gwydion Dylan for Windows!</p>

<p>Note: Once you compile and install, you may get the following problem: programs 
  compile but don't link because libtool require a blank configure.in - just run 
  <code>touch configure.in</code> to create a blank one to solve that. This is 
  a workaround at this stage... :-)</p>
<p>You may also want to download the libraries and examples, which you can do 
  with the following commands:</p>
<p>svn checkout svn://anonsvn.gwydiondylan.org/scm/svn/dylan/trunk/libraries<br>
  svn checkout svn://anonsvn.gwydiondylan.org/scm/svn/dylan/trunk/examples</p>
<od:standard-footer/>
