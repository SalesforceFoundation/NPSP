*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${NS}DataImport__c   ${NS}NPSP_Data_Import_Batch__c=${BATCH_Id}
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]       Create contact, generate random names for template and batch, and set up NPSP namespace prefix.

    &{CONTACT1} =          API Create Contact       FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable     &{CONTACT1}
    Store Session Record   Account                  ${CONTACT1}[AccountId]
    &{CONTACT2} =          API Create Contact       FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable     &{CONTACT2}
    Store Session Record   Account                  ${CONTACT2}[AccountId]
    ${BATCH_NAME} =        Generate Random String
	Set suite variable     ${BATCH_NAME}
    ${NS} =                Get NPSP Namespace Prefix
    Set suite variable     ${NS}

*** Test Cases ***
Progress Bar and Totals in Batch
    [Documentation]          Create a batch and give values to Expected amount and count of gits fields, and check Required Expected totals Match checkbox .   
    ...                      Verify progress bar apprear with total amount and count of gifts in batch form.    
    ...                      Verify I should not be able to process batch until total git amount and count of gifts matches.    
    ...                      Verify the progress bar get updated after deleting one of the saved gifts. 

    [tags]                                 unstable      feature:GE        W-8279400

    Go To Page                             Landing                         GE_Gift_Entry
    Click Gift Entry Button                New Batch
    Wait Until Modal Is Open
    Select Template                        Default Gift Entry Template
    Load Page Object                       Form         Gift Entry
    Fill Gift Entry Form
    ...                                    Batch Name=${BATCH_NAME}
    ...                                    Expected Count of Gifts=2
    ...                                    Expected Total Batch Amount=50
    ...                                    Require Expected Totals Match=check
    Click Gift Entry Button                Next
    Click Gift Entry Button                Save
    Current Page Should Be                 Form          Gift Entry 
    ${BATCH_Id} =                          Save Current Record ID For Deletion                     ${NS}DataImportBatch__c
    Set Suite Variable                     ${BATCH_Id}
    Fill Gift Entry Form
    ...                                    Donor Type=Contact1
    ...                                    Existing Donor Contact=${CONTACT1}[Name]
    ...                                    Donation Date=Today
    ...                                    Donation Amount=25
    Click Gift Entry Button                Save & Enter New Gift
    Wait Until Loading Is Complete
    Verify Progress Bar                    Count of Gifts=1
    ...                                    Total Batch Amount=$25.00
    Click Gift Entry Button                Process Batch
    Verify Batch Error                     Error         The expected and total number of gifts and amount of gifts must match before you can process this batch.
    Fill Gift Entry Form
    ...                                    Donor Type=Contact1
    ...                                    Existing Donor Contact=${CONTACT2}[Name]
    ...                                    Donation Date=Today
    ...                                    Donation Amount=25
    Click Gift Entry Button                Save & Enter New Gift
    Wait Until Loading Is Complete
    Verify Progress Bar                    Count of Gifts=2
    ...                                    Total Batch Amount=$50.00
    Click Gift Entry Button                Process Batch
    Wait Until Loading Is Complete
    Click Data Import Button               NPSP Data Import       button       Cancel
    Current Page Should Be                 Form                   Gift Entry 
    Perform Action On Datatable Row   	   ${CONTACT1}[Name]      Delete
    Verify Progress Bar                    Count of Gifts=1
    ...                                    Total Batch Amount=$25.00
