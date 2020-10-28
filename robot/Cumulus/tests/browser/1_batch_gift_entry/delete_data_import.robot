*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
Library         DateTime
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Delete a Data Import
    [tags]  stable
    ${ns} =  Get NPSP Namespace Prefix
    &{batch} =       API Create DataImportBatch
    ...    ${ns}Batch_Process_Size__c=50
    ...    ${ns}Batch_Description__c=Created via API
    ...    ${ns}Donation_Matching_Behavior__c=Single Match or Create
    ...    ${ns}Donation_Matching_Rule__c=donation_amount__c;donation_date__c
    ...    ${ns}RequireTotalMatch__c=false
    ...    ${ns}Run_Opportunity_Rollups_while_Processing__c=true
    ...    ${ns}GiftBatch__c=true
    ...    ${ns}Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}]
    &{account} =     API Create Organization Account
    &{data_import} =  API Create DataImport    ${ns}NPSP_Data_Import_Batch__c=${batch}[Id]    ${ns}Account1Imported__c=${account}[Id]    ${ns}Donation_Donor__c=Account1
    Go To Page                  Details      DataImportBatch__c         object_id=${batch}[Id]
    Current Page Should Be      Details      DataImportBatch__c
    Wait For Locator    bge.locate_dropdown    1
    Sleep    3
    Select BGE Row     ${account}[Name]
    Click Span Button    Delete
    Page Should Contain    Total Count: 0
    ${status} =     Run Keyword And Return Status     Salesforce Get      DataImport__c  ${data_import}[Id]
    Should Be Equal As Strings    ${status}    False
