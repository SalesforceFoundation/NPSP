<?xml version="1.0" encoding="UTF-8"?>
<Profile xmlns="http://soap.sforce.com/2006/04/metadata">
    <applicationVisibilities>
        <application>%%%NAMESPACE%%%Nonprofit_CRM</application>
        <default>false</default>
        <visible>true</visible>
    </applicationVisibilities>
    <applicationVisibilities>
        <application>Nonprofit_Success_Pack</application>
        <default>true</default>
        <visible>true</visible>
    </applicationVisibilities>
    <layoutAssignments>
        <layout>Account-Household Lightning Layout</layout>
        <recordType>Account.HH_Account</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Account-%%%NAMESPACE%%%Organization Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Account-Organization Lightning Layout</layout>
        <recordType>Account.Organization</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Contact-Contact Lightning Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Campaign-%%%NAMESPACE%%%NPSP Campaign Layout</layout>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Donation Layout</layout>
        <recordType>Opportunity.NPSP_Default</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Donation Layout</layout>
        <recordType>Opportunity.Donation</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Grant Layout</layout>
        <recordType>Opportunity.Grant</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%In-Kind Gift Layout</layout>
        <recordType>Opportunity.InKindGift</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Major Gift Layout</layout>
        <recordType>Opportunity.MajorGift</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Matching Gift Layout</layout>
        <recordType>Opportunity.MatchingGift</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>Opportunity-%%%NAMESPACE%%%Membership Layout</layout>
        <recordType>Opportunity.Membership</recordType>
    </layoutAssignments>
    <layoutAssignments>
        <layout>%%%NAMESPACE%%%Grant_Deadline__c-Deliverable</layout>
    </layoutAssignments>
    <recordTypeVisibilities>
        <default>true</default>
        <recordType>Opportunity.Donation</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.Grant</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.InKindGift</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.MajorGift</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.MatchingGift</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.Membership</recordType>
        <visible>true</visible>
    </recordTypeVisibilities>
    <recordTypeVisibilities>
        <default>false</default>
        <recordType>Opportunity.NPSP_Default</recordType>
        <visible>false</visible>
    </recordTypeVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%Address__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%Batch_Gift_Entry</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%Contact_Merge</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%DataImport__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%Engagement_Plan_Template__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%General_Accounting_Unit__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%Grant_Deadline__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%Level__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%NPSP_Resources</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>%%%NAMESPACE%%%NPSP_Settings</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>npe01__OppPayment__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>npe4__Relationship__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
    <tabVisibilities>
        <tab>npe5__Affiliation__c</tab>
        <visibility>DefaultOn</visibility>
    </tabVisibilities>
</Profile>
