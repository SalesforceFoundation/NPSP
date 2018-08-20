<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_County_to_Account</fullName>
        <description>Copies the value of the County field to the Account.County__c field</description>
        <field>County__c</field>
        <formula>County_Name__c</formula>
        <name>Copy County to Account</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Household_Account__c</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>Copy Default Address County to Account</fullName>
        <actions>
            <name>Copy_County_to_Account</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Address__c.Default_Address__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Copies the County field&apos;s value to Account.County__c for default addresses</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
