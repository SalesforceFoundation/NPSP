*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/ContactPageObject.py
Library         DateTime
Suite Setup     Open Test Browser
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${batch}[Id]
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Dont select match for contact new donation with grid changes
    #Enter a donation for a contact that has an exact opp match, don't select the match, make grid changes, and process batch
    [tags]  stable
    ${ns} =  Get NPSP Namespace Prefix
    Set Suite Variable      ${ns}
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
    &{opportunity} =     API Create Opportunity   ${contact}[AccountId]    Donation  StageName=Prospecting    Amount=100    CloseDate=${date}
    Go To Page                  Details      DataImportBatch__c         object_id=${batch}[Id]
    Current Page Should Be      Details      DataImportBatch__c
    Select Value From BGE DD    Donor Type    Contact
    Wait Until Keyword Succeeds          1 minute
        ...                              5 seconds
        ...                              Search Field And Perform Action    Search Contacts    ${contact}[FirstName] ${contact}[LastName]

    Page Should Contain Link    Review Donations
    Click Element With Locator    bge.field-input    Donation Amount
    Fill BGE Form
    ...                       Donation Amount=100
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Sleep    2
    Verify Row Count    1
    Page Should Contain Link    ${opportunity}[Name]
    Wait For Locator    bge.edit_button    Donation Amount
    Click BGE Edit Button    Donation Amount
    Wait For Locator    bge.edit_field
    Populate BGE Edit Field    Donation Amount    20
    Click Element With Locator    span    Donation Date
    Wait Until Element Is Not Visible    //span[contains(@class,'toastMessage')]
    Page Should Not Contain Link    ${opportunity}[Name]
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    Verify Expected Values    nonns    Opportunity    ${opportunity}[Id]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Prospecting
    ${value}    Return Locator Value    bge.value    Donation
    # Click Link    ${value}
    Click Link With Text    ${value}
    Select Window    ${value} | Salesforce    10
    ${opp_name}    Return Locator Value    check_field_spl    Opportunity
    Click Link    ${opp_name}
    Current Page Should Be    Details    Opportunity
    ${newopp_id}    Save Current Record ID For Deletion      Opportunity
    Verify Expected Values    nonns    Opportunity    ${newopp_id}
    ...    Amount=20.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    Go To Page      Details        Contact        object_id=${contact}[Id]
    Validate Related Record Count     Opportunities     2



