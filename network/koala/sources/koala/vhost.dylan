Module:    httpi
Synopsis:  Virtual hosts
Author:    Carl Gay
Copyright: Copyright (c) 2004 Carl L. Gay.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND


// Some methods to make logging slightly more convenient by not having
// to always pass log-target(*virtual-host*).
define method log-copious (format-string, #rest format-args)
  apply(%log-copious, *temp-log-target* | debug-log-target(*virtual-host*), format-string, format-args);
end;
define method log-verbose (format-string, #rest format-args)
  apply(%log-verbose, *temp-log-target* | debug-log-target(*virtual-host*), format-string, format-args);
end;
define method log-debug (format-string, #rest format-args)
  apply(%log-debug, *temp-log-target* | debug-log-target(*virtual-host*), format-string, format-args);
end;
define method log-info (format-string, #rest format-args)
  apply(%log-info, *temp-log-target* | debug-log-target(*virtual-host*), format-string, format-args);
end;
define method log-warning (format-string, #rest format-args)
  apply(%log-warning, *temp-log-target* | error-log-target(*virtual-host*), format-string, format-args);
end;
define method log-error (format-string, #rest format-args)
  apply(%log-error, *temp-log-target* | error-log-target(*virtual-host*), format-string, format-args);
end;


define class <directory-spec> (<object>)
  constant slot dirspec-pattern :: <string>,
    required-init-keyword: pattern:;

  // TODO:
  // If this regular expression is the first to match the request URL
  // then this directory spec will be used.
  slot regular-expression :: <string>;        // will be <regular-expression>
  
  // Whether to allow directory listings.
  // May be overridden for specific directories.
  // Default is to be secure.
  slot allow-directory-listing? :: <boolean> = #f,
    init-keyword: allow-directory-listing?:;

  // Whether to allow serving documents that are outside of the document
  // root and are accessed via a symlink from within the document root.
  // Default is to be secure.
  slot follow-symlinks? :: <boolean> = #f,
    init-keyword: follow-symlinks?:;

  // TODO:
  //slot allow-cgi?, etc ...
  
end;


define method initialize
    (spec :: <directory-spec>, #key pattern, #all-keys)
  // TODO:
  // This is temp code, depending on the fact that we only create specs ending
  // in '*' right now.
  let pos = char-position('*', pattern, 0, size(pattern));
  regular-expression(spec) := iff(pos, substring(pattern, 0, pos), pattern);
end;


define method dirspec-matches?
    (spec :: <directory-spec>, url :: <string>)
  // TODO: regular expressions.  For now if it's an initial substring match that'll do.
  looking-at?(regular-expression(spec), url, 0, size(url))
end;


// Most slots are set when the config file is processed.  A valiant attempt
// should be made to use good defaults, in case the config file doesn't specify
// a value.

define class <virtual-host> (<object>)
  constant slot vhost-name :: <string>,
    required-init-keyword: name:;

  // The root of the web document hierarchy.  By default, this will be
  // *server-root*/www/<vhost-name>/.  If name is the empty string then
  // just *server-root*/www/.
  slot document-root :: <directory-locator>;

  // TODO: no need for this here.  Even though ports can be specified inside
  //       the virtual host definition in the config file, we just need a 
  //       list of virtual hosts per port.  Start up one listener per port
  //       and serve requests only for the vhosts that are registered on that
  //       port.
  slot vhost-port :: <integer> = 80;

  slot vhost-ip :: <string> = "0.0.0.0";

  // List of <directory-spec> objects that determine how documents in
  // different directories are treated.  These are searched in order,
  // and the first one to match the requested URL is used.  Items are
  // pushed onto the beginning of this list as the config file is read,
  // so if two specs match the request URL then later specs will take
  // precedence.  I think this will match the natural usage, where people
  // will put more general specs first in the file and more specific ones
  // later, but we might want to revisit this decision.
  slot directory-specs :: <list>
    = list();

  // Each vhost gets an implicitly defined spec for the vhost root directory.
  // It must, of course, match all documents under the vhost document root.
  // It should always be the last element in directory-specs(vhost).
  // See initialize(<virtual-host>).
  constant slot root-directory-spec :: <directory-spec>
    = make(<directory-spec>,
           pattern: "/*");

  // Whether or not to include a Server: header in all responses.  Most people
  // won't care either way, but some might want to hide the server type so as
  // to prevent cracking or to hide the fact that they're not using one of the
  // Chosen Few accepted technologies.  Wimps.  ;-)
  slot generate-server-header? :: <boolean> = #t;

  // TODO: this should be per-dirspec.  no reason some subtree on the same
  //       vhost shouldn't have a different set of default docs.
  // The set of file names that are searched for when a directory URL is
  // requested.  They are searched in order, and the first match is chosen.
  slot default-documents :: <list>
    = list(as(<file-locator>, "index.html"),
           as(<file-locator>, "index.htm"));

  // The value sent in the "Content-Type" header for static file responses if
  // no other value is set.  See *mime-type-map*.
  slot default-static-content-type :: <string> = "application/octet-stream";

  // The value sent in the "Content-Type" header for dynamic responses if no
  // other value is set.
  slot default-dynamic-content-type :: <string> = "text/html; charset=utf-8";

  // This is the "master switch" for auto-registration of URLs.  If #f then
  // URLs will never be automatically registered based on their file types.  It
  // defaults to #f to be safe.  See auto-register-map
  slot auto-register-pages? :: <boolean> = #f;

  // Maps from file extensions (e.g., "dsp") to functions that will register a
  // URL responder for a URL.  If a URL matching the file extension is
  // requested, and the URL isn't registered yet, then the function for the
  // URL's file type extension will be called to register the URL and then the
  // URL will be processed normally.  This mechanism is used, for example, to
  // automatically export .dsp URLs as Dylan Server Pages so that it's not
  // necessary to have a "define page" form for every page in a DSP
  // application.
  // TODO: x-platform: this should be a case-sensitive string table for 
  //       unix variants and insensitive for Windows.
  constant slot auto-register-map :: <table> = make(<string-table>);

  // Log targets.  If these are #f then the default virtual host's
  // log target is used.  They are never #f in $default-virtual-host.
  slot %activity-log-target :: false-or(<log-target>) = #f,
    init-keyword: #"activity-log";
  slot %error-log-target :: false-or(<log-target>) = #f,
    init-keyword: #"error-log";
  slot %debug-log-target :: false-or(<log-target>) = #f,
    init-keyword: #"debug-log";

end class <virtual-host>;


define method initialize
    (vhost :: <virtual-host>, #key name, #all-keys)
  next-method();
  log-debug("name = %=, vhost-name = %=\n", name, vhost-name(vhost));
  ensure-server-root();
  // This may be overridden by a <document-root> spec in the config file.
  document-root(vhost) := subdirectory-locator(*server-root*, name);
  // Add a spec that matches all urls.
  add-directory-spec(vhost, root-directory-spec(vhost));
end;

define method activity-log-target
    (vhost :: <virtual-host>) => (target :: <log-target>)
  vhost.%activity-log-target | $default-virtual-host.%activity-log-target
end;

define method debug-log-target
    (vhost :: <virtual-host>) => (target :: <log-target>)
  vhost.%debug-log-target | $default-virtual-host.%debug-log-target
end;

define method error-log-target
    (vhost :: <virtual-host>) => (target :: <log-target>)
  vhost.%error-log-target | $default-virtual-host.%error-log-target
end;

define method add-directory-spec
    (vhost :: <virtual-host>, spec :: <directory-spec>)
  directory-specs(vhost)
    := pair(spec, remove!(directory-specs(vhost), spec,
                          test: method (s1, s2)
                                  dirspec-pattern(s1) = dirspec-pattern(s2)
                                end));
end;

// The vhost used if the request host doesn't match any other virtual host.
// Note that the document root may be changed when the config file is
// processed, so don't use it except during request processing.
//
define constant $default-virtual-host :: <virtual-host>
  = begin
      let stdout-log = make(<stream-log-target>, stream: *standard-output*);
      make(<virtual-host>,
           name: "default",
           activity-log: stdout-log,
           debug-log: stdout-log,
           error-log: make(<stream-log-target>, stream: *standard-error*))
    end;

// If this is true, then requests directed at hosts that don't match any
// explicitly named virtual host (i.e., something created with <virtual-host>
// in the config file) will use the default vhost.  If this is #f when such a
// request is received, a Bad Request (400) response will be returned.
//
define variable *fall-back-to-default-virtual-host?* :: <boolean> = #t;

// Maps host names to virtual hosts.  Any host name not found in this
// table maps to $default-virtual-host (contingent on the value of
// *fall-back-to-default-virtual-host?*).
define constant $virtual-hosts :: <string-table> = make(<string-table>);

define thread variable *virtual-host* :: <virtual-host> = $default-virtual-host;

begin
  *temp-log-target* := #f;
end;

define method add-virtual-host
    (name :: <string>, vhost :: <virtual-host>)
  $virtual-hosts[name] := vhost;
end;

define method virtual-host
    (name :: <string>) => (vhost :: false-or(<virtual-host>))
  element($virtual-hosts, name, default: #f)
end;

define method virtual-host
    (request :: <request>) => (vhost :: false-or(<virtual-host>))
  let host-spec = request-host(request);
  local method die ()
          bad-request(message: format-to-string("Unknown virtual host: %s",
                                                host-spec));
        end;
  if (host-spec)
    let colon = char-position(':', host-spec, 0, size(host-spec));
    let host = iff(colon, substring(host-spec, 0, colon), host-spec);
    let port = colon &
                 block ()
                   string-to-integer(host-spec, start: colon + 1)
                 exception (ex :: <error>)
                   log-debug("error parsing port in host spec");
                   die();
                 end;
    let vhost = virtual-host(host) | (*fall-back-to-default-virtual-host?*
                                        & $default-virtual-host);
    // TODO: If this is an HTTPS request and no port is specified, make sure
    //       vhost-port(vhost) == 443
    if (vhost & ((~port & vhost-port(vhost) == 80)
                   | port == vhost-port(vhost)))
      vhost
    else
      die();
    end;
  else
    (*fall-back-to-default-virtual-host?* & $default-virtual-host)
      | die()
  end
end;

define method virtual-host
    (port :: <integer>) => (vhost :: false-or(<virtual-host>))
  block (return)
    for (vhost :: <virtual-host> keyed-by name in $virtual-hosts)
      if (vhost-port(vhost) == port)
        return(vhost)
      end
    end
  end
end;

define method directory-spec-matching
    (vhost :: <virtual-host>, url :: <string>)
  iterate loop (specs :: <list> = directory-specs(vhost))
    if (empty?(specs))
      // The last spec is guaranteed to match all documents under the document root,
      // so if we get here it's an error.
      // TODO: improve the error message here, at least in the case where debugging
      //       is enabled.
      internal-server-error();
    else
      let spec :: <directory-spec> = head(specs);
      iff(dirspec-matches?(spec, url),
          spec,
          loop(tail(specs)));
    end;
  end;
end;

