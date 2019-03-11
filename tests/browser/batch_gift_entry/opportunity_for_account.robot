*** Settings ***

Resource        tests/NPSP.robot
Library           DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Select an opportunity for an account make grid changes and process it
    #Select an opportunity for an account, make grid changes, and process it
    [tags]  unstable
    Set Window Size    1024    768
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
    &{account} =     API Create Organization Account
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    &{opportunity} =     API Create Opportunity   &{account}[Id]    Donation  StageName=Prospecting    Amount=100    CloseDate=${date}    
    Select App Launcher Tab   Batch Gift Entry
    # Click Link  &{batch}[Name]
    Click Link With Text    &{batch}[Name]
    Wait For Locator    bge.title    Batch Gift Entry
    Select Value From BGE DD    Donor Type    Account
    Populate Field By Placeholder    Search Accounts    &{account}[Name]
    Click Link    &{account}[Name]
    Click Link    Review Donations
    Click BGE Button    Update this Opportunity
    Fill BGE Form
    ...                       Donation Amount=20
    Click Element With Locator    bge.field-input    Donation Date
    Click BGE Button    Today
    Click BGE Button       Save
    Reload Page
    Sleep    2
    Verify Row Count    1
    Page Should Contain Link    &{opportunity}[Name]
    Wait For Locator    bge.edit_button    Donation Amount
    Click BGE Edit Button    Donation Amount   
    Wait For Locator    bge.edit_field  
    Populate BGE Edit Field    Donation Amount    10
    Click BGE Button       Process Batch
    Select Frame With Title    NPSP Data Import
    Click Button With Value   Begin Data Import Process
    Wait For Locator    data_imports.status    Completed
    Click Button With Value   Close
    Go To Record Home    &{opportunity}[Id]
    Confirm Value    Amount    $10.00    Y 
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Confirm Value    Close Date    ${opp_date}    Y 
    Confirm Value    Stage    Closed Won    Y 
    
    