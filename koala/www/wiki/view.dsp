<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%dsp:taglib name="wiki"/>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title><wiki:show-page-title/></title>
</head>

<body>
  <%dsp:include url="header.dsp"/>
  <wiki:show-page-content format="html"/>
  <%dsp:include url="footer.dsp"/>
</body>
</html>
