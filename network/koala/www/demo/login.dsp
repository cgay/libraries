<%dsp:taglib name="demo"/>

<html>
<head>
  <title>DSP Example -- Login</title>
</head>

<body>

  <%dsp:include location="header.dsp"/>
  <%dsp:include location="body-wrapper-start.dsp"/>

  <dsp:show-form-notes/>

  <form action="<demo:base-url/>/welcome"
        method="post"
        enctype="application/x-www-form-urlencoded">

    <h2>Please Login</h2>

    <p>This page demonstrates posting to a Dylan Server Page (see the
       respond-to method), using the DSP session, and use of simple tags.

    <p>Any username and password will do.

    <p>Try logging in without specifying both username and password to
       see the error mechanism.

    <p>
    <table border="0" align="center" cellspacing="2">
      <tr>
        <td nowrap align="right">User name:</td>
        <td nowrap><input name="username" value="<demo:current-username/>" type="text"></td>
      </tr>
      <tr>
        <td nowrap align="right">Password:</td>
        <td nowrap><input name="password" value="" type="password"></td>
      </tr>
      <tr>
        <td nowrap align="right" colspan="2">
          <input name="submit" value="Login" type="submit">
        </td>
      </tr>
    </table>
  </form>

  <%dsp:include location="body-wrapper-end.dsp"/>
  <%dsp:include location="footer.dsp"/>

</body>
</html>
