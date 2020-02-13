*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
Library         DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Select an opportunity for an account make grid changes and process it
    #Select an opportunity for an account, make grid changes, and process it
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
    &{account} =     API Create Organization Account
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    &{opportunity} =     API Create Opportunity   &{account}[Id]    Donation  StageName=Prospecting    Amount=100    CloseDate=${date}    
    Go To Page                        Listing                      Batch_Gift_Entry
    # Click Link  &{batch}[Name]
    Click Link With Text    &{batch}[Name]
    Wait For Locator    bge.title    Batch Gift Entry
    Select Value From BGE DD    Donor Type    Account
    Search Field By Value    Search Accounts    &{account}[Name]
    Click Link    &{account}[Name]
    Click Link With Text    Review Donations
    Click BGE Button    Update this Opportunity
    Fill BGE Form
    ...                       Donation Amount=20
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Sleep    2
    Verify Row Count    1
    Page Should Contain Link    &{opportunity}[Name]
    Wait For Locator    bge.edit_button    Donation Amount
    Click BGE Edit Button    Donation Amount   
    Wait For Locator    bge.edit_field  
    Populate BGE Edit Field    Donation Amount    10
    Scroll Page To Location    0    0
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    Go To Record Home    &{opportunity}[Id]
    Navigate To And Validate Field Value    Amount    contains    $10.00
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Navigate To And Validate Field Value    Close Date    contains    ${opp_date}
    Navigate To And Validate Field Value    Stage    contains    Closed Won
