*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
Library         DateTime
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create a new account and enter payment information
    #Create a new account and enter payment information, then process batch
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
    Go To Page                        Listing                      Batch_Gift_Entry
    # Click Link  &{batch}[Name]
    Click Link With Text    &{batch}[Name]
    Wait For Locator    bge.title    Batch Gift Entry
    Select Value From BGE DD    Donor Type    Account
    ${acc_name} =  Generate Random String
    Search Field By Value    Search Accounts    ${acc_name}
    Click Element    title:Search Accounts...
    Wait For Locator    record.edit_button    New Account
    Click Element    title=New Account
    Select Record Type         Organization
    Populate Form
    ...                        Account Name=${acc_name}
    Click Modal Button         Save    
    Wait Until Modal Is Closed
    Fill BGE Form
    ...                       Donation Amount=20
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Wait For Locator    bge.title    Batch Gift Entry
    Verify Row Count    1 
    Wait For Locator    bge.edit_button    Donation Amount
    SeleniumLibrary.Element Text Should Be    //td[@data-label="Donation"]//lightning-formatted-url    ${Empty}
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    ${value}    Return Locator Value    bge.value    Donation
    # Click Link    ${value}
    Click Link With Text    ${value}
    Select Window    ${value} | Salesforce    10
    ${opp_name}    Return Locator Value    check_field_spl    Opportunity
    Click Link    ${opp_name}
    Current Page Should Be    Details    Opportunity
    ${opp_id} =           Save Current Record ID For Deletion      Opportunity  
    Select Tab    Details
    Navigate To And Validate Field Value    Amount    contains    $20.00
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Navigate To And Validate Field Value    Close Date    contains    ${opp_date}
    Navigate To And Validate Field Value    Stage    contains    Closed Won
    Click Link With Text    text=${acc_name}
    Current Page Should Be    Details    Account
    ${account_id} =       Save Current Record ID For Deletion      Account
