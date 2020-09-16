*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py

Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${amount}         100
${amount_updated}  50
${msg}            Automation Batch Status Test

*** Keywords ***
Setup Test Data
    [Documentation]     Data setup needed for the testcase. Creates a regular contact
    ...                 and a contact associated with an account.
    &{contact} =    API Create Contact    FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable    &{contact}
    # create an account using create  account api
    &{account} =    API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{account}
    #Create a contact associated with the account ID creaed above
    &{contact2} =        API Create Contact
        ...              FirstName=${faker.first_name()}
        ...              LastName=${faker.last_name()}
        ...              AccountId=${account}[Id]
    Set suite variable   &{contact2}
    ${ns} =  Get NPSP Namespace Prefix
    Set Suite Variable   ${ns}


Edit Default Template To Add Batch Table Columns
    [Documentation]     Edit the default template fields and ensure the status and the right
    ...                 required fields are displayed.
    Go To Page                       Landing                       GE_Gift_Entry
    Click Link                       Templates
    Select Template Action           Default Gift Entry Template   Edit
    Current Page Should Be           Template                      GE_Gift_Entry
    Click Gift Entry Button          Next: Form Fields
    Click Gift Entry Button          Next: Batch Settings
    Add Batch Table Columns          Donor Name                    Donation Amount     Status      Failure Information
    Click Gift Entry Button          Save & Close
    Current Page Should Be           Landing                       GE_Gift_Entry

Process And Validate Batch
    [Documentation]     Process Batch , wait for the data import process is completed
    ...                 Validate the Batch data import status based on the status parameter
    [Arguments]                          ${status}
    Scroll Page To Location              0      0
    Click Gift Entry Button              Process Batch
    Click Data Import Button             NPSP Data Import                button       Begin Data Import Process
    Wait For Batch To Process            BDI_DataImport_BATCH            ${status}
    Click Button With Value              Close
    Current Page Should Be               Form                            Gift Entry


*** Test Cases ***

Test Batch Status Adding Removig Gifts
    [Documentation]                  This test case makes edits to Default gift entry template
    ...                              Adds the status field. Initiates Batch and adds different
    ...                              Gift entries. Validates the different Status messages.

    [tags]                           unstable               W-043100            feature:GE

    Edit Default Template To Add Batch Table Columns
    Go To Page                       Landing                       GE_Gift_Entry
    Click Gift Entry Button          New Batch
    Wait Until Modal Is Open
    Select Template                  Default Gift Entry Template
    Current Page Should Be           Form                          GE_Gift_Entry
    Fill Gift Entry Form
    ...                              Batch Name=${msg}
    ...                              Batch Description=This is a test batch created via automation script
    Click Gift Entry Button          Next
    Click Gift Entry Button          Save
    Current Page Should Be           Form                          Gift Entry

    ${batch_id} =                    Save Current Record ID For Deletion     ${ns}DataImportBatch__c

    Fill Gift Entry Form
    ...                              Donor Type=Contact1
    ...                              Existing Donor Contact=${contact}[Name]
    ...                              Donation Amount=${amount}
    ...                              Donation Date=Today

    Click Special Button             Save & Enter New Gift
    Verify Table Field Values        Batch Gifts
    ...                              Status=Dry Run - Validated

    # Update the gift value and check the value gets  reflected in the table
    Perform Action On Datatable Row   ${contact}[Name]          Open
    Fill Gift Entry Form
     ...                              Donation Amount=${amount_updated}
    Click Special Button              Update
    Verify Table Field Values         Batch Gifts
     ...                              Donation Amount=$${amount_updated}.00
    # Run and validate the Batch data import status

    Process And Validate Batch       Completed
    Verify Table Field Values        Batch Gifts
    ...                              Status=Imported
    # Verify the backend dataimport batch job using the API call
    Verify Expected Values    nonns  DataImportBatch__c    ${batch_id}
    ...                              Batch_Status__c=Completed

    #Scroll to the top of the page, add gift for contact associated with org account
    Scroll Page To Location          0      0
    Fill Gift Entry Form
    ...                              Donor Type=Contact1
    ...                              Existing Donor Contact=${contact2}[Name]
    ...                              Donation Amount=${amount}
    ...                              Donation Date=Today

    Click Special Button             Save & Enter New Gift
    Verify Table Field Values        Batch Gifts
    ...                              Status=Dry Run - Error
    Process And Validate Batch       Errors
    Verify Table Field Values        Batch Gifts
    ...                              Status=Failed

    # Verify the backend dataimport batch job
    Verify Expected Values    nonns  DataImportBatch__c    ${batch_id}
    ...                              Batch_Status__c=Failed - Needs Review

    #Delete the row that has Dry run status and trigger the batch job to see it completed
    Perform Action On Datatable Row  ${contact2}[Name]          Delete

    # Verify the backend dataimport batch job
    Verify Expected Values    nonns  DataImportBatch__c    ${batch_id}
    ...                              Batch_Status__c=Completed

    Process And Validate Batch       Completed
    Verify Table Field Values        Batch Gifts
    ...                              Status=Imported