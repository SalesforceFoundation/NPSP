*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/DataImportPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${batch_id}
...   AND       Query And Store Records To Delete    Opportunity   AccountId=${contact}[AccountId]
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

BGE Batch With Default Values
    #Create a BGE batch with default values
    [tags]  stable
    ${batch} =              Generate Random String
    Go To Page              Listing                      Batch_Gift_Entry
    Click BGE Button        New Batch
    Fill BGE Form
    ...                     Name=${batch}
    ...                     Batch Description=This batch is created by Robot
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Save
    Wait For Locator    bge.title    Batch Gift Entry
    Verify Title    Batch Gift Entry    ${batch}
    ${ns} =  Get NPSP Namespace Prefix
    Set Suite Variable  ${ns}
    Current Page Should Be    Details    DataImportBatch__c
    ${batch_id}    Save Current Record ID For Deletion      ${ns}DataImportBatch__c
    Set Suite Variable    ${batch_id}
    Verify Expected Batch Values    ${batch_id}
    ...    Batch_Process_Size__c=50.0
    ...    Donation_Date_Range__c=0.0
    ...    Donation_Matching_Behavior__c=Single Match or Create
    ...    Donation_Matching_Implementing_Class__c=None
    ...    Donation_Matching_Rule__c=${ns}donation_amount__c;${ns}donation_date__c
    ...    Expected_Count_of_Gifts__c=0.0
    ...    Expected_Total_Batch_Amount__c=0.0
    ...    Post_Process_Implementing_Class__c=None
    ...    RequireTotalMatch__c=False
    ...    Run_Opportunity_Rollups_while_Processing__c=True
Create New gift and process batch and validate
    [tags]  stable
    &{contact} =     API Create Contact
    Set Suite Variable    &{contact}
    Store Session Record        Account       ${contact}[AccountId]
    Select Value From BGE DD    Donor Type    Contact
    Wait Until Keyword Succeeds          1 minute
    ...                          5 seconds
    ...                          Search Field And Perform Action    Search Contacts    ${contact}[FirstName] ${contact}[LastName]

    Fill BGE Form    Donation Amount=100
    Select Date From Datepicker    Donation Date    Today
    Click BGE Button       Save
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value   Close
    Wait Until Element Is Visible    text:All Gifts
    Verify Row Count    1
    Page Should Contain    PMT-

