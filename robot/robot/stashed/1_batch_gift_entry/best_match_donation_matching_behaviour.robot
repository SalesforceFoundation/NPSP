*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Library         DateTime
Suite Setup     Run keywords
...             Open Test Browser
...             Add instance to suite metadata
...             Setup Test Data
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${batch}[Id]
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Best Match Donation Matching Behaviour
    [tags]                      stable      quadrant:q3
    Go To Page                  Details     DataImportBatch__c         object_id=${batch}[Id]
    Current Page Should Be      Details     DataImportBatch__c
    Select Value From BGE DD    Donor Type    Account
    Wait Until Keyword Succeeds          1 minute
        ...                              5 seconds
        ...                              Search Field And Perform Action   Search Accounts    ${account}[Name]
    Click Link With Text    Review Donations
    Page Should Contain    ${opp_match}[Name]
    Page Should Contain    ${opp_dont_match}[Name]
    Click Button    title:Close this window
    Wait Until Modal Is Closed
    Click Element With Locator    bge.field-input    Donation Amount
    Fill BGE Form
    ...                       Donation Amount=100
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Verify Row Count    1
    Page Should Contain Link    ${pay_match}[Name]
    Scroll Page To Location    0    0
    Search Field And Perform Action   Search Accounts    ${account}[Name]
    Click Element With Locator    bge.field-input    Donation Amount
    Fill BGE Form
    ...                       Donation Amount=200
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Sleep    5
    Verify Row Count    2
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    @{value}    Return List    bge.value    Donation
    #Click Link    ${value}
    Click Link With Text    ${value}[0]
    # Verify that a new payment and opportunity are created for the gift in closed won stage
    Select Window    ${value}[0] | Salesforce    7
    Current Page Should Be    Details    npe01__OppPayment__c
    ${pay_id}    Save Current Record ID For Deletion      npe01__OppPayment__c
    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay_id}
    ...    npe01__Payment_Amount__c=200.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Paid__c=True
    &{new_payment} =    API Query Record     npe01__OppPayment__c      Id=${pay_id}
    Store Session Record      Opportunity             ${new_payment}[npe01__Opportunity__c]
    Verify Expected Values    nonns    Opportunity    ${new_payment}[npe01__Opportunity__c]
    ...                                  Amount=200.0
    ...                                  CloseDate=${date}
    ...                                  StageName=Closed Won
    # Verify that the gift matched to existing opportunity and updated it to closed won status and payment is paid
    Verify Expected Values    nonns    Opportunity    ${opp_match}[Id]
    ...                                  Amount=100.0
    ...                                  CloseDate=${date}
    ...                                  StageName=Closed Won

    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay_match}[Id]
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Paid__c=True
    # Verify that the opportunity that does not match is still in prospecting stage
    Verify Expected Values    nonns    Opportunity    ${opp_dont_match}[Id]
    ...                                  Amount=50.0
    ...                                  CloseDate=${date}
    ...                                  StageName=Prospecting

*** Keywords ***
Setup Test Data
    ${ns} =  Get NPSP Namespace Prefix
    Set Suite Variable    ${ns}
    &{batch} =       API Create DataImportBatch
    ...    ${ns}Batch_Process_Size__c=50
    ...    ${ns}Batch_Description__c=Created via API
    ...    ${ns}Donation_Matching_Behavior__c=Best Match or Create
    ...    ${ns}Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c
    ...    ${ns}RequireTotalMatch__c=false
    ...    ${ns}Run_Opportunity_Rollups_while_Processing__c=true
    ...    ${ns}GiftBatch__c=true
    ...    ${ns}Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}]

    Set Suite Variable    &{batch}
    &{account} =     API Create Organization Account
    Set Suite Variable    &{account}
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    Set Suite Variable    ${date}
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Set Suite Variable    ${opp_date}
    &{opp_match} =     API Create Opportunity   ${account}[Id]    Donation
    ...    StageName=Prospecting
    ...    Amount=100
    ...    CloseDate=${date}
    ...    npe01__Do_Not_Automatically_Create_Payment__c=false
    ...    Name=${account}[Name] Test 100 Donation
    Set Suite Variable    &{opp_match}
    &{pay_match} =         API Query Record         npe01__OppPayment__c      npe01__Opportunity__c=${opp_match}[Id]
    Set Suite Variable    &{pay_match}
    &{opp_dont_match} =     API Create Opportunity   ${account}[Id]    Donation
    ...    StageName=Prospecting
    ...    Amount=50
    ...    CloseDate=${date}
    ...    npe01__Do_Not_Automatically_Create_Payment__c=false
    ...    Name=${account}[Name] Test 50 Donation
    Set Suite Variable    &{opp_dont_match}
    &{pay_dontmatch} =         API Query Record         npe01__OppPayment__c      npe01__Opportunity__c=${opp_dont_match}[Id]
    Set Suite Variable    &{pay_dontmatch}