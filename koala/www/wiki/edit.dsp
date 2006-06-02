<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%dsp:taglib name="wiki"/>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Dylan Wiki: 
     <dsp:if test="new-page?">
       <dsp:then>Adding Page</dsp:then>
       <dsp:else>Editing <wiki:show-title/></dsp:else>
     </dsp:if>
  </title>
  <link  rel="stylesheet" href="/wiki/wiki.css"/>
</head>

<body>

  <%dsp:include url="header.dsp"/>

  <div id="form-notes">
  <dsp:show-form-notes/>
  </div>

  <dsp:if test="login?">
    <dsp:then>
      <dsp:if test="new-page?">
        <dsp:then>
          <h1>Adding new Page</h1>
        </dsp:then>
        <dsp:else>    
          <h1>Editing "<wiki:show-title v="false" for-url="false"/>"</h1>
        </dsp:else>
      </dsp:if>
      <form action="/wiki/edit.dsp" method="post">
        <div id="edit">
          <dsp:if test="new-page?">
            <dsp:then>Title: <input type="text" name="title"/><br/></dsp:then>
            <dsp:else><input type="hidden" name="title" value="<wiki:show-title/>"/></dsp:else>
          </dsp:if>
          <textarea name="page-content" cols="80" rows="20"><wiki:show-content format="raw"/></textarea>
          <br/>
          Comment: <input type="text" name="comment"/>
          <br/>
          <input type="submit" value="Save"/>
        </div>
      </form>
    </dsp:then>
    <dsp:else>
      Error: you're not allowed to edit <wiki:show-title/>.
    </dsp:else>
  </dsp:if>

  <%dsp:include url="footer.dsp"/>

</body>
</html>
