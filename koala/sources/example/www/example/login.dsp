<html>
<head>
  <title>DSP Example -- Login</title>
</head>

<body>

  <%dsp:include url="header.dsp"/>
  <%dsp:include url="body-wrapper-start.dsp"/>

  <dsp:show-errors/>

  <form action="welcome.dsp" method="post" enctype="application/x-www-form-urlencoded">
    <h2>Please Login</h2>
    <table border="0" align="center" cellspacing="2">
      <tr>
        <td nowrap align="right">User name:</td>
        <td nowrap><input name="username" value="<dsp:current-username/>" type="text"></td>
      </tr>
      <tr>
        <td nowrap align="right">Password:</td>
        <td nowrap><input name="password" value="" type="password"></td>
      </tr>
      <tr>
        <td nowrap align="right" colspan="2"><input name="submit" value="Login" type="submit"></td>
      </tr>
    </table>
  </form>

  <%dsp:include url="body-wrapper-end.dsp"/>
  <%dsp:include url="footer.dsp"/>

</body>
</html>
