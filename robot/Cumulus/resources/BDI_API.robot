*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot


*** Keywords ***
Collect BDI Failures
    @{failures} =   Salesforce Query  DataImport__c
    ...           select=Id,Status__c,FailureInformation__c, PaymentImported__c, PaymentImportStatus__c
    ...           Status__c=Failed
    Return From Keyword @{failures}