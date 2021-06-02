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
${AMOUNT}         100
${AMOUNT_UPDATED}  50
${MSG}            Automation Batch Status Test

*** Keywords ***
Setup Test Data
    [Documentation]     Data setup needed for the testcase. Creates a regular contact
    ...                 and a contact associated with an account.
    &{CONTACT} =        API Create Contact    FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable  &{CONTACT}
    # create an account using create  account api
    &{ACCOUNT} =        API Create Organization Account    Name=${faker.company()}
    Set suite variable  &{ACCOUNT}
    #Create a contact associated with the account ID creaed above
    &{CONTACT2} =       API Create Contact
        ...             FirstName=${faker.first_name()}
        ...             LastName=${faker.last_name()}
        ...             AccountId=${ACCOUNT}[Id]
    Set suite variable  &{CONTACT2}
    ${NS} =             Get NPSP Namespace Prefix
    Set Suite Variable  ${NS}


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
    Wait Until BGE Batch Processes       ${MSG}
    Current Page Should Be               Form                            Gift Entry


*** Test Cases ***

Test Batch Status Adding Removig Gifts
    [Documentation]                  This test case makes edits to Default gift entry template
    ...                              Adds the status field. Initiates Batch and adds different
    ...                              Gift entries. Validates the different Status messages.

    [tags]                           unstable               W-043100            feature:GE

    Edit Default Template To Add Batch Table Columns
    Go To Page                       Landing                       GE_Gift_Entry
    Create Gift Entry Batch          Default Gift Entry Template   ${MSG}
    Current Page Should Be           Form                          Gift Entry

    ${BATCH_ID} =                    Save Current Record ID For Deletion     ${NS}DataImportBatch__c

    Fill Gift Entry Form
    ...                              Donor Type=Contact1
    ...                              Existing Donor Contact=${CONTACT}[Name]
    ...                              Donation Amount=${AMOUNT}
    ...                              Donation Date=Today

    Click Gift Entry Button          Save & Enter New Gift
    Verify Table Field Values        ${CONTACT}[Name]   True
    ...                              Status=Dry Run - Validated

    # Update the gift value and check the value gets  reflected in the table
    Perform Action On Datatable Row   ${CONTACT}[Name]          Open
    Fill Gift Entry Form
     ...                              Donation Amount=${AMOUNT_UPDATED}
    Click Special Button              Update
    Verify Table Field Values         ${CONTACT}[Name]   True
     ...                              Donation Amount=$${AMOUNT_UPDATED}.00
    # Run and validate the Batch data import status
    Verify Expected Values    nonns   ${NS}DataImportBatch__c    ${BATCH_ID}
    ...                               ${NS}Batch_Status__c=Open

    Process And Validate Batch        Completed
    Verify Table Field Values         ${CONTACT}[Name]   True
    ...                               Status=Imported
    # Verify the backend dataimport batch job using the API call
    Verify Expected Values    nonns   ${NS}DataImportBatch__c    ${BATCH_ID}
    ...                               ${NS}Batch_Status__c=Completed

    #Scroll to the top of the page, add gift for contact associated with org account
    Scroll Page To Location           0      0
    Click Element                    npsp:gift_entry.collapse_header
    Fill Gift Entry Form
    ...                              Donor Type=Contact1
    ...                              Existing Donor Contact=${CONTACT2}[Name]
    ...                              Donation Amount=${AMOUNT}
    ...                              Donation Date=Today

    Click Gift Entry Button          Save & Enter New Gift
    Verify Table Field Values        ${CONTACT2}[Name]   True
    ...                              Status=Dry Run - Error
    Process And Validate Batch       Errors
    Verify Table Field Values        ${CONTACT2}[Name]   True
    ...                              Status=Failed

    # Verify the backend dataimport batch job
    Verify Expected Values    nonns  ${NS}DataImportBatch__c    ${BATCH_ID}
    ...                              ${NS}Batch_Status__c=Failed - Needs Review

    #Delete the row that has Dry run status and trigger the batch job to see it completed
    Perform Action On Datatable Row  ${CONTACT2}[Name]          Delete

    # Verify the backend dataimport batch job
    Verify Expected Values    nonns  ${NS}DataImportBatch__c    ${BATCH_ID}
    ...                              ${NS}Batch_Status__c=Completed