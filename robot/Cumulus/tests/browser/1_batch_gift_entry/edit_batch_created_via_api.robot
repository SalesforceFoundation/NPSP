*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
Library         DateTime
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Edit Batch Created Via API
    [tags]  stable
    ${ns} =  Get NPSP Namespace Prefix
    &{batch} =       API Create DataImportBatch
    ...    ${ns}Batch_Process_Size__c=50
    ...    ${ns}Batch_Description__c=Created via API
    ...    ${ns}Donation_Matching_Behavior__c=Single Match or Create
    ...    ${ns}Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c
    ...    ${ns}RequireTotalMatch__c=false
    ...    ${ns}Run_Opportunity_Rollups_while_Processing__c=true
    ...    ${ns}GiftBatch__c=true
    ...    ${ns}Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}]
    Go To Page                  Details      DataImportBatch__c         object_id=${batch}[Id]
    Current Page Should Be      Details      DataImportBatch__c
    Click BGE Button       Edit
    Fill BGE Form
    ...                       Expected Count of Gifts=2
    ...                       Expected Total Batch Amount=20
    Select BGE Checkbox    Require Expected Totals Match
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Next
    Click Button        xpath=//div[contains(@class,"footer")]//button[text()="Save"]
    Wait For Locator    bge.title    Batch Gift Entry
    Verify Title    Batch Gift Entry    ${batch}[Name]
    Wait For Locator    bge.button    Process Batch
    Page Should Contain    Total Count: 0 / 2
    ${value}    Return Locator Value    bge.gift-amount    Total Amount:
    Should Be Equal As Strings    ${value}    Total Amount: / $20.00
    Click BGE Button       Process Batch
    Page Should Contain    Error
    Verify Title    Batch Gift Entry    ${batch}[Name]

