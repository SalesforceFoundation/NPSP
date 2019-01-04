*** Settings ***

Resource        tests/NPSP.robot
Library           DateTime
Suite Setup     Open Test Browser
#Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Select a payment for a contact make grid changes and process it
    [tags]  unstable
    ${ns} =  Get NPSP Namespace Prefix
    &{batch} =       API Create DataImportBatch    Batch_Process_Size__c=50    Batch_Description__c=Created via API    Donation_Matching_Behavior__c=Single Match or Create    Donation_Matching_Rule__c=donation_amount__c;donation_date__c    RequireTotalMatch__c=false    Run_Opportunity_Rollups_while_Processing__c=false   GiftBatch__c=true    Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}] 
    &{contact} =     API Create Contact
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    &{opportunity} =     API Create Opportunity   &{contact}[AccountId]    Donation  StageName=Prospecting    Amount=100    CloseDate=${date}    npe01__Do_Not_Automatically_Create_Payment__c=false
    Select App Launcher Tab   NPSP Data Import Batches
    Click Link  &{batch}[Name]
    Populate Address    Search Contacts    &{contact}[FirstName] &{contact}[LastName]
    Click Link    &{contact}[FirstName] &{contact}[LastName]
    Click Link    Review Donations
    ${pay_id}    Get BGE Card Header    &{opportunity}[Name]
    Log To Console    ${pay_id}
    Click BGE Button    Update this Payment
    Fill BGE Form
    ...                       Donation Amount=10
    Select BGE Date Picker    Donation Date
    Click BGE Button    Today
    Click BGE Button       Save
    Verify Row Count    1
    Page Should Contain Link    ${pay_id}
    Sleep    2
    Wait For Locator    bge.edit_button    Donation Amount
    Click BGE Edit Button    Donation Amount    
    # Populate BGE Edit Field    Donation Amount    20
    # Click BGE Button       Process Batch
    # Select Frame With Title    NPSP Data Import
    # Click Button With Value   Begin Data Import Process
    # Wait For Locator    data_imports.status    Completed
    # Click Button With Value   Close
    # Go To Record Home    &{opportunity}[Id]
    # Select Tab    Details
    # Confirm Value    Amount    $100.00    Y 
    # ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    # Confirm Value    Close Date    ${opp_date}    Y 
    # Confirm Value    Stage    Prospecting    Y 
    # Click Link    ${pay_id}
    # Confirm Value    Payment Amount    $10.00    Y 
    # Confirm Value    Payment Date    ${opp_date}    Y 
    