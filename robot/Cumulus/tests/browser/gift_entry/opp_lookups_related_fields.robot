*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${BATCH_Id}
...   AND       Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${TEMPLATE}       Opportunity Lookups Template
&{RECORD_TYPE}    Default Value=In-Kind Gift
&{DESCRIPTION}    Default Value=Testing defaults

*** Keywords ***
Setup Test Data
    &{CONTACT} =          API Create Contact       FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable    &{CONTACT}
    Store Session Record  Account                  ${CONTACT}[AccountId]
    ${CUR_DATE} =         Get Current Date         result_format=%Y-%m-%d
    Set suite variable    ${CUR_DATE}
    &{OPPORTUNITY} =      API Create Opportunity   ${CONTACT}[AccountId]              Donation
    ...                   StageName=Prospecting
    ...                   Amount=100
    ...                   CloseDate=${CUR_DATE}
    ...                   Name=${CONTACT}[Name] Donation
    Set suite variable    &{OPPORTUNITY}
    ${NS} =               Get NPSP Namespace Prefix
    Set suite variable    ${NS}
    ${ui_date} =          Get Current Date         result_format=%b %-d, %Y
    Set suite variable    ${UI_DATE}

*** Test Cases ***

Verify Changing Labels on Template Gets Updated on Batches
    # [Documentation]
    [tags]                                  unstable      feature:GE        W-8292782
    Go To Page                              Landing                         GE_Gift_Entry
    Click Link                              Templates
    Click Gift Entry Button                 Create Template
    Current Page Should Be                  Template                        GE_Gift_Entry
    Enter Value In Field
    ...                                     Template Name=${TEMPLATE}
    ...                                     Description=This is created by automation script
    Click Gift Entry Button                 Next: Form Fields
    Perform Action On Object Field          select                          Opportunity           Record Type ID
    Perform Action On Object Field          select                          Opportunity           Stage
    Perform Action On Object Field          select                          Opportunity           Description
    Fill Template Form                      Opportunity: Record Type ID=&{RECORD_TYPE}
    ...                                     Opportunity: Description=&{DESCRIPTION}
    Click Gift Entry Button                 Next: Batch Settings
    Add Batch Table Columns                 Opportunity: Record Type
    ...                                     Opportunity: Stage
    ...                                     Opportunity: Description
    Click Gift Entry Button                 Save & Close
    Current Page Should Be                  Landing                         GE_Gift_Entry
    Click Link                              Templates
    Wait Until Page Contains                ${TEMPLATE}
    Store Template Record Id                ${TEMPLATE}
    Create Gift Entry Batch                 ${TEMPLATE}                     Opportunity Lookups Automation Batch
    Current Page Should Be                  Form                            Gift Entry          title=Gift Entry Form
    ${BATCH_Id} =   Save Current Record ID For Deletion                     ${NS}DataImportBatch__c
    Set Suite Variable                      ${BATCH_Id}
    Verify Field Default Value              Opportunity: Record Type=${RECORD_TYPE}[Default Value]
    ...                                     Opportunity: Description=${DESCRIPTION}[Default Value]
    Fill Gift Entry Form
    ...                                     Data Import: Donation Donor=Contact1
    ...                                     Data Import: Contact1 Imported=${CONTACT}[Name]
    Click Button                            Review Donations
    Wait Until Modal Is Open
    Click Button                            npsp:gift_entry.id:Update this Opportunity ${OPPORTUNITY}[Name]
    Verify Field Default Value
    ...                                     Opportunity: Amount=$100.00
    ...                                     Opportunity: Close Date=${UI_DATE}
    ...                                     Opportunity: Record Type=Donation
    ...                                     Opportunity: Stage=Prospecting
    ...                                     Opportunity: Description=${DESCRIPTION}[Default Value]
    Fill Gift Entry Form                    Opportunity: Stage=Closed Won
    Click Button                            Save & Enter New Gift
    #Verify gift is created with correct values
    Verify Gift Count                       1
    Verify Table Field Values               Batch Gifts
    ...                                     Donor Name=${CONTACT}[Name]
    ...                                     Opportunity: Amount=$100.00
    ...                                     Opportunity: Close Date=${UI_DATE}
    ...                                     Opportunity: Record Type=Donation
    ...                                     Opportunity: Stage=Closed Won
    ...                                     Opportunity: Description=${DESCRIPTION}[Default Value]
    Perform Action On Datatable Row   	    ${CONTACT}[Name]                Open
    Verify Field Default Value
    ...                                     Opportunity: Amount=$100.00
    ...                                     Opportunity: Close Date=${UI_DATE}
    ...                                     Opportunity: Record Type=Donation
    ...                                     Opportunity: Stage=Closed Won
    ...                                     Opportunity: Description=${DESCRIPTION}[Default Value]


