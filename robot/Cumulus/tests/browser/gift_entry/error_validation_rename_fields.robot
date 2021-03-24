*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Run Keywords
...             Rename Object Field                     Account              custom_acc1_text     custom_acc_text
...  AND        Query And Store Records To Delete       ${NS}DataImport__c   ${NS}NPSP_Data_Import_Batch__c=${BATCH1_Id}
...  AND        Query And Store Records To Delete       ${NS}DataImport__c   ${NS}NPSP_Data_Import_Batch__c=${BATCH2_Id}
...  AND        Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${TEMPLATE}       Field Rename Template

*** Keywords ***
Setup Test Data
    [Documentation]     creates a test organization account
    &{ACCOUNT} =    API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{ACCOUNT}
    ${NS} =         Get NPSP Namespace Prefix
    Set suite variable    ${NS}

*** Test Cases ***

Validate Errors When Field Is Renamed
    [Documentation]         Creates a template with a custom field on template form, renames the field, verifies warnings and error are thrown on AM
    ...                     Object group page, template builder. Verify field is not present on batch gift form. Save the gift and verify gift
    ...                     status is dry run error. Rename the field to correct it and verify no errors or warnings are thrown on AM, object group,
    ...                     and template builder. Creates a batch and verifys field is back on form and on saving gift its status is dry run validated.

    [tags]                              unstable                      feature:GE        W-8292840
    Go To Page                          Landing                       GE_Gift_Entry
    Click Link                          Templates
    Click Gift Entry Button             Create Template
    Current Page Should Be              Template                      GE_Gift_Entry
    Enter Value In Field
    ...                                 Template Name=${TEMPLATE}
    ...                                 Description=This is created by automation script
    Click Gift Entry Button             Next: Form Fields
    Perform Action On Object Field      select                        Account 1         custom_acc_text
    Click Gift Entry Button             Next: Batch Settings
    Click Gift Entry Button             Save & Close

    Load Page Object                    Custom                        ObjectManager
    Rename Object Field                 Account                       custom_acc_text   custom_acc1_text
    Verify Error Message on AM Page And Object Group                  Account 1         custom_acc_text
    Go To Page                          Landing                       GE_Gift_Entry
    Click Link                          Templates
    Store Template Record Id            ${TEMPLATE}
    Select Template Action              ${TEMPLATE}   Edit
    Current Page Should Be              Template                      GE_Gift_Entry
    Click Gift Entry Button             Next: Form Fields
    Verify Errors On Template Builder   Account 1                     custom_acc_text
    ...                                 warning
    ...                                 This form contains fields that can't be found. Please check with your administrator.
    Page Should Contain Element         npsp:gift_entry.field_error:custom_acc_text,Field not found
    Click Gift Entry Button             Cancel
    Go To Page                          Landing                       GE_Gift_Entry
    Create Gift Entry Batch             ${TEMPLATE}                   ${ACCOUNT}[Name] first batch
    Current Page Should Be              Form                          Gift Entry        title=Gift Entry Form
    ${BATCH1_Id} =   Save Current Record ID For Deletion              ${NS}DataImportBatch__c
    Set Suite Variable                  ${BATCH1_Id}
    Page Should Not Contain Locator     gift_entry.page_error
    Page Should Not Contain Locator     label                         Account 1: custom_acc_text
    Fill Gift Entry Form
    ...                                 Data Import: Donation Donor=Account1
    ...                                 Opportunity: Close Date=Today
    ...                                 Opportunity: Amount=5
    # This is separate from the other Fill Gift Entry keyword to prevent timing issues
    Fill Gift Entry Form
    ...                                 Data Import: Account1 Imported=${ACCOUNT}[Name]
    Click Gift Entry Button             Save & Enter New Gift
    Verify Table Field Values           Batch Gifts
    ...                                 Donor Name=${ACCOUNT}[Name]
    ...                                 Status=Dry Run - Error
    #Rename the field again and verify errors are automaticlly resolved
    Rename Object Field                 Account                       custom_acc1_text     custom_acc_text
    Verify No Errors Displayed on AM Page And Object Group            Account 1            custom_acc_text
    Go To Page                          Landing                       GE_Gift_Entry
    Reload Page
    Current Page Should Be              Landing                       GE_Gift_Entry
    Click Link                          Templates
    Select Template Action              ${TEMPLATE}                   Edit
    Current Page Should Be              Template                      GE_Gift_Entry
    Click Gift Entry Button             Next: Form Fields
    Page Should Not Contain Locator     gift_entry.page_error
    Page Should Not Contain Locator     gift_entry.object_field_checkbox    Account 1      Field not found
    Page Should Not Contain Locator     gift_entry.field_error        custom_acc_text      Field not found
    Click Gift Entry Button             Cancel
    Go To Page                          Landing                       GE_Gift_Entry
    Create Gift Entry Batch             ${TEMPLATE}                   ${ACCOUNT}[Name] second batch
    Current Page Should Be              Form                          Gift Entry           title=Gift Entry Form
    ${BATCH2_Id} =   Save Current Record ID For Deletion              ${NS}DataImportBatch__c
    Set Suite Variable                  ${BATCH2_Id}
    Page Should Not Contain Locator     gift_entry.page_error
    Page Should Contain Element         npsp:label:Account 1: custom_acc_text
    Fill Gift Entry Form
    ...                                 Data Import: Donation Donor=Account1
    ...                                 Opportunity: Close Date=Today
    ...                                 Opportunity: Amount=10
    # This is separate from the other Fill Gift Entry keyword to prevent timing issues
    Fill Gift Entry Form
    ...                                 Data Import: Account1 Imported=${ACCOUNT}[Name]
    Click Gift Entry Button             Save & Enter New Gift
    Verify Table Field Values           Batch Gifts
    ...                                 Donor Name=${ACCOUNT}[Name]
    ...                                 Status=Dry Run - Validated
