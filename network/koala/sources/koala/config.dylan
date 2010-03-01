Module:    httpi
Synopsis:  For processing the configuration init file, koala-config.xml
Author:    Carl Gay
Copyright: Copyright (c) 2001-2004 Carl L. Gay.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND

/*
 * TODO: warn() should note whether it has been called (perhaps with a
 *       fatal? flag) and then after the entire config has been processed
 *       Koala should exit if there were errors.  It's a good way to debug
 *       the config file.  Many of the current warnings should be fatal.
 *
 * TODO: Should warn when unrecognized attributes are used.
 *       Makes debugging your config file much easier sometimes.
 *
 * TODO: Decide how to configure CGI directories/scripts.  i.e.,
 *       to add cgi-directory-responder via config only.
 */

define constant $koala-config-dir :: <string> = "config";

define constant $default-config-filename :: <string> = "koala-config.xml";

define thread variable %server = #f;

define thread variable %dir = #f;

// Holds the current vhost while config elements are being processed.
define thread variable %vhost = #f;

define class <configuration-error> (<koala-api-error>)
end;

define function config-error
    (format-string :: <string>, #rest format-args)
  signal(make(<configuration-error>,
              format-string: format-string,
              format-arguments: format-args))
end;

define function warn
    (format-string, #rest format-args)
  apply(log-warning,
        concatenate("CONFIG: ", format-string),
        format-args);
end;


// API
// Process the server config file, config.xml.
// Assume a user directory structure like:
// koala/
// koala/bin               // server executable and dlls
// koala/www               // default web document root
// koala/config            // koala-config.xml etc
define method configure-server
    (server :: <http-server>, config-file :: false-or(<string>))
  let defaults
    = merge-locators(merge-locators(as(<file-locator>, $default-config-filename),
                                    as(<directory-locator>, $koala-config-dir)),
                     server.server-root);
  let config-loc
    = as(<string>, merge-locators(as(<file-locator>, config-file | defaults),
                                  defaults));
  let text = file-contents(config-loc);
  if (text)
    log-info("Loading server configuration from %s.", config-loc);
    configure-from-string(server, text, filename: config-loc);
  elseif (config-file)
    // Only blow out if user specified a config file, not if they're taking
    // the default config file.
    config-error("Server configuration file (%s) not found.", config-loc);
  end if;
end method configure-server;

// This is separated out so it can be used by the test suite.
//
define method configure-from-string
    (server :: <http-server>, text :: <string>,
     #key filename :: false-or(<string>))
  let xml :: false-or(xml$<document>) = xml$parse-document(text);
  if (xml)
    dynamic-bind (%vhost = server.default-virtual-host,
                  %dir = root-directory-policy(server.default-virtual-host))
      process-config-node(server, xml);
    end;
  else
    config-error("Unable to parse configuration from %s",
                 filename | "string");
  end;
end method configure-from-string;

// Exported
// The xml-parser library doesn't seem to define anything like this.
define method get-attr
    (node :: xml$<element>, attrib :: <symbol>)
 => (value :: false-or(<string>))
  block (return)
    for (attr in xml$attributes(node))
      when (xml$name(attr) = attrib)
        return(xml$attribute-value(attr));
      end;
    end;
  end
end;

// I think the XML parser's class hierarchy is broken.  It seems <tag>
// should inherit from <node-mixin> so that one can descend the node
// hierarchy seamlessly.
define method process-config-node
    (server :: <http-server>, node :: xml$<tag>) => ()
end;

define method process-config-node
    (server :: <http-server>, node :: xml$<document>) => ()
  for (child in xml$node-children(node))
    process-config-node(server, child);
  end;
end;

define method process-config-node
    (server :: <http-server>, node :: xml$<element>) => ()
  process-config-element(server, node, xml$name(node));
end;

define method process-config-node
    (server :: <http-server>, node :: xml$<xml>) => ()
  config-error("Unexpected XML document element: %s", xml$name(node));
end;

// Exported.
// Libraries may specialize this.
// Note that the previous comment about the XML parser's class hierarchy
// applies here as well.  Otherwise this would specialize node more tightly.
//
define open generic process-config-element
    (server :: <http-server>, node :: <object>, name :: <object>);

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name :: <object>)
  warn("Unrecognized configuration setting: %=.  Processing child nodes anyway.",
       name);
  for (child in xml$node-children(node))
    process-config-node(server, child);
  end;
end;

define method process-config-element
    (server :: <http-server>, node :: xml$<comment>, name :: <object>)
end;

define function true-value?
    (val :: <string>) => (true? :: <boolean>)
  member?(val, #("yes", "true", "on"), test: string-equal?)
end;



//// koala-config.xml elements.  One method for each element name.

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"koala")
  for (child in xml$node-children(node))
    process-config-node(server, child);
  end;
end method process-config-element;


define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"listener")
  let address = get-attr(node, #"address");
  let port = get-attr(node, #"port");
  if (address | port)
    block ()
      let ssl = get-attr(node, #"ssl");
      let ssl? = ssl & true-value?(ssl);
      let port = port & string-to-integer(port);
      if (ssl?)
        let port = port | $default-https-port;
        let cert = get-attr(node, #"certificate");
        let key = get-attr(node, #"key");
        if (~cert | ~key)
          error("Both 'certificate' and 'key' are required for SSL listener %s:%d.",
                address, port);
        end;
        log-info("Adding HTTPS listener for %s:%d", address, port);
        add!(server.server-listeners,
             make(<ssl-listener>,
                  host: address,
                  port: port,
                  certificate-filename: cert,
                  key-filename: key));
      else
        let port = port | $default-http-port;
        log-info("Adding HTTP listener for %s:%d", address, port);
        add!(server.server-listeners, make(<listener>, host: address, port: port));
      end;
    exception (ex :: <serious-condition>)
      warn("Invalid <listener> spec: %s", ex);
    end;
  else
    warn("Invalid <listener> spec.  You must supply at least one "
         "of 'address' or 'port'.");
  end;
end method process-config-element;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"virtual-host")
  let name = get-attr(node, #"name");
  if (name)
    let vhost = make-virtual-host(server, name: trim(name));
    add-virtual-host(server, vhost, name);
    dynamic-bind (%vhost = vhost,
                  %dir = root-directory-policy(vhost))
      for (child in xml$node-children(node))
        process-config-element(server, child, xml$name(child))
      end;
    end;
  else
    warn("Invalid <VIRTUAL-HOST> spec.  "
           "The 'name' attribute must be specified.");
  end;
end;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"host-alias")
  let name = get-attr(node, #"name");
  if (name)
    block ()
      add-virtual-host(server, %vhost, name);
    exception (err :: <koala-api-error>)
      warn("Invalid <HOST-ALIAS> element.  %s", err);
    end;
  else
    warn("Invalid <HOST-ALIAS> element.  The 'name' attribute must be specified.");
  end;
end;

// I considered making this and debug-server be attributes on the
// top-level <koala> element, but then it's impossible to turn on
// logging first in a general way.
define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"default-virtual-host")
  bind (attr = get-attr(node, #"enabled"))
    when (attr)
      server.fall-back-to-default-virtual-host? := true-value?(attr)
    end;
    when (server.fall-back-to-default-virtual-host?)
      log-info("Fallback to the default virtual host is enabled.");
    end;
  end;
end;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"debug-server")
  bind (attr = get-attr(node, #"value"))
    when (attr)
      server.debugging-enabled? := true-value?(attr);
    end;
    when (server.debugging-enabled?)
      warn("Server debugging is enabled.  "
           "Server may crash if not run inside an IDE!");
    end;
  end;
end;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"server-root")
  if (%vhost == server.default-virtual-host)
    let loc = get-attr(node, #"location");
    if (loc)
      server.server-root
        := merge-locators(as(<directory-locator>, loc), server.server-root);
      log-info("Server root set to %s", loc);
    else
      config-error("Invalid <SERVER-ROOT> spec.  "
                   "The 'location' attribute must be specified.");
    end;
  else
    warn("The <SERVER-ROOT> element is only valid at top-level "
           "(inside the <KOALA> element) in the koala config file.  "
           "It will be ignored.");
  end;
end;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"document-root")
  bind (loc = get-attr(node, #"location"))
    if (loc)
      document-root(%vhost)
        := merge-locators(as(<directory-locator>, loc), server.server-root);
      log-info("Document root for virtual host %s: %s",
               vhost-name(%vhost), document-root(%vhost));
    else
      warn("Invalid <DOCUMENT-ROOT> spec.  "
           "The 'location' attribute must be specified.");
    end if;
  end;
end;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"dsp-root")
  bind (loc = get-attr(node, #"location"))
    if (loc)
      %vhost.dsp-root := merge-locators(as(<directory-locator>, loc), 
                                        server.server-root);
      log-info("DSP root for virtual host %s: %s",
               vhost-name(%vhost), dsp-root(%vhost));
    else
      warn("Invalid <DSP-ROOT> spec.  "
           "The 'location' attribute must be specified.");
    end if;
  end;
end;


// The main thing this controls right now is whether check template modification
// dates and reparse them if needed.
//
define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"development-mode")
  let enabled? = get-attr(node, #"enabled");
  let enabled? = enabled? & true-value?(enabled?);
  server.development-mode? := enabled?;
  log-warning("Development mode is %s.",
              if (enabled?) "on" else "off" end);
end method process-config-element;


// TODO: There is currently no way to configure (for example) the
//       "http.common.headers" logger.  We should really just have one
//       configuration element, <log>, that names a logger that exists
//       in the code and says how to configure it.  The loggers for each
//       virtual host should be named <vhost-name>.debug etc.  Needs more
//       thought, but I think it will be an improvement.

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"error-log")
  let format-control = get-attr(node, #"format");
  let name = get-attr(node, #"name") | "http.server.error";
  let logger = process-log-config-element(server, node, format-control, name,
                                          $stderr-log-target);
  error-logger(%vhost) := logger;
  *error-logger* := logger;
end method process-config-element;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"debug-log")
  let format-control = get-attr(node, #"format");
  let name = get-attr(node, #"name") | "http.server.debug";
  let logger = process-log-config-element(server, node, format-control, name,
                                          $stdout-log-target);
  debug-logger(%vhost) := logger;
  *debug-logger* := logger;
end method process-config-element;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"request-log")
  let format-control = get-attr(node, #"format") | "%{message}";
  let name = get-attr(node, #"name") | "http.server.request";
  let logger = process-log-config-element(server, node, format-control, name,
                                          $stdout-log-target);
  request-logger(%vhost) := logger;
  *request-logger* := logger;
end method process-config-element;

define function process-log-config-element
    (server :: <http-server>, node :: xml$<element>,
     format-control, logger-name :: <string>, default-log-target :: <log-target>)
 => (logger :: <logger>)
  let additive? = true-value?(get-attr(node, #"additive") | "no");
  let location = get-attr(node, #"location");
  let default-size = 20 * 1024 * 1024;
  let max-size = get-attr(node, #"max-size");
  if (max-size)
    block ()
      max-size := string-to-integer(max-size);
    exception (ex :: <error>)
      warn("<%s> element has invalid max-size attribute (%s).  "
           "The default (%d) will be used.",
           xml$name(node), max-size, default-size);
      max-size := default-size;
    end;
  else
    max-size := default-size;
  end if;
  let target = iff(location,
                   make(<rolling-file-log-target>,
                        pathname: merge-locators(as(<file-locator>, location),
                                                 server.server-root),
                        max-size: max-size),
                   default-log-target);
  let logger :: <logger>
    = get-logger(logger-name) | make(<logger>, name: logger-name);
  logger.logger-additive? := additive?;
  if (format-control)
    logger.log-formatter := make(<log-formatter>, pattern: format-control);
  end;
  remove-all-targets(logger);  // TODO: make this optional
  add-target(logger, target);

  let unrecognized = #f;
  let level-name = get-attr(node, #"level") | "info";
  let level = select (level-name by string-equal?)
                "trace" => $trace-level;
                "debug" => $debug-level;
                "info"  => $info-level;
                "warn", "warning", "warnings" => $warn-level;
                "error", "errors" => $error-level;
                otherwise =>
                  unrecognized := #t;
                  $info-level;
              end;
  log-level(logger) := level;
  if (unrecognized)
    warn("Unrecognized log level: %=", level);
  end;
  log-info("Logger created: %s", logger);
  logger
end function process-log-config-element;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"administrator")
  // ---TODO:
end;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"module")
  bind (name = get-attr(node, #"name"))
    if (name)
      load-module(name);
    end;
  end;
end;

define class <mime-type> (xml$<xform-state>)
  constant slot mime-type-map :: <table>,
    required-init-keyword: mime-type-map:;
end class <mime-type>;

define method xml$transform
    (node :: xml$<element>, state :: <mime-type>)
  if (xml$name(node) = #"mime-type")
    let mime-type = get-attr(node, #"id");
    let mime-type-map = state.mime-type-map;
    for (child in xml$node-children(node))
      if (xml$name(child) = #"extension")
        mime-type-map[as(<symbol>, xml$text(child))] := mime-type;
      else
        warn("Skipping: %s %s %s: not an extension node!",
             mime-type, xml$name(child), xml$text(child));
      end if;
    end for;
  else
    next-method();
  end if;
end method xml$transform;


define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"mime-type-map")
  let filename = get-attr(node, #"location");
  let mime-type-loc
    = as(<string>,
         merge-locators(merge-locators(as(<file-locator>, filename),
                                       as(<directory-locator>, $koala-config-dir)),
                        server.server-root));
  log-info("Loading mime-type map from %s", mime-type-loc);
  let mime-text = file-contents(mime-type-loc);
  if (mime-text)
    let mime-xml :: xml$<document> = xml$parse-document(mime-text);
    let clear = get-attr(node, #"clear");
    if (clear & true-value?(clear))
      log-info("Clearing default mime type mappings.");
      remove-all-keys!(server.server-mime-type-map);
    end;
    with-output-to-string (stream)
      dynamic-bind (%server = server)
        // Transforming the document side-effects the server's mime type map.
        xml$transform(mime-xml, make(<mime-type>,
                                     stream: stream,
                                     mime-type-map: server.server-mime-type-map));
      end;
    end;
  else
    warn("mime-type map %s not found", mime-type-loc);
  end if;
end method process-config-element;

define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"alias")
  let url = get-attr(node, #"url");
  let target = get-attr(node, #"target");
  if (~url)
    warn("Invalid alias; the 'url' attribute is required.");
  end;
  if (~target)
    warn("Invalid alias; the 'target' attribute is required.");
  end;
  add-alias-responder(server, url, target);
end method process-config-element;

// Add an alias that maps all URLs starting with url-path to the target path.
// For example:
//   add-alias-responder("/bugs/", "https://foo.com/bugzilla/")
// will redirect a request for /bugs/123 to https://foo.com/bugzilla/123.
// The redirection is implemented by issuing a 301 (moved permanently
// redirect) response.
define function add-alias-responder
    (store :: type-union(<string-trie>, <http-server>),
     url-path :: <string>, target :: <string>, #key request-methods)
  add-responder(store, url-path,
                make-responder(list(request-methods | #(get:, post:),
                                    "^(?P<tail>.*)$",
                                    curry(alias-responder, target))));
end;

define function alias-responder
    (target :: <string>, #key tail :: <string>)
  let location = concatenate(target, tail);
  moved-permanently-redirect(location: location,
                             header-name: "Location",
                             header-value: location);
end function alias-responder;

// <directory  url = "/"
//             location = "/some/filesystem/path"
//             allow-directory-listing = "no"
//             allow-static = "no"
//             allow-cgi = "no"
//             cgi-extensions = "cgi,bat,exe,..."
//             follow-symlinks = "no"
//             default-documents = "index.html,index.htm"
//             />
define method process-config-element
    (server :: <http-server>, node :: xml$<element>, name == #"directory")
  let url = get-attr(node, #"url");
  if (~url)
    warn("Invalid <DIRECTORY> spec.  The 'pattern' attribute is required.");
  else
    let path = get-attr(node, #"location");
    let dirlist? = get-attr(node, #"allow-directory-listing");
    let static? = get-attr(node, #"allow-static");
    let follow? = get-attr(node, #"follow-symlinks");
    let cgi? = get-attr(node, #"allow-cgi");
    let cgi-ext = get-attr(node, #"cgi-extensions") | "cgi";
    cgi-ext := map(trim, split(trim(cgi-ext), ','));
    let root-policy = root-directory-policy(%vhost);
    let index = get-attr(node, #"default-documents");
    let indexes = iff(index,
                      map(curry(as, <file-locator>), split(index, ",")),
                      root-policy.policy-default-documents);
    // TODO: the default value for these should really
    //       be taken from the parent policy rather than from root-policy.
    let policy = make(<directory-policy>,
                      url-path: url,
                      directory: iff(path,
                                     as(<directory-locator>, path),
                                     apply(subdirectory-locator,
                                           document-root(%vhost),
                                           uri-path(parse-url(url)))),
                      allow-static?: iff(static?,
                                         true-value?(static?),
                                         allow-static?(root-policy)),
                      follow-symlinks?: iff(follow?,
                                            true-value?(follow?),
                                            follow-symlinks?(root-policy)),
                      allow-directory-listing?: iff(dirlist?,
                                                    true-value?(dirlist?),
                                                    allow-directory-listing?(root-policy)),
                      allow-cgi?: iff(cgi?,
                                      true-value?(cgi?),
                                      allow-cgi?(root-policy)),
                      cgi-extensions: cgi-ext,
                      default-documents: indexes);
    add-directory-policy(%vhost, policy);
    dynamic-bind (%dir = policy)
      for (child in xml$node-children(node))
        process-config-element(server, child, xml$name(child));
      end;
    end;
  end;
end method process-config-element;


// RFC 2616 Section 15.1.2
// Implementors SHOULD make the Server header field a configurable option.
define method process-config-element
    (server :: <http-server>,
     node :: xml$<element>,
     name == #"server-header")
  let value = get-attr(node, #"value");
  if (~value)
    warn("Invalid <server-header> spec.  The 'value' attribute "
           "must be specified.");
  else
    server-header(server) := value;
  end;
end method process-config-element;
    


// TODO:
// <default-document>index.html</default-document>
// <response>301</response>???

