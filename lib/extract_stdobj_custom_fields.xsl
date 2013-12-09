<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sf="http://soap.sforce.com/2006/04/metadata" xmlns="http://soap.sforce.com/2006/04/metadata"  exclude-result-prefixes="sf">

<xsl:variable name="field_whitelist" select="',Active__c,CustomerPriority__c,NumberofLocations__c,SLAExpirationDate__c,SLASerialNumber__c,SLA__c,UpsellOpportunity__c,Languages__c,Level__c,CurrentGenerators__c,NumberofLocations__c,Primary__c,ProductInterest__c,SICCode__c,CurrentGenerators__c,DeliveryInstallationStatus__c,MainCompetitors__c,OrderNumber__c,TrackingNumber__c,'" />

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

    <xsl:template match="sf:CustomObject">
        <types>
        <xsl:for-each select="sf:fields">
          <xsl:if test="substring(sf:fullName, string-length(sf:fullName) - 2) = '__c'">
          <xsl:if test="not(contains(substring(sf:fullName, 0, string-length(sf:fullName) - 2), '__'))">
          <xsl:if test="not(contains($field_whitelist, concat(',', sf:fullName, ',')))">
            <members><xsl:copy-of select="sf:fullName/text()"/></members>
          </xsl:if>
          </xsl:if>
          </xsl:if>
        </xsl:for-each>
        </types>
    </xsl:template>

</xsl:stylesheet>
