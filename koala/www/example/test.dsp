<html>
<body>

This page demonstrates various features of Dylan Server Pages.<p>


<dsp:maybe-display-welcome/>

<!-- The most basic DSP tag.  No arguments, no body. -->
<p><hr>
Basic tags:<br>
<dsp:hello/>


<!-- A tag that has keyword arguments. -->
<p><hr>
Tags with keyword arguments:<br>
<dsp:show-keys arg1="a" arg2="b"/>

<%dsp:taglib name="example" prefix="ex"/>

<!-- An iteration tag.  The body may be executed zero or more times. -->
<p><hr>
Iteration tags:<br>
Specify a query value of n=xxx in the URL to change the number of iterations.<p>
<ex:repeat>
  This is iteration <ex:display-iteration-number/>.<br>
</ex:repeat>


<!-- Another iteration tag to demonstrate HTML table generation. -->
<p><hr>
Iteration tags used to dynamically generate tables:<br>
<table border="0" align="center" cellspacing="0" cellpadding="4">
  <ex:no-iterations name="blah-table">
    <tr><td>There are no rows to display.</td></tr>
  </ex:no-iterations>
  <ex:iterator name="blah-table">
    <tr bgcolor="<ex:row-bgcolor/>">
      <td width="10%"><ex:iteration-number/></td>
      <td width="90%">blah blah blah</td>
    </tr>
  </ex:iterator>
</table>
<p>
<table border="1">
  <ex:no-iterations name="zero-table">
    <tr><td>This table has no rows to display.</td></tr>
  </ex:no-iterations>
  <ex:iterator name="zero-table">
    <tr bgcolor="<ex:row-bgcolor/>">
      <td width="10%"><ex:iteration-number/></td>
      <td width="90%">zero zero zero</td>
    </tr>
  </ex:iterator>
</table>

<!-- The include directive -->
<p><hr>
Include directive:<br>
<%dsp:include url="/include-me.dsp"/>


<!-- A tag that shows the use of sessions. -->
<p><hr>
Using sessions to manage persistent data:<br>
The value below should change each time you refresh the page.<br>
<ex:demo-sessions/>


</body>
</html>
