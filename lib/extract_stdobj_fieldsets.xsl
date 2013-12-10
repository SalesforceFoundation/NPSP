<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sf="http://soap.sforce.com/2006/04/metadata" xmlns="http://soap.sforce.com/2006/04/metadata"  exclude-result-prefixes="sf">

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

    <xsl:template match="sf:CustomObject">
        <types>
        <xsl:for-each select="sf:fieldSets">
          <xsl:if test="not(contains(substring(sf:fullName, 0, string-length(sf:fullName) - 2), '__'))">
            <members><xsl:copy-of select="sf:fullName/text()"/></members>
          </xsl:if>
        </xsl:for-each>
        </types>
    </xsl:template>

</xsl:stylesheet>
