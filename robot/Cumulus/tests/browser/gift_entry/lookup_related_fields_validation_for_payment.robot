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

*** Variables ***
&{PAYMENT_REF}             Default Value=123abc
&{PAYMENT_METHOD}          Default Value=Cash
&{PAID}                    Default Value=False

*** Keywords ***
Setup Test Data
    [Documentation]       Create contact, opportunity, get current date and npsp
    ...                   generate random names for template and batch.

    &{CONTACT} =          API Create Contact       FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable    &{CONTACT}
    Store Session Record  Account                  ${CONTACT}[AccountId]
    ${DATE} =             Get Current Date         result_format=%Y-%m-%d
    Set suite variable    ${DATE}
    &{OPPORTUNITY} =      API Create Opportunity   ${CONTACT}[AccountId]           Donation
    ...                   StageName=Pledged
    ...                   Amount=200
    ...                   CloseDate=${DATE}
    ...                   Name=${CONTACT}[Name] Donation
    Set suite variable    &{OPPORTUNITY}
    &{PAYMENT1} =         API Create Payment            ${OPPORTUNITY}[Id]
    ...                                  npe01__Payment_Amount__c=100.0
    ...                                  npe01__Scheduled_Date__c=${DATE}
    Set suite variable    &{PAYMENT1}
    &{PMT_IMP} =          Create Dictionary         Default Value=${PAYMENT1}[Name]
    Set Suite Variable    &{PMT_IMP}
    &{PAYMENT2} =         API Create Payment            ${OPPORTUNITY}[Id]
    ...                                  npe01__Payment_Amount__c=300.0
    ...                                  npe01__Scheduled_Date__c=${DATE}
    Set suite variable    &{PAYMENT2}
    ${TEMPLATE_NAME} =    Generate Random String
	Set suite variable    ${TEMPLATE_NAME}
    ${BATCH_NAME} =       Generate Random String
	Set suite variable    ${BATCH_NAME}
    ${UI_DATE} =          Get Current Date         result_format=%b %-d, %Y
    Set suite variable    ${UI_DATE}
    ${NS} =               Get NPSP Namespace Prefix
    Set suite variable    ${NS}

*** Test Cases ***
Lookup Related Fields Validation for Payment
    [Documentation]          Create template with different default values in payment imported.
    ...                      Verify  payment related fields are autopopulated in gift entry form.
    ...                      When batch created and contact is selected, select payment from Review Donations and verifies related values are autopopulated correctly.
    ...                      Edit the batch and clear out template values, then verify fields are empty.
    ...                      When a gift is saved verify that the valus are displayed in table row correctly.
    ...                      When a batch is saved with a gift, open the batch and verify the values are displayed in the form.
    [tags]                                 feature:GE        W-8523468

    Go To Page                             Landing                         GE_Gift_Entry
    Click Link                             Templates
    Click Gift Entry Button                Create Template
    Current Page Should Be                 Template                        GE_Gift_Entry
    Enter Value In Field
    ...                                    Template Name=${TEMPLATE_NAME}
    ...                                    Description=This Template is created by automation script
    Click Gift Entry Button                Next: Form Fields
    Perform Action On Object Field         select          Payment         Paid
    Perform Action On Object Field         select          Payment           Payment Imported
    Fill Template Form
    ...                                    Payment: Paid=&{PAID}
    ...                                    Payment: Check/Reference Number=&{PAYMENT_REF}
    ...                                    Data Import: Payment Imported=&{PMT_IMP}
    ...                                    Payment: Payment Method=&{PAYMENT_METHOD}
    Click Gift Entry Button                Next: Batch Settings
    Add Batch Table Columns
    ...                                    Payment: Check/Reference Number
    ...                                    Payment: Payment Method
    ...                                    Payment: Paid
    ...                                    Data Import: Payment Imported
    Click Gift Entry Button                Save & Close
    Current Page Should Be                 Landing                         GE_Gift_Entry
    Click Link                             Templates
    Wait Until Page Contains               ${TEMPLATE_NAME}
    Store Template Record Id               ${TEMPLATE_NAME}
    Click Gift Entry Button                New Batch
    Wait Until Modal Is Open
    Select Template                        ${TEMPLATE_NAME}
    Load Page Object                       Form         Gift Entry
    Enter Value In Field
    ...                                    Batch Name=${BATCH_NAME}
    Click Gift Entry Button                Next
    Click Gift Entry Button                Save
    Current Page Should Be                 Form                             Gift Entry          title=Gift Entry Form
    Verify Field Default Value
    ...                                    Payment: Check/Reference Number=123abc
    ...                                    Payment: Payment Method=Cash
    ...                                    Payment: Paid=False
    ...                                    Data Import: Payment Imported=${PAYMENT1}[Name]
    Fill Gift Entry Form
    ...                                    Data Import: Donation Donor=Contact1
    ...                                    Data Import: Contact1 Imported=${CONTACT}[Name]
    Click Button                           Review Donations
    Wait Until Modal Is Open
    Click Button                           npsp:gift_entry.id:Update this Payment ${PAYMENT2}[Name]
    Verify Field Default Value
    ...                                    Data Import: Donation Donor=Contact1
    ...                                    Data Import: Contact1 Imported=${CONTACT}[Name]
    ...                                    Opportunity: Close Date=${UI_DATE}
    ...                                    Opportunity: Amount=$300.00
    ...                                    Payment: Check/Reference Number=123abc
    ...                                    Payment: Payment Method=Cash
    ...                                    Payment: Paid=False
    ...                                    Data Import: Payment Imported=${PAYMENT2}[Name]
    Click Gift Entry Button                Save & Enter New Gift
    Verify Table Field Values              Batch Gifts
    ...                                    Data Import: Donation Donor=Contact1
    ...                                    Data Import: Contact1 Imported=${CONTACT}[Name]
    ...                                    Opportunity: Close Date=${UI_DATE}
    ...                                    Opportunity: Amount=$300.00
    ...                                    Payment: Check/Reference Number=123abc
    ...                                    Payment: Payment Method=Cash
    ...                                    Payment: Paid=False
    ...                                    Data Import: Payment Imported=${PAYMENT2}[Name]
    Click Gift Entry Button                Edit Batch Info
    Click Gift Entry Button                Next
    Current Page Should Be                 Form                   Gift Entry          title=Gift Entry Form
    Clear Form Fields
    ...                                    Payment: Paid=--None--
    ...                                    Payment: Check/Reference Number=
    ...                                    Payment: Payment Method=Check
    Clear Lookup Value
    ...                                    Data Import: Payment Imported
    Click Gift Entry Button                Wizard Save
    ${BATCH_Id} =                          Save Current Record ID For Deletion                     ${NS}DataImportBatch__c
    Set Suite Variable                     ${BATCH_Id}
    Wait Until Modal Is Closed
    Verify Field Default Value
    ...                                    Payment: Check/Reference Number=
    ...                                    Payment: Paid=--None--
    ...                                    Payment: Payment Method=Check
    ...                                    Data Import: Payment Imported=
    Perform Action On Datatable Row   	    ${CONTACT}[Name]                Open
    Verify Field Default Value
    ...                                    Data Import: Donation Donor=Contact1
    ...                                    Data Import: Contact1 Imported=${CONTACT}[Name]
    ...                                    Opportunity: Close Date=${UI_DATE}
    ...                                    Opportunity: Amount=$300.00
    ...                                    Payment: Check/Reference Number=123abc
    ...                                    Payment: Payment Method=Cash
    ...                                    Payment: Paid=False
    ...                                    Data Import: Payment Imported=${PAYMENT2}[Name]
