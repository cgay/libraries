Module: dylan-user
Synopsis: Code shared by HTTP client and server

define library http-common
  use base64;
  use common-dylan,
    import: { dylan, common-extensions, threads, simple-random };
  use functional-dylan,
    import: { dylan-extensions };
  use io,
    import: { format, standard-io, streams };
  use logging;
  use system,
    import: { date, file-system, locators, operating-system };
  use strings;
  use uncommon-dylan;
  use uri;
  export http-common;
end library http-common;

define module http-common
  use base64;
  use common-extensions,
    exclude: { format-to-string };
  use date;
  use dylan;
  use dylan-extensions,
    import: { element-no-bounds-check,
              element-no-bounds-check-setter,
              element-range-check,
              element-range-error,
              // make-symbol,
              // case-insensitive-equal,
              // case-insensitive-string-hash
              <format-string-condition>
              };
  use file-system,
    import: { with-open-file,
              <file-does-not-exist-error>,
              <pathname> };
  use format;
  use locators,
    import: { <locator>,
              <file-locator>,
              <directory-locator>,
              locator-directory,
              simplify-locator,
              subdirectory-locator
              };
  use logging;
  use standard-io;
  use streams;
  use strings;
  use threads;
  use uncommon-dylan;
  use uri;

  export
    // Things that expire
    <expiring-mixin>,
    expired?,
    date-modified,
    date-modified-setter,

    // Thing with attributes
    <attributes-mixin>,
    get-attribute,
    set-attribute,
    remove-attribute,

    quote-html,

    // Request objects
    <base-http-request>,
    request-content,
    request-content-setter,
    request-method,
    request-method-setter,          // todo -- remove this export
    request-raw-url-string,
    request-raw-url-string-setter,  // todo -- remove this export
    request-url,
    request-url-setter,             // todo -- remove this export
    request-version,
    request-version-setter,         // todo -- remove this export

    // Response objects
    <base-http-response>,
    response-code,
    response-code-setter,
    response-reason-phrase,
    response-reason-phrase-setter,
    response-request,

    // Errors and redirects
    <http-error>,
    <http-redirect-error>, // 3xx
    <http-client-error>,   // 4xx
    <http-server-error>,   // 5xx
      <internal-server-error>, // 500
    http-error-code,
    http-error-headers,
    http-error-message-no-code,   // get rid of this, use condition-to-string

    access-forbidden-error,           $access-forbidden-error,
    application-error,                $application-error,
    bad-header-error,                 $bad-header-error,
    bad-request,                      $bad-request,
    content-length-required-error,    $content-length-required-error,
    header-too-large-error,           $header-too-large-error,
    internal-server-error,            $internal-server-error,
    method-not-allowed,               $method-not-allowed,
    moved-permanently-redirect,       $moved-permanently-redirect,
    moved-temporarily-redirect,       $moved-temporarily-redirect,
    not-implemented-error,            $not-implemented-error,
    not-modified,                     $not-modified,
    request-entity-too-large-error,   $request-entity-too-large-error,
    resource-not-found-error,         $resource-not-found-error,
    see-other-redirect,               $see-other-redirect,
    unauthorized-error,               $unauthorized-error,
    unsupported-http-version-error,   $unsupported-http-version-error,
    unsupported-media-type-error,     $unsupported-media-type-error,

    // Parsing
    token-end-position,
    validate-http-version,
    validate-http-status-code,

    // Headers
    <header-table>,
    add-header,  // should probably be set-header, for symmetry with get-header.
    get-header,
    read-message-headers,
    raw-headers,
    parsed-headers,

    // lower level header APIs...
    read-header-line,
    read-http-line,
    parse-header-value,
    grow-header-buffer,

    // Cookies
    cookie-name,
    cookie-value,
    cookie-domain,
    cookie-path,
    cookie-max-age,
    cookie-comment,
    cookie-version,
    $default-cookie-version;   // get rid of this

end module http-common;

