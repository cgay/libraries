Module:    httpi
Synopsis:  Tools for mapping URLs to available resources
Author:    Carl Gay
Copyright: Copyright (c) 2001-2010 Carl L. Gay.  All rights reserved.
           Original Code is Copyright (c) 2001 Functional Objects, Inc.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND


//// Resource protocol

// An <abstract-resource> is responsible for setting headers on and
// writing data to the current <response> by overriding the "respond"
// method or one of the "respond-to-{get,put,...}"
// methods. <resource>s are arranged in a tree structure.
//
define open abstract class <abstract-resource> (<object>)
end;

// Respond to a request for the given resource.
define open generic respond
    (resource :: <abstract-resource>, #key, #all-keys);


// Is it okay to add child resources via an absolute URL path?
// This is needed for <virtual-host-resource>, which has a
// parent resource but allows absolute paths for its children.
define open generic root-resource?
    (resource :: <abstract-resource>) => (root? :: <boolean>);


// This method is called if the request URL has leftover path elements after
// all path variables have been bound.  It gives the resource implementation
// a chance to signal 404, for example.  In many applications you might want
// to do this (at least during development or QA) so that incorrect URLs can
// be discovered quickly.
define open generic unmatched-url-suffix
    (resource :: <abstract-resource>, unmatched-path :: <sequence>);

define method unmatched-url-suffix
    (resource :: <abstract-resource>, unmatched-path :: <sequence>)
  log-debug("Unmatched URL suffix for resource %s: %s",
            resource, unmatched-path);
  resource-not-found-error();
end;


// Pre-defined request methods each have a specific generic...

define open generic respond-to-options (resource :: <abstract-resource>, #key, #all-keys);
define open generic respond-to-get     (resource :: <abstract-resource>, #key, #all-keys);
define open generic respond-to-head    (resource :: <abstract-resource>, #key, #all-keys);
define open generic respond-to-post    (resource :: <abstract-resource>, #key, #all-keys);
define open generic respond-to-put     (resource :: <abstract-resource>, #key, #all-keys);
define open generic respond-to-delete  (resource :: <abstract-resource>, #key, #all-keys);
define open generic respond-to-trace   (resource :: <abstract-resource>, #key, #all-keys);
define open generic respond-to-connect (resource :: <abstract-resource>, #key, #all-keys);

// The content type that will be sent in the HTTP response if no
// Content-Type header is set by the respond* method.
//
define open generic default-content-type
    (resource :: <abstract-resource>)
 => (content-type :: <mime-type>);

define constant application/octet-stream :: <mime-type>
  = make(<mime-type>, type: "application", subtype: "octet-stream");

define method default-content-type
    (resource :: <abstract-resource>)
 => (content-type :: <mime-type>)
  application/octet-stream
end;



//// <resource> -- the default resource implementation

// <resource>s are <abstract-router>s because they route requests to
// their children.  That is, there are methods for add-resource and
// find-resource.
define open class <resource> (<abstract-resource>, <abstract-router>)
  constant slot resource-children :: <string-table> = make(<string-table>);

  // This holds the child names (the keys of resource-children) in the order
  // in which they were added.  If a resource is added under multiple names
  // the first one is "canonical", and is used in URL generation.  (An ordered
  // hash table would be nice here....)
  constant slot resource-order :: <stretchy-vector> = make(<stretchy-vector>);

  // The parent is used for URL to find the full URL path (for url generation).
  // Even though there may be multiple URLs that map to the same resource
  // each resource only has a single parent.  The idea is that you should
  // add the URL under its "canonical" name first, and that will be the one
  // generated.
  slot resource-parent :: false-or(<resource>) = #f;

  // If add-resource was called with URL /page/view/{title}/{version} then
  // this would be set to #(title:, version:) to indicate that those keywords
  // should be passed to the respond* methods with the corresponding values
  // from the request URL suffix, if available.  They are also used in URL
  // generation.  When a link is generated with f(... title: "t", version: "v")
  // this slot tells us where those arguments fit into the URL by virtue of
  // the fact that its elements are ordered.  See unmatched-url-suffix.
  //
  slot resource-path-variables :: <sequence> = #();

end class <resource>;

define method root-resource?
    (resource :: <resource>) => (root? :: <boolean>)
  ~resource.resource-parent
end;

// Used for internal book-keeping.
define class <placeholder-resource> (<resource>)
end;


//// add-resource

// Add a route (path) to a resource.  The 'url' parameter accepts a string or
// sequence of strings that indicate the path portion of a URL relative to the
// parent's path.  For example if the parent resource is mapped to "/foo"...
//
//    given url         child is mapped to
//    ---------         ------------------
//    "bar"             /foo/bar
//    ""                /foo/
//    "x/y"             /foo/x/y
//    #("x", "y")       /foo/x/y
//
// The "url-name" parameter can be used to give a (global) name to the
// URL which can be used for URL generation (to avoid hard-coding URLs
// into the application).  See generate-url.
//
// The "trailing-slash" parameter determines what, if anything, to do
// for the given path with a trailing slash appended to it.  
//

// convert <uri> to <sequence>
define method add-resource
    (router :: <resource>, url :: <uri>, child :: <abstract-resource>,
     #rest args, #key)
  log-debug("add-resource(%=, %=, %=)", router, url, child);
  // The root URL, "/", is a special case because it is both a leading
  // and trailing slash, which doesn't match our resource tree structure.
  // There is a corresponding hack in find-resource.
  let path = url.uri-path;
  apply(add-resource, router, iff(path = #("", ""), #(""), path), child, args)
end;

// convert <http-server> to <abstract-router>
define method add-resource
    (server :: <http-server>, url :: <object>, resource :: <abstract-resource>,
     #rest args, #key)
  log-debug("add-resource(%=, %=, %=)", server, url, resource);
  apply(add-resource, server.request-router, url, resource, args);
end;

// "url" is either a single path element or a full URL path.
define method add-resource
    (parent :: <resource>, url :: <string>, child :: <resource>,
     #key url-name :: false-or(<string>),
          trailing-slash: trailing-slash)
  log-debug("add-resource(%=, %=, %=)", parent, url, child);
  if (member?('/', url))
    // The root URL, "/", is a special case because it is both a leading
    // and trailing slash, which doesn't match our resource tree structure.
    // There is a corresponding hack in find-resource.
    let path = iff(url = "/", list(""), split(url, '/'));
    add-resource(parent, path, child,
                 url-name: url-name,
                 trailing-slash: trailing-slash);
  elseif (path-variable?(url))
    koala-api-error("Attempt to call add-resource with a path "
                    "variable (%=) as the URL.", url);
  else
    let name = url;
    let existing-child = element(parent.resource-children, name, default: #f);
    if (existing-child)
      if (instance?(existing-child, <placeholder-resource>))
        for (kid keyed-by kid-name in existing-child.resource-children)
          // Do this recursively to check for duplicate names.
          // Do not pass the url-name argument.
          add-resource(child, kid-name, kid, trailing-slash: #f);
        end;
      else
        koala-api-error("A child resource, %=, is already mapped "
                        "to this URL: %s",
                        existing-child, existing-child.resource-url-path);
      end;
    else
      parent.resource-children[name] := child;
      add!(parent.resource-order, name);
      if (~child.resource-parent)
        child.resource-parent := parent;
      end;
      if (trailing-slash & name ~= "")
        // The caller passed url foo and wants foo/ mapped as well.
        add-resource(child, "", child);
      end;
      if (url-name)
        // TODO: add a way to specify whether the url with or without
        //       a trailing slash should be canonical (i.e., generated).
        add-resource-name(url-name, child);
      end;
    end;
  end;
end method add-resource;

// "path" is a sequence of URL path elements (strings). 
define method add-resource
    (parent :: <resource>, path :: <sequence>, resource :: <resource>,
     #key url-name, trailing-slash)
  log-debug("add-resource(%=, %=, %=)", parent, path, resource);
  if (empty?(path))
    koala-api-error("Empty sequence, %=, passed to add-resource.", path);
  elseif (path[0] = "" & ~parent.root-resource?)
    koala-api-error("Attempt to add resource %= to non-root resource"
                    " %= using a URL with a leading slash %=.  This"
                    " will result in an unreachable URL path.",
                    resource, parent, join(path, "/"));
  else
    let (prefix, vars) = parse-path-variables(path);
    resource.resource-path-variables := vars;
    iterate loop (parent = parent, path = prefix)
      if (empty?(path))
        // done
      elseif (path.size = 1)
        let name :: <string> = first(path);
        add-resource(parent, name, resource,
                     url-name: url-name,
                     trailing-slash: trailing-slash)
      else
        let name :: <string> = first(path);
        let child = element(parent.resource-children, name, default: #f);
        if (~child)
          child := make(<placeholder-resource>);
          add-resource(parent, name, child, trailing-slash: #f, url-name: #f);
        end;
        loop(child, rest(path))
      end if;
    end iterate;
  end if;
end method add-resource;


//// path variables

//   "{v}"     => <path-variable> (required)
//   "{v?}"    => <path-variable> (optional)
//   "{v*}"    => <star-path-variable> (matches zero or more path elements)
//   "{v+}"    => <plus-path-variable> (matches one or more path elements)

// {v} or {v?}
define sealed class <path-variable> (<object>)
  constant slot path-variable-name :: <symbol>,
    required-init-keyword: name:;
  constant slot path-variable-required? :: <boolean>,
    required-init-keyword: required?:;
end;

// {v*}
define sealed class <star-path-variable> (<path-variable>) end;

// {v+}
define sealed class <plus-path-variable> (<path-variable>) end;

define function parse-path-variables
    (path :: <sequence>) => (prefix :: <sequence>, vars :: <sequence>)
  let index = find-key(path, path-variable?) | path.size;
  let path-vars = as(<list>, copy-sequence(path, start: index));
  let path-prefix = as(<list>, copy-sequence(path, end: index));
  let vars = map(parse-path-variable, path-vars);

  // disallow {v*} or {v+} except at the end of the path.
  for (item in copy-sequence(vars, end: max(0, vars.size - 1)))
    if (instance?(item, <star-path-variable>)
          | instance?(item, <plus-path-variable>))
      koala-api-error("Path variables of the form \"{var*}\" or \"{var+}\""
                      " may only occur as the last element in the URL path."
                      " URL: %s",
                      join(path, "/"));
    end;
  end;

  values(path-prefix, vars)
end function parse-path-variables;

define function parse-path-variable
    (path-element :: <string>) => (var :: <path-variable>)
  if (path-variable?(path-element))
    let spec = copy-sequence(path-element, start: 1, end: path-element.size - 1);
    if (spec.size = 1)
      make(<path-variable>, name: as(<symbol>, spec), required?: #t)
    else
      let modifier = spec[spec.size - 1];
      let class = <path-variable>;
      let required? = #t;
      select (modifier by \=)
        '?' => required? := #f;
        '*' => class := <star-path-variable>;
               required? := #f;
        '+' => class := <plus-path-variable>;
        otherwise => #f;
      end;
      if (member?(modifier, "?*+"))
        spec := copy-sequence(spec, end: spec.size - 1);
      end;
      make(class, name: as(<symbol>, spec), required?: required?)
    end
  else
    koala-api-error("%= is not a path variable.  All URL path elements"
                    " following the first path variable must also be path "
                    " variables.", path-element);
  end
end function parse-path-variable;

define function path-variable?
    (path-element :: <string>) => (path-variable? :: <boolean>)
  path-element.size > 2
    & path-element[0] = '{'
    & path-element[path-element.size - 1] = '}'
end;

// Make a sequence of key/value pairs for passing to respond(resource, #key)
//
define method path-variable-bindings
    (resource :: <resource>, path-suffix :: <list>)
 => (bindings :: <sequence>,
     unbound :: <sequence>,
     leftover-suffix :: <list>)
  let bindings = make(<stretchy-vector>);
  log-debug("pvars = %s", resource.resource-path-variables);
  for (pvar in resource.resource-path-variables,
       suffix = path-suffix then rest(suffix))
    select (pvar by instance?)
      <star-path-variable> =>
        add!(bindings, pvar.path-variable-name);
        add!(bindings, suffix);
        suffix := #();
      <plus-path-variable> =>
        if (empty?(suffix))
          log-debug("plus var not there");
          resource-not-found-error();
        else
          add!(bindings, pvar.path-variable-name);
          add!(bindings, suffix);
          suffix := #();
        end;
      <path-variable> =>
        let path-element = iff(empty?(suffix), #f, first(suffix));
        if (pvar.path-variable-required? & ~path-element)
          log-debug("pvar required but not there.");
          resource-not-found-error();
        else
          add!(bindings, pvar.path-variable-name);
          add!(bindings, path-element);
        end;
    end select;
    log-debug("suffix = %s", suffix);
  finally
    log-debug("suffix finally = %s", suffix);
    values(bindings,
           copy-sequence(resource.resource-path-variables,
                         start: floor/(bindings.size, 2)),
           suffix)
  end
end method path-variable-bindings;


define open generic do-resources
    (router :: <abstract-router>, function :: <function>, #key seen);

define method do-resources
    (router :: <resource>, function :: <function>,
     #key seen :: <list> = #())
  // It's perfectly normal to add a resource in multiple places
  // so just skip the ones we've seen before.
  if (~member?(router, seen))
    if (~instance?(router, <placeholder-resource>))
      function(router);
    end;
    for (child in router.resource-children)
      do-resources(child, function, seen: pair(router, seen));
    end;
  end;
end method do-resources;


//// find-resource

// convert <request> to <uri>
define method find-resource
    (router :: <abstract-router>, request :: <request>)
 => (resource :: <abstract-resource>, prefix :: <list>, suffix :: <list>)
  log-debug("find-resource(%=, %=)", router, request);
  find-resource(router, request.request-url)
end;

// convert <http-server> to <resource>
define method find-resource
    (server :: <http-server>, path :: <object>)
 => (resource :: <abstract-resource>, prefix :: <list>, suffix :: <list>)
  log-debug("find-resource(%=, %=)", server, path);
  find-resource(server.request-router, path)
end;

// convert <uri> to <sequence>
define method find-resource
    (router :: <resource>, uri :: <uri>)
 => (resource :: <resource>, prefix :: <list>, suffix :: <list>)
  log-debug("find-resource(%=, %=)", router, uri);
  // Special case the root path, "/", which is both a leading and
  // trailing slash, which doesn't match our resource tree structure.
  // There's a similar special case for add-resource.
  let path = iff(uri.uri-path = #("", ""), list(""), uri.uri-path);
  find-resource(router, path)
end;

// convert <string> to <sequence>
define method find-resource
    (router :: <resource>, path :: <string>)
 => (resource :: <resource>, prefix :: <list>, suffix :: <list>)
  log-debug("find-resource(%=, %=)", router, path);
  find-resource(router, split(path, '/'))
end;

// The base method.  Deeper (more specific) resources are preferred.
define method find-resource
    (router :: <resource>, path :: <sequence>)
 => (resource :: <resource>, prefix :: <list>, suffix :: <list>)
  log-debug("find-resource(%=, %=)", router, path);
  let resource = #f;
  let prefix = #();
  let suffix = #();
  iterate loop (parent = router, path = as(<list>, path), seen = #())
    if (~empty?(path))
      let key = first(path);
      let child = element(parent.resource-children, key, default: #f);
      if (child)
        if (~instance?(child, <placeholder-resource>))
          resource := child;
          prefix := pair(key, seen);
          suffix := rest(path);
        end;
        loop(child, rest(path), pair(key, seen))
      end;
    end;
  end;
  if (resource)
    values(resource, reverse(prefix), suffix)
  else
    resource-not-found-error();
  end;
end method find-resource;


//// URL generation

// TODO: store this in the request router
define constant $named-resources :: <string-table> = make(<string-table>);

define open generic add-resource-name
    (name :: <string>, resource :: <resource>);

define method add-resource-name
    (name :: <string>, resource :: <resource>) => ()
  if (element($named-resources, name, default: #f))
    koala-api-error("Duplicate URL name: %s (resource = %s)", name, resource);
  else
    $named-resources[name] := resource;
  end;
end;

define method generate-url
    (router :: <resource>, name :: <string>, #key)
 => (url :: <string>)
  let resource = element($named-resources, name, default: #f);
  if (resource)
    // TODO: generate a full url not just the path.
    resource.resource-url-path
  else
    koala-api-error("Named resource not found: %s", name);
  end;
end method generate-url;

// follow the resource parent chain to find the url path prefix
define function resource-url-path
    (resource :: <resource>, #key path-so-far = #())
 => (path :: <string>)
  local method find-first-added-name(parent, resource)
          let children = parent.resource-children;
          block (return)
            for (name in parent.resource-order)
              if (children[name] == resource)
                return(name)
              end;
            end;
            error("can't get here");
          end;
        end;
  let parent = resource.resource-parent;
  if (parent)
    let name = find-first-added-name(parent, resource);
    resource-url-path(parent, path-so-far: pair(name, path-so-far))
  elseif (empty?(path-so-far))
    "/"
  else
    join(path-so-far, "/")
  end
end function resource-url-path;



define method respond-to-options
    (resource :: <abstract-resource>, #key)
  let request :: <request> = current-request();
  if (request.request-raw-url-string = "*")
    set-header(current-response(),
               "Allow",
               "GET, HEAD, OPTIONS, POST, PUT, DELETE, TRACE, CONNECT");
  else
    let methods = find-request-methods(resource);
    if (~empty?(methods))
      set-header(current-response(),
                 "Allow",
                 join(methods, ", ", key: as-uppercase))
    end;
  end;
end method respond-to-options;

define inline function %method-not-allowed
    ()
  method-not-allowed-error(
    request-method: as-uppercase(as(<string>,
                                    request-method(current-request()))));
end;

define method respond-to-get
    (resource :: <abstract-resource>, #key)
  %method-not-allowed();
end;

define method respond-to-head
    (resource :: <abstract-resource>, #key)
  %method-not-allowed()
end;

define method respond-to-post
    (resource :: <abstract-resource>, #key)
  %method-not-allowed()
end;

define method respond-to-put
    (resource :: <abstract-resource>, #key)
  %method-not-allowed()
end;

define method respond-to-delete
    (resource :: <abstract-resource>, #key)
  %method-not-allowed()
end;

define method respond-to-trace
    (resource :: <abstract-resource>, #key)
  %method-not-allowed()
end;

define method respond-to-connect
    (resource :: <abstract-resource>, #key)
  %method-not-allowed()
end;

define table $request-method-table = {
    #"options" => respond-to-options,
    #"get"     => respond-to-get,
    #"head"    => respond-to-head,
    #"post"    => respond-to-post,
    #"put"     => respond-to-put,
    #"delete"  => respond-to-delete,
    #"trace"   => respond-to-trace,
    #"connect" => respond-to-connect,
    };

// TODO: a way to add new request methods

define method respond
    (resource :: <placeholder-resource>, #key)
  resource-not-found-error();
end;

// Default method dispatches to respond-to-<request-method> functions.
define method respond
    (resource :: <abstract-resource>, #rest args, #key)
  let request :: <request> = current-request();
  let function = element($request-method-table, request.request-method,
                         default: #f);
  if (function)
    apply(function, resource, args);
  else
    // It's an extension method and there's no "respond" method for
    // the resource.
    %method-not-allowed()
  end;
end;

define method find-request-methods
    (resource :: <abstract-resource>) => (methods :: <collection>)
  #()  // TODO: determine request methods for OPTIONS request
end;



//// Redirecting resources

// A resource that redirects requests to another location.  If /a/b/c/d
// is requested and this resource is matched to /a/b, and the target is
// /x/y, then the request is redirected to /x/y/c/d.  The redirection
// is implemented by issuing a 301 (moved permanently redirect) response.
//
define class <redirecting-resource> (<resource>)
  constant slot resource-target :: <uri>,
    required-init-keyword: target:;
end;

define method respond
    (resource :: <redirecting-resource>, #key)
  let target :: <uri> = resource.resource-target;
  let suffix :: <string> = request-url-path-suffix(current-request());
  if (suffix.size > 0 & suffix[0] = '/')
    suffix := copy-sequence(suffix, from: 1);
  end;
  let path = iff(empty?(suffix), #(), split(suffix, '/'));
  let location = build-uri(make(<uri>,
                                path: concatenate(target.uri-path, path),
                                copy-from: target));
  moved-permanently-redirect(location: location,
                             header-name: "Location",
                             header-value: location);
end method respond;



//// Function resources

// A resource that simply calls a function.  The function must accept
// only keyword arguments, one for each path variable it expects.
//
define open class <function-resource> (<resource>)
  constant slot resource-function,
    required-init-keyword: function:;

  // Since this is a raw function responder, there's nothing to dispatch
  // on so it needs a way to specify which request methods to respond to.
  //
  constant slot resource-request-methods :: <collection> = #(#"get", #"post"),
    init-keyword: methods:;

end;

// Turn a function into a resource.
//
define function function-resource
    (function :: <function>, #key methods) => (resource :: <resource>)
  make(<function-resource>,
       function: function,
       methods: methods | #(#"get", #"post"))
end;

define method respond
    (resource :: <function-resource>, #rest path-bindings, #key)
  if (member?(request-method(current-request()),
              resource.resource-request-methods))
    apply(resource.resource-function, path-bindings);
  end;
end;

