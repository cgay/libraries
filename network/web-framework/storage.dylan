module: storage
author: Hannes Mehnert <hannes@mehnert.org>

define variable *directory* = "/";

define sideways method process-config-element
    (node :: <xml-element>, name == #"web-framework")
  let cdir = get-attr(node, #"content-directory");
  if (~cdir)
    log-warning("Web Framework - No content-directory specified!");
  else
    *directory* := cdir;
  end;
  log-info("Web framework content directory = %s", *directory*);
  restore-newest(*directory*);
end;

define variable *storage* = make(<table>);

define variable *version* :: <integer> = 0;

define variable *rev* :: <integer> = 0;
define constant $database-lock = make(<recursive-lock>);

define open generic storage-type (type) => (res);

define open generic key (class) => (res);
define method key (class) => (res)
  #f;
end;
define method storage-type (type) => (res)
  <stretchy-vector>;
end;

define open generic storage (type) => (res);
define method storage (type) => (res)
  let res = element(*storage*, type, default: #f);
  unless (res)
    res := make(storage-type(type));
    *storage*[type] := res;
  end;
  res;
end;

define open generic setup (class) => ();

define method setup (class)
 => ();
end;

define macro with-storage
  { with-storage (?:variable = ?type:expression)
      ?body:body
    end }
 =>  { begin
         with-lock($database-lock)
           let ?variable = storage(?type);
           ?body
         end
       end }
end;

define open generic save (object :: <object>) => ();

define method save (object) => ()
  with-lock($database-lock)
    add-object(storage(object.object-class), object);
    //if (*rev* = 100 | *version* = 0)
    //  really-dump-all-data();
    //else
    //  dump-single-object(object);
    //end;
  end;
end;

define method add-object (list :: <collection>, ele :: <object>)
  *storage*[ele.object-class] := add!(list, ele);
end;

define method add-object (table :: <table>, ele :: <object>)
  table[ele.key] := ele
end;

define class <storage> (<object>)
  constant slot hash-table = *storage*;
  constant slot table-version = *version*;
end;

define constant $filename = last(split(application-name(), '/'));

define inline function generate-filename () => (res :: <string>)
  concatenate(*directory*, $filename, ".", integer-to-string(*version*));
end;

define function dump-single-object (object :: <object>) => ()
  let loc = concatenate(generate-filename(), ".", integer-to-string(*rev*));
  let dood = make(<dood>, locator: loc, direction: #"output", if-exists: #"replace");
  dood-root(dood) := object;
  dood-commit(dood);
  dood-close(dood);
  *rev* := *rev* + 1;
end;

define function really-dump-all-data () => ()
  *version* := *version* + 1;
  let loc = generate-filename();
  let dood = make(<dood>, locator: loc, direction: #"output", if-exists: #"replace");
  dood-root(dood) := make(<storage>);
  dood-commit(dood);
  dood-close(dood);
  *rev* := 0;
end;
define method dump-data () => ()
  with-lock ($database-lock)
    really-dump-all-data();
  end;
end;

define method restore (directory :: <string>, filename :: <string>) => ()
  let dood = make(<dood>,
                  locator: merge-locators(as(<file-locator>, filename),
                                          as(<directory-locator>, directory)),
                  direction: #"input");
  let storage-root = dood-root(dood);
  dood-close(dood);
  let major = split-file(filename);
  with-lock ($database-lock)
    *storage* := storage-root.hash-table;
    *version* := storage-root.table-version;
    //ok, restored major version, now restore all patches!
    let minor-list = make(<vector>, size: 100, fill: #f);
    do-directory(method (dir :: <pathname>, fname :: <string>, type :: <file-type>)
                   if (type == #"file")
                     let min = minor-version?(major, fname);
                     if (min)
                       minor-list[min] := fname;
                     end;
                   end;
                 end, directory);
    for (minor in minor-list, i from 1)
      if (minor)
        let d = make(<dood>, locator: concatenate(directory, minor), direction: #"input");
        let obj = dood-root(d);
        dood-close(d);
        add-object(storage(obj.object-class), obj);
        //setup(obj);
        *rev* := i;
      end;
    end;
  end;
  for (class in key-sequence(*storage*))
    setup(class);
  end for;
end;

define inline function minor-version? (major :: <integer>, minor :: <string>)
 => (res :: false-or(<integer>))
  let filename-elements = split(minor, '.');
  if ((filename-elements.size = 3)
      & (filename-elements[0] = $filename)
      & (string-to-integer(filename-elements[1]) = major))
    string-to-integer(filename-elements[2]);
  else
    #f;
  end;
end;
define method restore-newest (directory :: <string>) => ()
  let file = #f;
  let latest-version = 0;
  do-directory(method (dir :: <pathname>, filename :: <string>, type :: <file-type>)
                 if (type == #"file")
                   let version = split-file(filename);
                   if (version > latest-version)
                     latest-version := version;
                     file := filename
                   end;
                 end;
               end, directory);
  if (file)
    restore(directory, file);
  end;
end;

define function dumper (#key interval :: <integer> = 300, do-something :: false-or(<function>) = #f) => ()
  make(<thread>,
       function: method()
                     sleep(23);
                     while(#t)
                       dump-data();
                       if (do-something)
                         do-something()
                       end;
                       sleep(interval);
                     end;
                 end);
end;

define function split-file (filename :: <string>) => (version :: <integer>)
  let elements = split(filename, '.');
  block()
    if ((elements.size = 2) & (elements[0] = $filename))
      string-to-integer(elements[1]);
    else
      0;
    end;
  exception (e :: <error>)
    0
  end;
end;
