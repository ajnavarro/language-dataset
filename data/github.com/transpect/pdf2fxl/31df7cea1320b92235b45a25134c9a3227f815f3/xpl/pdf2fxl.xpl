<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:epub="http://transpect.io/epubtools"
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="tr-pdf2fxl"
  type="tr:pdf2fxl" 
  exclude-inline-prefixes="tr c css html">
  
  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    pdf2fxl converts a PDF to Fixed Layout EPUB3. To extract HTML from PDF, 
    <a href="https://poppler.freedesktop.org" target="_blank">Poppler</a> needs 
    to be installed. Further information can be found in the 
    <a href="https://github.com/transpect/pdf2fxl/blob/master/README.md" target="_blank">README</a>.  
  </p:documentation>
  
  <p:output port="result" primary="true">
    <p:documentation>The result port provides the HTML</p:documentation>
    <p:pipe port="result" step="css-name"/>
  </p:output>

  <p:output port="css" primary="false">
    <p:documentation>This port provides the CSS stylesheet.</p:documentation>
    <p:pipe port="result" step="rename-wrapper"/>
  </p:output>
  
  <p:serialization port="css" method="text" encoding="UTF-8" media-type="text/plain"/>
  <p:serialization port="result" method="xhtml" omit-xml-declaration="false" doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" indent="true"/>
  
  <p:option name="path" required="true">
    <p:documentation>
      The path to the directory which contains the HTML files derived from pdf2html
    </p:documentation>
  </p:option>
		
	<p:option name="rastertext" select="'no'">
		<p:documentation>
			Must be set to yes, if you want to use rasterized page spreads. 
		</p:documentation>
	</p:option>
	
  <p:option name="headline-fontsize" select="35">
  	<p:documentation>
  		Defines the fontsize in px that is used to detect headlines for toc generation. 
  	</p:documentation>
  </p:option>
  
  <!-- debugging options -->

	<p:option name="debug" select="'yes'">
		<p:documentation>
			Used to switch debug mode on or off. Pass 'yes' to enable debug mode.
		</p:documentation>
	</p:option> 
	
	<p:option name="debug-dir-uri" select="'debug'">
		<p:documentation>
			Expects a file URI of the directory that should be used to store debug information. 
		</p:documentation>
	</p:option>
	
	<p:option name="progress" select="'yes'">
		<p:documentation>
			Whether to display progress information as text files in a certain directory
		</p:documentation>
	</p:option>
	
	<p:option name="status-dir-uri" select="concat($debug-dir-uri, '/status')">
		<p:documentation>
			Expects URI where the text files containing the progress information are stored.
		</p:documentation>
	</p:option>

  <p:import href="http://transpect.io/css-tools/xpl/css.xpl"/>
  <p:import href="http://transpect.io/epubtools/xpl/epub-convert.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/simple-progress-msg/xpl/simple-progress-msg.xpl"/>
  
  <tr:simple-progress-msg name="start-msg1" file="pdf-convert-start.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Starting PDF to HTML conversion</c:message>
          <c:message xml:lang="de">Konvertiere PDF nach HTML</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
	
	<tr:file-uri name="input-dir-uri">
		<p:documentation xmlns="http://www.w3.org/1999/xhtml">
			<p>The output files are stored relative to the base-uri of the document on the primary input port.</p>
		</p:documentation>
		<p:with-option name="filename" select="$path"/>
	</tr:file-uri>
  
  <!-- directory listing -->
  
  <p:directory-list name="directory-list">
    <p:with-option name="path" select="/*/@local-href"/>
  </p:directory-list>
  
  <tr:store-debug pipeline-step="pdf2fxl/directory-list">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <!-- load individual html files and expand CSS styles as attributes -->
  
  <tr:simple-progress-msg name="start-msg2" file="collect-single-html.txt">
    <p:input port="msgs">
      <p:inline>
        <c:messages>
          <c:message xml:lang="en">Create wrapped HTML</c:message>
          <c:message xml:lang="de">Erstelle Gesamt-HTML</c:message>
        </c:messages>
      </p:inline>
    </p:input>
    <p:with-option name="status-dir-uri" select="$status-dir-uri"/>
  </tr:simple-progress-msg>
  
  <p:for-each name="iterate-html">
    <p:iteration-source select="//c:file[matches(@name, '^.+\.(htm|html|xhtml)$')]"/>
    <p:variable name="filename" select="c:file/@name"/>
    <p:variable name="filepath" select="concat(/*/@local-href, '/', $filename)">
      <p:pipe port="result" step="input-dir-uri"/>
    </p:variable>
    
    <cx:message>
      <p:with-option name="message" select="'[info] processing ', $filepath"/>
    </cx:message>
    
    <p:load name="load">
      <p:with-option name="href" select="$filepath"/>
    </p:load>
    
    <p:xslt>
      <p:input port="stylesheet">
        <p:inline>
          <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            exclude-result-prefixes="xs"
            version="2.0">
            
            <xsl:template match="@*|*">
              <xsl:copy>
                <xsl:apply-templates select="@*, node()"/>
              </xsl:copy>
            </xsl:template>
            
          </xsl:stylesheet>
        </p:inline>
      </p:input>
      <p:input port="parameters">
        <p:empty/>
      </p:input>
    </p:xslt>
    
    <tr:store-debug>
      <p:with-option name="pipeline-step" select="concat('pdf2fxl/html/', $filename)"/>
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
    
    <css:expand name="expand">
      <p:input port="stylesheet">
        <p:document href="../css-tools/xsl/css-parser.xsl"/>
      </p:input>
      <p:with-option name="path-constraint" select="''"/>
      <p:with-option name="prop-constraint" select="''"/>
      <p:with-option name="debug" select="$debug"/>
      <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    </css:expand>
    
  </p:for-each>
  
  <p:wrap-sequence wrapper="collection" name="collection" cx:depends-on="iterate-html"/>
  
  <cx:message>
    <p:with-option name="message" select="'[info] wrap collection in single HTML'"/>
  </cx:message>
  
  <tr:store-debug pipeline-step="pdf2fxl/html-collection-pre">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <!-- XSLT convert and sort -->
  
  <p:xslt name="transform-html" cx:depends-on="collection">
    <p:with-param name="headline-fontsize" select="$headline-fontsize"/>
  	<p:with-param name="rastertext" select="$rastertext"/>
    <p:input port="stylesheet">
      <p:document href="../xsl/pdf2fxl.xsl"/>
    </p:input>
  </p:xslt>
	
  <tr:store-debug pipeline-step="pdf2fxl/html-collection-transform">
		<p:with-option name="active" select="$debug"/>
		<p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:xslt name="sort-html" cx:depends-on="transform-html">
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:document href="../xsl/sort-html.xsl"/>
    </p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="pdf2fxl/html-collection-post" extension="xhtml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <!-- exclude style element and insert CSS reference. Port 'css' provides the stylesheet file -->
  
  <p:filter select="/html:html/html:head/html:style"/>
  
  <p:rename match="html:style" new-name="c:data" name="rename-wrapper"/>
  
  <p:delete match="/html:html/html:head/html:style">
    <p:input port="source">
      <p:pipe port="result" step="sort-html"/>
    </p:input>
  </p:delete>
  
  <p:insert match="/html:html/html:head" position="last-child">
    <p:input port="insertion">
      <p:inline>
        <link xmlns="http://www.w3.org/1999/xhtml" type="text/css" rel="stylesheet"/>
      </p:inline>
    </p:input>
  </p:insert>
	
	<p:add-attribute match="/html:html" attribute-name="xml:base" name="xmlbase">
		<p:with-option name="attribute-value" select="replace(/*/@local-href, '^(.+)/([^/]+)/?\.[a-z]+$', '$1/$2.epub')">
			<p:pipe port="result" step="input-dir-uri"/>
		</p:with-option>
	</p:add-attribute>
  
  <p:add-attribute match="/html:html/html:head/html:link[last()]" attribute-name="href" name="css-name">
		<p:with-option name="attribute-value" select="replace(/*/@xml:base, '\.x?html$', '.css')"/>
	</p:add-attribute>
  
  <tr:store-debug pipeline-step="pdf2fxl/merged-html" extension="xhtml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:sink name="sink1"/>
  
  <p:store method="text" cx:depends-on="xmlbase" name="css-write" undeclare-prefixes="true">
    <p:input port="source">
      <p:pipe port="result" step="rename-wrapper"/>
    </p:input>
    <p:with-option name="href" select="/html:html/html:head/html:link[last()]/@href">
      <p:pipe port="result" step="css-name"/>
    </p:with-option>
  </p:store>
  
</p:declare-step>
