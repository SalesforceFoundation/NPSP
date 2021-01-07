*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
...             robot/Cumulus/resources/DataImportPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
&{DATE}               Default Value=Today
&{PAYMENT}            Default Value=Credit Card
&{TEXT}               Default Value=text
&{RECORD_TYPE}        Default Value=Major Gift

*** Keywords ***
Setup Test Data
    [Documentation]		  Setup test data: Create Contacts, get current/future dates,
    ...                   generate random names for template and batch,
    ...                   and set up NPSP namespace prefix.

	&{CONTACT} =          API Create Contact    FirstName=${faker.first_name()}     LastName=${faker.last_name()}
    Store Session Record  Account               ${CONTACT}[AccountId]
    Set suite variable    &{CONTACT}
    &{CONTACT2} =         API Create Contact    FirstName=${faker.first_name()}          LastName=${faker.last_name()}
    Store Session Record  Account               ${CONTACT2}[AccountId]
    Set suite variable    &{CONTACT2}
    ${FUT_DATE} =         Get Current Date      result_format=%b %-d, %Y        increment=2 days
    Set suite variable    ${FUT_DATE}
    ${UI_DATE} =          Get Current Date      result_format=%b %-d, %Y
    Set suite variable    ${UI_DATE}
    ${TEMPLATE_NAME} =    Generate Random String
	Set suite variable    ${TEMPLATE_NAME}
    ${BATCH_NAME} =       Generate Random String
	Set suite variable    ${BATCH_NAME}
    ${NS} =               Get NPSP Namespace Prefix
    Set suite variable    ${NS}
*** Test Cases ***
Batch Template Default values Setting
    [Documentation]                 Set default values in batch template and verify they auto poputale in batch for.
    ...                             Change default values in batch template and verify the auto poputale in batch form.
    ...                             Leave default values blank and verify they do not auto popuate in batch form

    [Tags]                           unstable               feature:GE          W-8279550

    Go To Page                       Landing                GE_Gift_Entry
    Click Link                       Templates
    Click Gift Entry Button          Create Template
    Current Page Should Be           Template               GE_Gift_Entry
    Enter Value In Field
    ...                              Template Name=${TEMPLATE_NAME}
    ...                              Description=Template with default
    Click Gift Entry Button          Next: Form Fields
    Perform Action On Object Field   select                 Opportunity          custom_text
    Perform Action On Object Field   select                 Opportunity          Record Type ID
    Fill Template Form
    ...                              Opportunity: Close Date=&{DATE}
    ...                              Payment: Payment Method=&{PAYMENT}
    ...                              Opportunity: custom_text=&{TEXT}
    ...                              Opportunity: Record Type ID=&{RECORD_TYPE}
    Click Gift Entry Button          Next: Batch Settings
    Add Batch Table Columns          Payment: Payment Method    Opportunity: custom_text         Opportunity: Record Type
    Click Gift Entry Button          Save & Close
    Click Link                       Templates
    Store Template Record Id         ${TEMPLATE_NAME}
    Click Gift Entry Button          New Batch
    Wait Until Modal Is Open
    Select Template                  ${TEMPLATE_NAME}
    Load Page Object                 Form         Gift Entry
    Enter Value In Field
    ...                              Batch Name=${BATCH_NAME}
    Click Gift Entry Button          Next
    Verify Field Default Value
    ...                              Opportunity: Close Date=${UI_DATE}
    ...                              Payment: Payment Method=Credit Card
    ...                              Opportunity: custom_text=text
    ...                              Opportunity: Record Type=Major Gift
    Click Gift Entry Button          Save
    Current Page Should Be           Form         Gift Entry            title=Gift Entry Form
    ${batch_id} =                    Save Current Record ID For Deletion     ${NS}DataImportBatch__c
    Verify Field Default Value
    ...                              Opportunity: Close Date=${UI_DATE}
    ...                              Payment: Payment Method=Credit Card
    ...                              Opportunity: custom_text=text
    ...                              Opportunity: Record Type=Major Gift
    Fill Gift Entry Form
    ...                              Data Import: Donation Donor=Contact1
    ...                              Data Import: Contact1 Imported=${CONTACT}[Name]
    Click Gift Entry Button          Save & Enter New Gift
    Verify Table Field Values        Batch Gifts
    ...                              Donor Name=${CONTACT}[Name]
    ...                              Opportunity: Close Date=${UI_DATE}
    ...                              Payment: Payment Method=Credit Card
    ...                              Opportunity: custom_text=text
    ...                              Opportunity: Record Type=Major Gift
    Click Gift Entry Button           Edit Batch Info
    Wait Until Modal Is Open
    Click Gift Entry Button           Next
    Wait Until Modal Is Open
    Fill Modal Form  
    ...                              Opportunity: Close Date=${FUT_DATE}
    ...                              Payment: Payment Method=Check
    ...                              Opportunity: custom_text=sometext
    ...                              Opportunity: Record Type=Matching Gift

    Click Gift Entry Button          Wizard Save
    Verify Field Default Value
    ...                              Opportunity: Close Date=${FUT_DATE}
    ...                              Payment: Payment Method=Check
    ...                              Opportunity: custom_text=sometext
    ...                              Opportunity: Record Type=Matching Gift
    Fill Gift Entry Form
    ...                              Data Import: Donation Donor=Contact1
    ...                              Data Import: Contact1 Imported=${CONTACT2}[Name]
    Click Gift Entry Button          Save & Enter New Gift
    Verify Table Field Values        Batch Gifts
    ...                              Donor Name=${CONTACT2}[Name]
    ...                              Opportunity: Close Date=${FUT_DATE}
    ...                              Payment: Payment Method=Check
    ...                              Opportunity: custom_text=sometext
    ...                              Opportunity: Record Type=Matching Gift
    Click Gift Entry Button          Edit Batch Info
    Wait Until Modal Is Open
    Click Gift Entry Button          Next
    Clear Form Fields
    ...                              Opportunity: Close Date=
    ...                              Payment: Payment Method=--None--
    ...                              Opportunity: custom_text=
    ...                              Opportunity: Record Type=NPSP Default
    Click Gift Entry Button          Wizard Save
    Verify Field Default Value
    ...                              Opportunity: Close Date=
    ...                              Payment: Payment Method=--None--
    ...                              Opportunity: custom_text=
    ...                              Opportunity: Record Type=NPSP Default

    Query And Store Records To Delete    ${NS}DataImport__c   ${NS}NPSP_Data_Import_Batch__c=${batch_id}
