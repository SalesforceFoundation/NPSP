*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/DataImportPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${batch_id}
...   AND       Query And Store Records To Delete    Opportunity   AccountId=${contact}[AccountId]
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${ns}
${camp_id}

*** Test Cases ***

Create BGE Batch With Custom Fields
    #Create a BGE batch with default values and selecting different types of custom fields for Donation and Payment
    [tags]  stable      quadrant:q3
    # --------------------------------
    # Create Batch With Custom Fields
    # --------------------------------
    ${batch} =           Generate Random String
    Go To Page                        Listing                      Batch_Gift_Entry
    Click BGE Button       New Batch
    Fill BGE Form
    ...                       Name=${batch}
    ...                       Batch Description=This batch is created by Robot.
    Click BGE Button        Next
    Select Multiple Values From Duellist    bge.duellist    Opportunity    Available Fields    new_lookup_campaign    custom_currency    custom_date    custom_number    custom_picklist    custom_text    custom_textarea
    Click Duellist Button    Opportunity    Move selection to Selected Fields
    Execute JavaScript    document.getElementsByClassName('wideListbox slds-form-element')[1].scrollIntoView()
    Select Multiple Values From Duellist    bge.duellist    Payment    Available Fields    custom_email    custom_multipick    custom_phone    custom_url
    Click Duellist Button    Payment    Move selection to Selected Fields
    Click BGE Button        Next
    Click BGE Button        Next
    Click BGE Button        Save
    Wait For Locator    bge.title    Batch Gift Entry
    Verify Title    Batch Gift Entry    ${batch}
    ${ns} =  Get NPSP Namespace Prefix
    Set Global Variable     ${ns}       ${ns}
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
    [tags]  stable      quadrant:q3
    &{contact} =     API Create Contact
    Set Suite Variable    &{contact}
    Store Session Record        Account       ${contact}[AccountId]
    &{campaign} =    API Create Campaign
    Set Global Variable     ${camp_id}       ${campaign}[Id]
    Select Value From BGE DD    Donor Type    Contact
    Wait Until Keyword Succeeds          1 minute
        ...                              5 seconds
        ...                              Search Field And Perform Action    Search Contacts    ${contact}[FirstName] ${contact}[LastName]

    Fill BGE Form
    ...    Donation Amount=100
    ...    custom_currency=20
    ...    custom_number=123
    ...    custom_text=Robot
    ...    custom_email=automation@robot.com
    ...    custom_phone=1234567890
    ...    custom_url=automation.com
    ...    custom_textarea=this is custom batch
    Populate Campaign    Search Campaigns    ${campaign}[Name]
    Select Date From Datepicker    Donation Date    Today
    Select Date From Datepicker    custom_date    Today
    Select Value From BGE DD    custom_picklist    2
    Select Multiple Values From Duellist    bge.duellist2    custom_multipick    Available    1    2    3
    Click Duellist Button    custom_multipick    Move selection to Chosen
    Click BGE Button    Save
    Click BGE Button       Process Batch
    Click Data Import Button    NPSP Data Import    button    Begin Data Import Process
    Wait For Batch To Process    BDI_DataImport_BATCH    Completed
    Click Button With Value      Close
    Reload Page
    Wait Until Element Is Visible    text:All Gifts
    Verify Row Count    1


Verify Custom Fields on Payment and Donation
    [tags]  stable      quadrant:q3
    ${date} =     Get Current Date    result_format=%Y-%m-%d
    ${value}    Return Locator Value    bge.value    Donation
    Click Link With Text    ${value}
    Select Window    ${value} | Salesforce    10
    Current Page Should Be    Details    npe01__OppPayment__c
    ${pay_id}    Save Current Record ID For Deletion      npe01__OppPayment__c
    ${org_ns} =  Get Org Namespace Prefix
    &{payment} =     Salesforce Get  npe01__OppPayment__c  ${pay_id}
    Verify Expected Values    nonns    npe01__OppPayment__c    ${pay_id}
    ...    npe01__Payment_Amount__c=100.0
    ...    npe01__Payment_Date__c=${date}
    ...    npe01__Paid__c=True
    ...    ${org_ns}custom_email__c=automation@robot.com
    ...    ${org_ns}custom_multipick__c=1;2;3
    ...    ${org_ns}custom_phone__c=1234567890
    ...    ${org_ns}custom_url__c=automation.com
    Verify Expected Values    nonns    Opportunity    ${payment}[npe01__Opportunity__c]
    ...    Amount=100.0
    ...    CloseDate=${date}
    ...    StageName=Closed Won
    ...    ${org_ns}custom_currency__c=20.0
    ...    ${org_ns}custom_date__c=${date}
    ...    ${org_ns}custom_lookup__c=${camp_id}
    ...    ${org_ns}custom_number__c=123.0
    ...    ${org_ns}custom_picklist__c=2
    ...    ${org_ns}custom_textarea__c=this is custom batch
    ...    ${org_ns}custom_text__c=Robot