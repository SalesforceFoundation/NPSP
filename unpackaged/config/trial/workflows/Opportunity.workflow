<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>%%%NAMESPACE%%%Opportunity_Email_Acknowledgment</fullName>
        <description>Opportunity Email Acknowledgment</description>
        <protected>false</protected>
        <recipients>
            <field>%%%NAMESPACE%%%Primary_Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>%%%NAMESPACE%%%NPSP_Email_Templates/%%%NAMESPACE%%%NPSP_Opportunity_Acknowledgment</template>
    </alerts>
    <fieldUpdates>
        <fullName>%%%NAMESPACE%%%Opportunity_AcknowledgmentStatus_Update</fullName>
        <description>Sets the Acknowledgment Status to &quot;Acknowledged&quot;</description>
        <field>%%%NAMESPACE%%%Acknowledgment_Status__c</field>
        <literalValue>Acknowledged</literalValue>
        <name>Opportunity Acknowledgment Status Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>%%%NAMESPACE%%%Opportunity_Acknowledgment_Date_Update</fullName>
        <description>sets the Acknowledgment Date to Today.</description>
        <field>%%%NAMESPACE%%%Acknowledgment_Date__c</field>
        <formula>Today()</formula>
        <name>Opportunity Acknowledgment Date Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>%%%NAMESPACE%%%Opportunity_Copy_FMV_to_Amount</fullName>
        <description>Copy the Opportunities Fair Market Value field to the Amount field.</description>
        <field>Amount</field>
        <formula>%%%NAMESPACE%%%Fair_Market_Value__c</formula>
        <name>Opportunity Copy FMV to Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>%%%NAMESPACE%%%Opportunity Copy FMV to Amount</fullName>
        <actions>
            <name>%%%NAMESPACE%%%Opportunity_Copy_FMV_to_Amount</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>(1 OR 2) AND (3 AND 4)</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Amount</field>
            <operation>equals</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Amount</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.%%%NAMESPACE%%%Fair_Market_Value__c</field>
            <operation>notEqual</operation>
            <value>0</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.%%%NAMESPACE%%%Fair_Market_Value__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Enable this rule to copy the Fair Market Value to the Amount field, when the Amount is zero or blank.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>%%%NAMESPACE%%%Opportunity Email Acknowledgment</fullName>
        <actions>
            <name>%%%NAMESPACE%%%Opportunity_Email_Acknowledgment</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>%%%NAMESPACE%%%Opportunity_AcknowledgmentStatus_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>%%%NAMESPACE%%%Opportunity_Acknowledgment_Date_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Emails an acknowledgement to the Primary Contact for an Opportunity when the Acknowledgement Status is set to Email Acknowledgement Now.</description>
        <formula>TEXT(%%%NAMESPACE%%%Acknowledgment_Status__c) = $Label.%%%NAMESPACE%%%sendacknowledgmentfirestatus &amp;&amp;  %%%NAMESPACE%%%Primary_Contact__r.Email &lt;&gt; NULL &amp;&amp;  %%%NAMESPACE%%%Primary_Contact__r.%%%NAMESPACE%%%Do_Not_Contact__c &lt;&gt; True &amp;&amp;  %%%NAMESPACE%%%Primary_Contact__r.HasOptedOutOfEmail &lt;&gt; True &amp;&amp;  %%%NAMESPACE%%%Primary_Contact__r.%%%NAMESPACE%%%Deceased__c &lt;&gt; True</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
