module: main

//// Arguments

// TODO: Make --name-list a separate task from doc gen.

define argument-parser <my-arg-parser> ()
   regular-arguments files;
   option toc-pattern = "toc",
      " <ext>", "Read as table of contents file [\"toc\"]",
      long: "toc", short: "t", kind: <parameter-option-parser>;
   option cfg-pattern = "cfg",
      " <ext>", "Read as configuration file [\"cfg\"]",
      long: "cfg", short: "c", kind: <parameter-option-parser>;
   option doc-pattern = "txt",
      " <ext>", "Read as documentation text file [\"txt\"]",
      long: "doc", short: "d", kind: <parameter-option-parser>;
   option api-list-filename,
      " <filename>", "Write fully qualified API names to file",
      long: "name-list", kind: <parameter-option-parser>;
   // option title = "Untitled",
   //    " <title>", "Title of documentation [Untitled]",
   //    long: "title", kind: <parameter-option-parser>;
   // option tab-size = "8",
   //    " <n>", "Tab size [8]",
   //    long: "tabsize", kind: <parameter-option-parser>;
   option disabled-warnings,
      " <nn>", "Hide warning message",
      long: "no-warn", short: "w", kind: <repeated-parameter-option-parser>;
   option stop-on-errors?,
      "Stop on first error or warning",
      long: "stop";
   option quiet?,
      "Hide progress messages",
      long: "quiet", short: "q";
   option help?,
      "Show this help message and exit",
      long: "help";
   option version?,
      "Show program version and exit",
      long: "version";
   synopsis print-help,
      usage: "doctower [options] <files>",
      description: "Creates Dylan API documentation from files."
end argument-parser;


//// Main

define constant $disabled-warnings = make(<stretchy-vector>);
define variable $stop-on-errors? :: <boolean> = #f;
define variable $error-code :: false-or(<integer>) = #f;

define function main (name, arguments)

   // Check arguments

   let args = make(<my-arg-parser>);
   let good-options? = parse-arguments(args, arguments);
   
   case
      ~good-options? =>
         error-in-command-arguments();
      args.help? =>
         print-help(args, *standard-output*);
         exit-application(0);
      args.version? =>
         format-out("Doctower 1.0\nby Dustin Voss");
         exit-application(0);
      args.files.empty? =>
         no-files-in-command-arguments();
   end case;
   
   block()
      map-into($disabled-warnings, string-to-integer, args.disabled-warnings)
   exception (e :: <error>)
      error-in-command-option(option: "--no-warn");
   end block;

   $stop-on-errors? := args.stop-on-errors?;
   $verbose? := ~args.quiet?;
   $api-list-filename := 
         when (args.api-list-filename)
            as(<file-locator>, args.api-list-filename)
         end when;

   let toc-files = make(<stretchy-vector>);
   let doc-files = make(<stretchy-vector>);
   let src-files = make(<stretchy-vector>);
   for (filename in args.files)
      block()
         let loc = as(<file-locator>, filename);
         select (loc.locator-extension by case-insensitive-equal?)
            args.doc-pattern => doc-files := add!(doc-files, loc);
            args.toc-pattern => toc-files := add!(toc-files, loc);
            ("dylan", "dyl", "lid") => src-files := add!(src-files, loc);
            otherwise => file-type-not-known(filename: filename);
         end select;
      exception (<skip-error-restart>)
      end block;
   end for;

   // Process files.

   let doc-tree = create-doc-tree(toc-files, doc-files, src-files);
   // TODO: Write doc-tree as HTML or DITA.
   // TODO: For now, just output it.
   print(doc-tree, *standard-output*, pretty?: #t);
   new-line(*standard-output*);

   exit-application($error-code | 0);
end function main;


// Invoke our main() function with error handlers.
begin
   let handler <user-visible-error> =
         method (cond, next)
            report-condition(cond, *standard-error*);
            new-line(*standard-error*);
            when ($stop-on-errors?)
               exit-application(cond.error-code);
            end when;
            $error-code := $error-code | cond.error-code;
            signal(make(<skip-error-restart>, condition: cond));
         end method;

   let handler <user-visible-warning> =
         method (cond, next)
            case
               member?(cond.error-code, $disabled-warnings) =>
                  #f;
               $stop-on-errors? =>
                  report-condition(cond, *standard-error*);
                  new-line(*standard-error*);
                  exit-application(cond.error-code);
               otherwise =>
                  report-condition(cond, *standard-output*);
                  new-line(*standard-output*);
            end case
         end method;

   let handler <skip-error-restart> =
         method (cond, next)
            exit-application($error-code);
         end method;
         
   *default-line-length* := 120;
   main(application-name(), application-arguments());
end
