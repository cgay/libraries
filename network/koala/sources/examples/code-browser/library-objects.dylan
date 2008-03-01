module: code-browser
Synopsis: Browse Open Dylan environment objects
Author:   Andreas Bogk, Bastian Mueller, Hannes Mehnert

define body tag modules in code-browser
    (page :: <code-browser-page>, do-body :: <function>)
    ()
  do-library-modules(method(x)
                       dynamic-bind(*environment-object* = x)
                         do-body()
                       end;
                     end, *project*, *environment-object*);
end;

define body tag defined-modules in code-browser
    (page :: <code-browser-page>, do-body :: <function>)
    ()
  do-library-modules(method(x)
                       dynamic-bind(*environment-object* = x)
                         do-body()
                       end;
                     end, *project*, *environment-object*, imported?: #f);
end;

define body tag used-libraries in code-browser
    (page :: <code-browser-page>, do-body :: <function>)
    ()
  do-used-definitions(method(x)
                       dynamic-bind(*environment-object* = x)
                         do-body()
                       end;
                     end, *project*, *environment-object*);
end;

