*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Library         DateTime
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${batch}[Id]
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Match Based on Number of Days from Donation Date Functionality
    [Documentation]    The number of days from donation date field on the BGE wizard allows matching to be made by providing
    ...                a margin of error on the Donation Date field for a record. If the gift created is within range of that date,
    ...                gift is matched to the existing donation
    [tags]             stable       quadrant:q3
    Go To Page                  Details      DataImportBatch__c         object_id=${batch}[Id]
    Current Page Should Be      Details      DataImportBatch__c
    Select Value From BGE DD    Donor Type    Account
    Wait Until Keyword Succeeds          1 minute
        ...                              5 seconds
        ...                              Search Field And Perform Action    Search Accounts    ${account}[Name]

    Click Link With Text    Review Donations
    Page Should Contain    ${opp}[Name]
    ${pay_no}    Get BGE Card Header    ${opp}[Name]
    Log To Console    ${pay_no}
    Click Button With Title     Close this window
    Wait Until Modal Is Closed
    Click Element With Locator    bge.field-input    Donation Amount
    Fill BGE Form
    ...                       Donation Amount=100
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Verify Row Count    1
    Page Should Contain Link    ${pay_no}
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    # Verify that the gift matched to existing opportunity and updated it to closed won status with gift date and payment is paid
    Go To Page      Details     Opportunity     object_id=${opp}[Id]
    Navigate To And Validate Field Value    Amount    contains    $100.00
    Navigate To And Validate Field Value    Close Date    contains    ${date}
    Navigate To And Validate Field Value    Stage    contains    Closed Won
    Select Tab    Related
    Load Related List    GAU Allocations
    Click Span Button    ${pay_no}
    Current Page Should Be    Details    npe01__OppPayment__c
    ${pay_id}    Save Current Record ID For Deletion      npe01__OppPayment__c
    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay_id}
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${api_date}
    ...    npe01__Paid__c=True

*** Keywords ***
Setup Test Data
    ${ns} =  Get NPSP Namespace Prefix
    Set Suite Variable    ${ns}
    &{batch} =       API Create DataImportBatch
    ...    ${ns}Batch_Process_Size__c=50
    ...    ${ns}Donation_Date_Range__c=5.0
    ...    ${ns}Batch_Description__c=Created via API
    ...    ${ns}Donation_Matching_Behavior__c=Single Match or Create
    ...    ${ns}Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c
    ...    ${ns}RequireTotalMatch__c=false
    ...    ${ns}Run_Opportunity_Rollups_while_Processing__c=true
    ...    ${ns}GiftBatch__c=true
    ...    ${ns}Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}]

    Set Suite Variable    &{batch}
    &{account} =     API Create Organization Account
    Set Suite Variable    &{account}
    ${api_date} =     Get Current Date    result_format=%Y-%m-%d
    Set Suite Variable    ${api_date}
    ${date} =     Get Current Date    result_format=%-m/%-d/%Y
    Set Suite Variable    ${date}
    ${opp_date} =     Get Current Date    result_format=%Y-%m-%d    increment=2 days
    &{opp} =     API Create Opportunity   ${account}[Id]    Donation
    ...    StageName=Prospecting
    ...    Amount=100
    ...    CloseDate=${opp_date}
    ...    npe01__Do_Not_Automatically_Create_Payment__c=false
    ...    Name=${account}[Name] Test 100 Donation
    Set Suite Variable    &{opp}