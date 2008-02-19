Module:    httpi
Synopsis:  header fields values parsing
Author:    Gail Zacharias
Copyright: Original Code is Copyright (c) 2001 Functional Objects, Inc.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND


define inline function trimmed-substring (str :: <byte-string>,
                                          bpos :: <integer>,
                                          epos :: <integer>)
  let (b, e) = trim-whitespace(str, bpos, epos);
  b < e & substring(str, b, e)
end;

define inline function trimmed-string->integer
    (str :: <byte-string>, bpos :: <integer>, epos :: <integer>)
  let (b, e) = trim-whitespace(str, bpos, epos);
  (b < e) & string->integer(str, b, e)
end;

define function token-or-qstring (str :: <byte-string>,
                                  bpos :: <integer>,
                                  epos :: <integer>)
  let (bpos, epos) = trim-whitespace(str, bpos, epos);
  let b = bpos + 1;
  let e = epos - 1;
  let strlen = e - b;
  if (strlen >= 0 & str[bpos] == '"' & str[e] == '"')
    iterate count (pos = b, len = strlen)
      let pos = char-position('\\', str, pos, e);
      if (pos)
        pos + 1 < e | bad-header-error();
        count(pos + 2, len - 1);
      elseif (len == strlen)
        substring(str, b, e)
      else
        let new = make(<byte-string>, size: len);
        iterate copy (i = 0, pos = b)
          unless (pos == e)
            let c = str[pos];
            copy(i + 1,
                 if (c == '\\') new[i] := str[pos + 1]; pos + 2
                 else new[i] := c; pos + 1 end)
          end;
          new
        end iterate /* copy */;
      end
    end iterate /* count */;
  else
    substring(str, bpos, epos)
  end;
end token-or-qstring;

// Note: to covert qvalue back to integer, use round(f * 1000), not
// floor. floor gives wrong results for 251, 253, 502, 506 and 511.
define function quality-value (str :: <byte-string>,
                               bpos :: <integer>,
                               epos :: <integer>)
  => (value :: false-or(/* limited(<float>, min: 0.0, max: 1.0) */ <float>))
  when (bpos < epos & epos <= bpos + 5)
    let val = as(<integer>, str[bpos]) - as(<integer>, '0');
    let pos = bpos + 1;
    when ((val == 0 | val == 1) & (pos == epos | str[pos] == '.'))
      iterate a2f (pos = pos + 1, val = val, rep = 3)
        if (rep == 0)
          when (val <= 1000)
            val / 1000.0
          end;
        else
          let n = if (pos < epos)
                    as(<integer>, str[pos]) - as(<integer>, '0')
                  else
                    0
                  end;
          0 <= n & n <= 9 & a2f(pos + 1, rep * 10 + n, rep - 1)
        end;
      end iterate;
    end;
  end
end;

  
define function parse-header (data) => (str :: <string>)
  if (instance?(data, <pair>))
    reduce(method (so-far :: <string>, datum :: <string>)
             if (empty?(datum))
               so-far
             elseif (empty?(so-far))
               datum
             else
               concatenate(so-far, ", ", datum)
             end
           end,
           "",
           data)
  else
    data
  end;
end;


define function parse-comma-separated-values (data, parse-function :: <function>)
  => (values :: <list>)
  local method add-fields (so-far :: <list>, string :: <string>)
          let (str, bpos, epos) = string-extent(string);
          let result = #();
          iterate loop (bpos = bpos)
            let lim = iterate find-end (pos = bpos, quoted? = #f)
                        // note that pos > epos is possible from the '\\' case.
                        let ch = pos < epos & str[pos];
                        if (~quoted? & (ch == ',' | ch == #f)) pos
                        elseif (quoted? & ch == '\\') find-end(pos + 2, #t)
                        elseif (ch == '"') find-end(pos + 1, ~quoted?)
                        elseif (ch) find-end(pos + 1, quoted?)
                        else bad-header-error() end;
                      end;
            let (b, e) = trim-whitespace(str, bpos, lim);
            when (b < e)
              let val = parse-function(str, b, e);
              result := pair(val, result);
            end;
            lim == epos | loop(lim + 1);
          end iterate;
          concatenate!(so-far, reverse!(result))
        end;
  if (instance?(data, <list>))
    reduce(add-fields, #(), data)
  else
    add-fields(#(), data)
  end;
end;

define function parse-comma-separated-pairs (data, parse-function :: <function>)
  => (attribs :: <avalue>)
  make(<avalue>,
       value: #f,
       alist: as(<alist>, parse-comma-separated-values(data, parse-function)))
end;

define function parse-single-header (data, parse-function :: <function>)
  if (instance?(data, <list>))
    bad-header-error();
  else
    let (str, bpos, epos) = string-extent(data);
    parse-function(str, bpos, epos)
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// media-type ::= type:token "/" subtype:token *( ";" parameter )
// parameter  ::= attribute:token "=" value:token-or-quoted-string
// No linear whitespace between type and subtype nor between attribute and value.
// Appear in Accept: and Content-Type: header fields


//---TODO: should have a table of known attributes and how to parse them.
// e.g. "q" => qvalue, "max-age" => integer, etc.
define function extract-attribute+value (str :: <byte-string>,
                                         bpos :: <integer>,
                                         epos :: <integer>)
  => (attribute :: <string>, value :: <object>)
  let vpos = char-position('=', str, bpos, epos) | epos;
  let attrib = trimmed-substring(str, bpos, vpos);
  let value = vpos < epos & token-or-qstring(str, vpos + 1, epos);
  values(attrib, value)
end;

// Add a tagged-alist type, which has a "value" (aka tag) and "attributes",
// sort of like an xml object.

define function extract-attribute-value-alist (str :: <byte-string>,
                                               bpos :: <integer>,
                                               epos :: <integer>,
                                               separator :: <character>)
  => (alist :: <alist>)
  iterate loop (bpos = bpos, params = #())
    let bpos = skip-whitespace(str, bpos, epos);
    let lim = char-position(separator, str, bpos, epos) | epos;
    let params = if (bpos == lim)
                   params
                 else
                   let (attr, val) = extract-attribute+value(str, bpos, lim);
                   pair(pair(attr, val), params)
                 end;
    if (lim == epos)
      rev-as-alist(params)
    else
      loop(lim + 1, params)
    end;
  end iterate;
end extract-attribute-value-alist;

//  datum *(";" attribute:token [ "=" value:token-or-quoted-string ])
define function extract-parameterized-value (str :: <byte-string>,
                                             bpos :: <integer>,
                                             epos :: <integer>)
  => (datum :: <string>, params :: <alist>)
  let lim = char-position(';', str, bpos, epos) | epos;
  let datum = trimmed-substring(str, bpos, lim);
  let params = if (lim < epos)
                 extract-attribute-value-alist(str, lim + 1, epos, ';')
               else
                 $empty-alist
               end;
  values(datum, params)
end;

define function parse-parameterized-value (str :: <byte-string>,
                                           bpos :: <integer>,
                                           epos :: <integer>)
  => (value :: <avalue>)
  let (value, alist) = extract-parameterized-value(str, bpos, epos);
  make(<avalue>, value: value, alist: alist);
end;

//  value = (type . subtype)
define function parse-media-type (str :: <byte-string>,
                                  bpos :: <integer>,
                                  epos :: <integer>)
  => (media-type :: <avalue>)
  let (value, params) = extract-parameterized-value(str, bpos, epos);
  let (str, bpos, epos) = string-extent(value);
  let spos = char-position('/', str, bpos, epos);
  let (type, subtype) = if (spos)
                          values(trimmed-substring(str, bpos, spos),
                                 trimmed-substring(str, spos + 1, epos))
                        else
                          values(str, #f)
                        end;
  make(<avalue>, value: pair(type, subtype), alist: params)
end;

// accept-charset, accept-languages, TE
define function parse-quality-pair (str :: <byte-string>,
                                    bpos :: <integer>,
                                    epos :: <integer>)
  let (key, params) = extract-parameterized-value(str, bpos, epos);
  let val = if (empty?(params))
              1000
            elseif (params.size > 1 | ~string-equal?("q", params[0].head))
              bad-header-error();
            else
              let (str, b, e) = string-extent(params[0].tail);
              quality-value(str, b, e) | bad-header-error();
            end;
  pair(key, val)
end;

define function parse-authorization-value (str :: <byte-string>,
                                           bpos :: <integer>,
                                           epos :: <integer>)
  let dpos = whitespace-position(str, bpos, epos) | epos;
  let (b, e) = trim-whitespace(str, dpos, epos);

  if (string-match("Basic", str, bpos, dpos))
    // base64 encoding of userid:password.  Should decode and return
    // (userid . password).  or maybe avalue with "userid"=userid, etc.
    let username+password = split(base64-decode(trimmed-substring(str, dpos, epos)), ':');
    pair(first(username+password), last(username+password));
  else
    make(<avalue>,
         value: substring(str, b, e),
         alist: extract-attribute-value-alist(str, dpos, epos, ','));
  end;
end;

define function parse-attribute-value-pair (str :: <byte-string>,
                                            bpos :: <integer>,
                                            epos :: <integer>)
  let (attribute, value) = extract-attribute+value(str, bpos, epos);
  pair(attribute, value)
end;

define function parse-string-value (str :: <byte-string>,
                                    bpos :: <integer>,
                                    epos :: <integer>)
  substring(str, bpos, epos)
end;

define function parse-token-value (str :: <byte-string>,
                                   bpos :: <integer>,
                                   epos :: <integer>)
  let ss = substring(str, bpos, epos); // may or may not copy.
  let (str, bpos, epos) = string-extent(ss);
  // Change in place, because nobody really minds...
  for (pos from bpos below epos)
    str[pos] := as-lowercase(str[pos]);
  end;
  ss
end;

define function parse-expectation-pair (str :: <byte-string>,
                                        bpos :: <integer>,
                                        epos :: <integer>)
  let vpos = char-position('=', str, bpos, epos);
  pair(trimmed-substring(str, bpos, vpos | epos),
       vpos & parse-parameterized-value(str, vpos + 1, epos))
end;

define function parse-host-value (str :: <string>,
                                  bpos :: <integer>,
                                  epos :: <integer>)
  => (host+port :: <pair>)
  let ppos = char-position(':', str, bpos, epos) | epos;
  let host = trimmed-substring(str, bpos, ppos);
  let (b, e) = trim-whitespace(str, ppos + 1, epos);
  let port = ppos < epos
              & (string->integer(str, b, e)
                   | bad-header-error());
  pair(host, port)
end;

define function parse-entity-tag-value (str :: <byte-string>,
                                        bpos :: <integer>,
                                        epos :: <integer>)
  if (string-match("*", str, bpos, epos))
   #("*" . #f)
  else
    let weak? = looking-at?("W/", str, bpos, epos)
                  & (bpos := skip-whitespace(str, bpos + 2, epos));
    unless (bpos < epos & str[bpos] == '"')
      bad-header-error();
    end;
    let tag = token-or-qstring(str, bpos, epos);
    pair(tag, weak?)
  end;
end;

define function parse-http-date (str :: <byte-string>,
                                 bpos :: <integer>,
                                 epos :: <integer>)
  => (date :: false-or(<date>))
  // wish could stack-cons this..
  let v = make(<simple-object-vector>, size: 8);
  iterate loop (bpos = bpos, i = 0)
    let pos = token-end-position(str, bpos, epos) | epos;
    unless (pos == bpos | i == 8)
      v[i] := string->integer(str, bpos, pos) | substring(str, bpos, pos);
      let bpos = if (pos == epos | str[pos] == ';') epos
                 else skip-whitespace(str, pos + 1, epos) end;
      if (bpos ~== epos)
        loop(bpos, i + 1)
      else
        let (sec, min, hour, day, mon, year)
          = if (instance?(v[0], <integer>)) // year-month-day hr:min:sec
              values(v[5], v[4], v[3], v[2], v[1], v[0])
            elseif (instance?(v[1], <integer>)) // wkday, day month year hr:min:sec GMT
              values(v[6], v[5], v[4], v[1], v[2], v[3])
            else // wkday month day hr:min:sec year GMT
              values(v[5], v[4], v[3], v[2], v[1], v[6])
            end;
        let sec = sec | 0;
        let min = min | 0;
        let hour = hour | 0;
        let day = day | 0;
        let month = find-key(#("Jan" "Feb" "Mar" "Apr" "May" "Jun"
                               "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"),
                             curry(string-equal?, mon));
        when (instance?(sec, <integer>) & sec < 60 &
              instance?(min, <integer>) & min < 60 &
              instance?(hour, <integer>) & hour < 24 &
              instance?(day, <integer>) & 0 < day &
              month & instance?(year, <integer>))
          let year = if (year >= 1800) year
                     elseif (year < 80) year + 2000
                     else year + 1900 end;
          // this is getting silly, but the date library validates this
          // and we don't want to get errors.
          let max-days = if (month == 1 & modulo(year, 4) == 0
                              & (modulo(year, 100) ~== 0 | modulo(year, 400) == 0))
                           29
                         else
                           #[31,28,31,30,31,30,31,31,30,31,30,31][month]
                         end;
          when (day <= max-days & year < 2200)
            encode-date(year, month + 1, day, hour, min, sec, time-zone-offset: 0)
          end;
        end;
      end;
    end;
  end;
end;

define function parse-date-value (str :: <byte-string>,
                                  bpos :: <integer>,
                                  epos :: <integer>)
  => (date :: <date>)
  parse-http-date(str, bpos, epos) | bad-header-error()
end;

define function parse-integer-value (str :: <byte-string>,
                                     bpos :: <integer>,
                                     epos :: <integer>)
  => (n :: <integer>)
  string->integer(str, bpos, epos) | bad-header-error()
end;

define function parse-ranges-value (str :: <byte-string>,
                                    bpos :: <integer>,
                                    epos :: <integer>)
  => (ranges :: <list>)
  let pos = char-position('=', str, bpos, epos) | bad-header-error();
  let (b, e) = trim-whitespace(str, bpos, pos);
  string-match("bytes", str, b, e) | bad-header-error();
  iterate loop (pos = pos, ranges = #())
    let bpos = skip-whitespace(str, pos + 1, epos);
    if (bpos == epos)
      reverse!(ranges)
    else
      let lim = char-position(',', str, bpos, epos) | epos;
      let pos = char-position('-', str, bpos, lim) | bad-header-error();
      let first = unless (pos == bpos)
                    let (b, e) = trim-whitespace(str, bpos, pos);
                    parse-integer-value(str, b, e)
                  end;
      let pos = skip-whitespace(str, pos + 1, lim);
      let last = unless (first & pos == lim)
                   parse-integer-value(str, pos, lim)
                 end;
      loop(lim, pair(pair(first, last), ranges))
    end;
  end;
end;

define function parse-range-value (str :: <byte-string>,
                                   bpos :: <integer>,
                                   epos :: <integer>)
  => (range :: <pair>)
  let pos = token-end-position(str, bpos, epos);
  (pos & string-match("bytes", str, bpos, pos)) | bad-header-error();
  let bpos = skip-whitespace(str, pos, epos);
  bpos < epos | bad-header-error();
  let (first, last, pos)
    = if (str[bpos] == '*')
        let pos = skip-whitespace(str, bpos + 1, epos);
        unless (pos < epos & str[pos] == '/') bad-header-error() end;
        values(#f, #f, pos)
      else
        let pos1 = char-position('-', str, bpos, epos);
        let first = pos1 & trimmed-string->integer(str, bpos, pos1);
        let pos2 = pos1 & char-position('/', str, pos1 + 1, epos);
        let last = pos2 & trimmed-string->integer(str, pos1 + 1, pos2);
        unless (first & last) bad-header-error() end;
        values(first, last, pos2);
      end;
  let bpos = skip-whitespace(str, pos + 1, epos);
  let len = if (bpos + 1 == epos & str[bpos] == '*') #f
            else string->integer(str, bpos, epos) | bad-header-error() end;
  pair(pair(first, last), len);
end;

