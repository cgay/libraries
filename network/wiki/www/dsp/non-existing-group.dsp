<%dsp:include url="xhtml-start.dsp"/>
<%dsp:taglib name="wiki"/>
<%dsp:taglib name="web-framework" prefix="wf"/>
<head>
  <title>Dylan Wiki: <dsp:get name="group-name"/></title>
  <%dsp:include url="meta.dsp"/>
</head>
<body>
  <%dsp:include url="header.dsp"/>
  <div id="content">
    <%dsp:include url="navigation.dsp"/>
    <div id="body">
      <h2><dsp:get name="group-name"/></h2>

      <dsp:show-page-errors/>
      <dsp:show-page-notes/>

      <p class="hint">
        This group doesn't exist.
	<a href="<wiki:base/>/register">Register</a> or
	<a href="<wiki:base/>/login?redirect=<wiki:current/>">login</a>
	to create it.
      </p>
    </div>
  </div>
  <%dsp:include url="footer.dsp"/>
</body>
</html>
