*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Library         DateTime
Suite Setup     Open Test Browser
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${batch}[Id]
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Opportunity is Autoclosed when Overpaid
    [Documentation]    Create Open Opportunity and apply new payment of amount more than opportunity amount
    ...                and confirm that opportunity is closed when batch is processed
    [tags]      stable      quadrant:q3
    ${ns} =  Get NPSP Namespace Prefix
    Set Suite Variable    ${ns}
    &{batch} =       API Create DataImportBatch
    ...    ${ns}Batch_Process_Size__c=50
    ...    ${ns}Batch_Description__c=Created via API
    ...    ${ns}Donation_Matching_Behavior__c=Single Match or Create
    ...    ${ns}Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c
    ...    ${ns}RequireTotalMatch__c=false
    ...    ${ns}Run_Opportunity_Rollups_while_Processing__c=true
    ...    ${ns}GiftBatch__c=true
    ...    ${ns}Active_Fields__c=[{"label":"Donation Amount","name":"${ns}Donation_Amount__c","sObjectName":"Opportunity","defaultValue":null,"required":true,"hide":false,"sortOrder":0,"type":"number","options":null},{"label":"Donation Date","name":"${ns}Donation_Date__c","sObjectName":"Opportunity","defaultValue":null,"required":false,"hide":false,"sortOrder":1,"type":"date","options":null}]
    Set Suite Variable    &{batch}
    &{contact} =     API Create Contact
    Store Session Record      Account    ${contact}[AccountId]
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    &{opportunity} =     API Create Opportunity   ${contact}[AccountId]    Donation
    ...    StageName=Prospecting
    ...    Amount=100
    ...    CloseDate=${date}
    ...    Name=${contact}[LastName] Test Donation
    Go To Page                  Details      DataImportBatch__c         object_id=${batch}[Id]
    Current Page Should Be      Details      DataImportBatch__c
    Wait Until Keyword Succeeds          1 minute
        ...                              5 seconds
        ...                              Search Field And Perform Action    Search Contacts    ${contact}[FirstName] ${contact}[LastName]

    Click Link With Text    Review Donations
    Click BGE Button    Apply New Payment
    Page Should Contain     You are currently applying a new Payment to Opportunity:${opportunity}[Name]
    Fill BGE Form
    ...                       Donation Amount=101
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Verify Row Count    1
    Page Should Contain Link    ${opportunity}[Name]
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    ${value}    Return Locator Value    bge.value    Donation
    # Click Link    ${value}
    Click Link With Text    ${value}
    Select Window    ${value} | Salesforce    10
    Current Page Should Be    Details    npe01__OppPayment__c
    ${pay_id}    Save Current Record ID For Deletion      npe01__OppPayment__c
    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay_id}
    ...    npe01__Payment_Amount__c=101.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Paid__c=True
    Go To Page      Details     Opportunity     object_id=${opportunity}[Id]
    Navigate To And Validate Field Value    Amount    contains    $100.00
    ${opp_date} =     Get Current Date    result_format=%-m/%-d/%Y
    Navigate To And Validate Field Value    Close Date    contains    ${opp_date}
    Navigate To And Validate Field Value    Stage    contains    Closed Won