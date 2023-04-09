<?xml version="1.0"?>
<xsl:transform
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0"
>

<!-- Parses model XML file to create HTML in order to visualize models -->

<xsl:template match="/">
	<html>
	<head/>
	<body style="font-family:Arial;font-size:16pt;background-color:#EEEEEE">

  
	<div style="background-color:#009999;black:white;padding:4px">
			<h1><a name="{topPage}">Model Set: </a> <xsl:value-of select="modelSet/material"/></h1>
	</div>
	
<table>
<tr> 
	<td>
	<table>
		<!-- Write basic modelset info -->
		<tr><th width="350" align="right"><h2>Kinetic Friction Coefficient: </h2></th><th width="200" align="left"><h2 style="color:#FF6600"><xsl:value-of select='format-number(modelSet/mu, "0.00")'/></h2></th></tr>
		<tr><th width="350" align="right"><h2>Sampling Rate: </h2></th><th width="200" align="left"><h2 style="color:red"><xsl:value-of select="modelSet/SampleRate"/> Hz</h2></th></tr>
		<tr><th width="350" align="right"><h2>Number of models: </h2></th><th width="200" align="left" style="color:#007A7A"><h2><xsl:value-of select="modelSet/numMod"/></h2></th></tr>
		<tr><th width="350" align="right"><h2>Number of AR coefficients: </h2></th><th width="200" align="left" style="color:#9966FF"><h2><xsl:value-of select="modelSet/numARCoeff"/></h2></th></tr>
		<tr><th width="350" align="right"><h2>Number of MA coefficients: </h2></th><th width="200" align="left" style="color:#6699FF"><h2><xsl:value-of select="modelSet/numMACoeff"/></h2></th></tr>
		<tr><th width="350" align="right"><h2>Model Output Units: </h2></th><th width="200" align="left" style="color:#666699"><h2>m/s<sup>2</sup></h2></th></tr>
		<tr><th width="350" align="right"><h2>Max speed: </h2></th><th width="200" align="left" style="color:#339933"><h2><xsl:value-of select='format-number(modelSet/maxSpeed, "#.0")'/> mm/s</h2></th></tr>
		<tr><th width="350" align="right"><h2>Max force: </h2></th><th width="200" align="left" style="color:#996633"><h2><xsl:value-of select='format-number(modelSet/maxForce, "#.000")'/> N</h2></th></tr>
	</table>
	</td>
	
	<td width="500">
	<table>
		<tr><img src="{modelSet/htmlPicture}" alt="Texture image not found" onError="this.onerror=null;this.src='{modelSet/htmlLinuxPicture}';" width="512"/></tr>
	</table>
	</td>
</tr>
</table>

<!-- Calls template (model info table) -->
	<xsl:apply-templates mode="toc"/>
   
<!-- Calls template (individual models and DT table) -->
	<xsl:apply-templates/>

  </body>
</html>
</xsl:template>
  
<!-- Creates template (model info table) -->
<xsl:template match="modelSet" mode="toc">
	<!-- Create DT hyperlink -->
	<h3>Jump to: <a href="#DT">Delaunay Triangulation</a></h3>
	
	<div style="background-color:#646464;color:white;padding:4px">
		<h3>List of Models:</h3>
	</div>

	<table border="1"> <!-- Creates all models table -->
	<tr>
		<!-- Table headers -->
		<th width="150" bgcolor="#99D6D6"  align="center"> Model Number </th>
		<th width="150" bgcolor="#339933"  align="center"> Speed (mm/s) </th>
		<th width="150" bgcolor="#996633"  align="center"> Force (N) </th>
	</tr>
	<!-- Loop through each model and pull force and speed -->
	<xsl:for-each select="model">
		<tr>
			<!-- Hyperlink model number -->
			<td align="center" bgcolor="#E0F3F3"><a href="#{modNum}"><xsl:value-of select="modNum"/></a></td>
			
			<xsl:if test="speedMod &gt; 99.99">
			<td align="center" bgcolor="#C2E0C2"><xsl:value-of select='format-number(speedMod, "00.0")'/></td>
			</xsl:if>
			<xsl:if test="speedMod &lt; 99.99">
				<xsl:if test="speedMod &gt; 9.99">
				<td align="center" bgcolor="#C2E0C2"><xsl:text> &#160;     </xsl:text><xsl:value-of select='format-number(speedMod, "00.0")'/></td>
				</xsl:if>
				
				<xsl:if test="speedMod &lt; 9.99">
				<td align="center" bgcolor="#C2E0C2"><xsl:text> &#160; &#160;    </xsl:text><xsl:value-of select='format-number(speedMod, "0.0")'/></td>
				</xsl:if>
			</xsl:if>
			
			<td align="center" bgcolor="#D6C2AD"><xsl:value-of select='format-number(forceMod, "0.000")'/></td>
		</tr>
	</xsl:for-each> <!-- End model loop -->
  </table>
  
    <!-- Create hyperlink to top of page -->
	<h4><a href="#{topPage}">top of page</a></h4>
  
</xsl:template>
  
<!-- Creates template (individual models and DT table) -->
<xsl:template match="modelSet">
	<!-- Loops through each model -->
	<xsl:for-each select="model">
		<!-- Creates divider and labels model (this is where modNum hyperlink points to) -->
		<div style="background-color:#99D6D6;color:white;padding:4px">
			<h2>Model <a name="{modNum}"><xsl:value-of select="modNum"/></a></h2>
		</div>
		
		<table>
			<!-- Model info -->
			<tr><th width="200" align="right"><h3>Model Speed: </h3></th><th width="350" align="left" style="color:#339933"><h3><xsl:value-of select='format-number(speedMod, "0.0")'/>  mm/s</h3></th></tr>
			<tr><th width="200" align="right"><h3>Model Force: </h3></th><th width="350" align="left" style="color:#996633"><h3><xsl:value-of select='format-number(forceMod, "0.000")'/> N</h3></th></tr>
			<tr><th width="200" align="right"><h3>Model Variance: </h3></th><th width="350" align="left" style="color:#CC3300"><h3><xsl:value-of select='format-number(var, "0.0000")'/></h3></th></tr>
			<tr><th width="200" align="right"><h3>Model Gain: </h3></th><th width="350" align="left" style="color:#FF0066"><h3><xsl:value-of select='format-number(gain, "0.0000")'/></h3></th></tr>
		</table>

		<!-- Model parameter tables (AR) -->
		<div style="color:#9966FF;padding:2px">
			<h3>AR Model Parameters:</h3>
		</div>
		<table>
		<tr>
		<td><!-- Coefficient table -->
			<table border="1">
			<tr bgcolor="#9966FF">
				<th width="150" align="center"> AR Coefficient </th>
				<th width="50"> Lag </th>
			</tr>
			<!-- Add each coefficient and LSF to table -->
			<xsl:for-each select="ARcoeff/value">
			<tr>
				<xsl:if test=". &lt; 0">
					<td align="center" bgcolor="#EBE0FF"><xsl:value-of select='format-number(., "0.000000")'/></td>
				</xsl:if>
				<xsl:if test=". &gt; 0">
					<td align="center" bgcolor="#EBE0FF"><xsl:text> &#160;     </xsl:text><xsl:value-of select='format-number(., "0.000000")'/></td>
				</xsl:if>
				<td bgcolor="#EBE0FF">z<sup>-<xsl:value-of select="position()-1" /></sup></td>
			</tr>
			</xsl:for-each>
			</table>
		</td>
		
		<td><!-- Space between tables -->
			<table>
			<tr>
				<th width="50" align="center"> </th>
			</tr>
			</table>
		</td>
		
		<td style="vertical-align:top;"><!-- LSF table -->
			<table border="1">
			<!-- Table headers -->
			<tr bgcolor="#9966FF">
				<th width="300"> AR Line Spectral Frequency </th>
			</tr>
			<!-- Add each coefficient and LSF to table -->
			<xsl:for-each select="ARlsf/value">
			<tr>
				<td align="center" bgcolor="#EBE0FF"><xsl:value-of select="."/></td>
			</tr>
			</xsl:for-each>
			</table>

		</td>
		</tr>
		</table> 
		
		<!-- Model parameter tables (MA) -->
		<div style="color:#6699FF;padding:2px">
			<h3>MA Model Parameters:</h3>
		</div>
		<table>
		<tr>
		<td><!-- Coefficient table -->
			<table border="1">
			<tr bgcolor="#6699FF">
				<th width="150" align="center"> MA Coefficient </th>
				<th width="50"> Lag </th>
			</tr>
			<!-- Add each coefficient and LSF to table -->
			<xsl:for-each select="MAcoeff/value">
			<tr>
				<xsl:if test=". &lt; 0">
					<td align="center" bgcolor="#E0EBFF"><xsl:value-of select='format-number(., "0.000000")'/></td>
				</xsl:if>
				<xsl:if test=". &gt; 0">
					<td align="center" bgcolor="#E0EBFF"><xsl:text> &#160;     </xsl:text><xsl:value-of select='format-number(., "0.000000")'/></td>
				</xsl:if>
				<td bgcolor="#E0EBFF">z<sup>-<xsl:value-of select="position()-1" /></sup></td>
			</tr>
			</xsl:for-each>
			</table>
		</td>
		
		<td><!-- Space between tables -->
			<table>
			<tr>
				<th width="50" align="center"> </th>
			</tr>
			</table>
		</td>
		
		<td style="vertical-align:top;"><!-- LSF table -->
			<table border="1">
			<!-- Table headers -->
			<tr bgcolor="#6699FF">
				<th width="300"> MA Line Spectral Frequency </th>
			</tr>
			<!-- Add each coefficient and LSF to table -->
			<xsl:for-each select="MAlsf/value">
			<tr>
				<td align="center" bgcolor="#E0EBFF"><xsl:value-of select="."/></td>
			</tr>
			</xsl:for-each>
			</table>

		</td>
		</tr>
		</table> 
	
		<!-- Create hyperlink to top of page -->
		<h4><a href="#{topPage}">top of page</a></h4>
	</xsl:for-each> <!-- End model loop -->

	<!-- Label DT section (this is where DT hyperlink points to) -->
	<div style="background-color:#FF5050;color:white;padding:4px">
		<h3><a name="DT">Delaunay Triangulation </a></h3>
	</div>
	
	<table>
	<tr> 	
		<!-- Delaunay Triangulation table -->
		<td>
		<table border="1">
		<!-- Column header -->
		<tr>
			<th width="150" bgcolor="#FF7C81"> Model Vertex 1 </th>
			<th width="150" bgcolor="#FFB0B3"> Model Vertex 2 </th>
			<th width="150" bgcolor="#FF7C81"> Model Vertex 3 </th>
		</tr>
		<!-- Loop through each triangle -->
		<xsl:for-each select="tri">
		<tr>
			<!-- Loop through three vertices of triangle -->
			<xsl:for-each select="value"> 
				<td align="center" bgcolor="#FFD8D9"><xsl:value-of select="."/></td>
			</xsl:for-each>
		</tr>
		</xsl:for-each> <!-- End triangle loop -->
		</table>
		</td>
		
		<td width="500" style="vertical-align:top;">
		<table>
			<tr><img src="{DTpicture}" alt="Delaunay Triangulation image not found" onError="this.onerror=null;this.src='{LinuxDTpicture}';" width="512"/></tr>
		</table>
		</td>
			
	</tr>
	</table>
	
	<!-- Create hyperlink to top of page -->
	<h4><a href="#{topPage}">top of page</a></h4>
</xsl:template>

</xsl:transform>