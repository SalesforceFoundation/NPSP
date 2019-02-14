*** Settings ***

Resource        tests/NPSP.robot
Library           DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Edit Batch Created Via API
    [tags]  unstable
    ${ns} =  Get NPSP Namespace Prefix
    &{batch} =       API Create DataImportBatch    Batch_Process_Size__c=50    Batch_Description__c=Created via API    Donation_Matching_Behavior__c=Single Match or Create    Donation_Matching_Rule__c=donation_amount__c;donation_date__c    RequireTotalMatch__c=false    Run_Opportunity_Rollups_while_Processing__c=true   GiftBatch__c=true    Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}]     
    Select App Launcher Tab   Batch Gift Entry
    Click Link With Text    &{batch}[Name]
    #Click Link  &{batch}[Name]
    Click BGE Button       Edit
    Fill BGE Form
    ...                       Expected Count of Gifts=2
    ...                       Expected Total Batch Amount=20
    Select BGE Checkbox    Require Expected Totals Match
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Next
    Click Button        xpath=//div[contains(@class,"footer")]//button[text()="Save"]
    Verify Title    Batch Gift Entry    ${batch}[Name]
    Wait For Locator    bge.button    Process Batch
    Page Should Contain    Total Count: 0 / 2
    #Page Should Contain    Total Amount: / $20.00
    Click BGE Button       Process Batch
    Page Should Contain    Error
    Verify Title    Batch Gift Entry    ${batch}[Name]
    