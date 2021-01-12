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
...             Rename Object Field                     Account              custom_acc_texts     custom_acc_text
...  AND        Query And Store Records To Delete       ${ns}DataImport__c   ${ns}NPSP_Data_Import_Batch__c=${BATCH_Id}
...  AND        Capture Screenshot and Delete Records and Close Browser


*** Keywords ***
Setup Test Data
    [Documentation]     creates a test organization account
    &{ACCOUNT} =    API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{ACCOUNT}
    ${NS} =         Get NPSP Namespace Prefix
    Set suite variable    ${NS}

*** Test Cases ***

Validate Errors When Field Is Renamed
    [Documentation]

    [tags]                              unstable                      feature:GE          W-8292840
    Load Page Object                    Custom                        ObjectManager
    Rename Object Field                 Account                       custom_acc_text     custom_acc_texts
    Verify Error Message on AM Page And Object Group                  Account 1           custom_acc_text
    Go To Page                          Landing                       GE_Gift_Entry
    Click Link                          Templates
    Select Template Action              Default Gift Entry Template   Edit
    Current Page Should Be              Template                      GE_Gift_Entry
    Click Gift Entry Button             Next: Form Fields
    Perform Action On Object Field      select                        Account 1           Field not found
    Verify Errors On Template Builder   Account 1                     Field not found
    ...                                 warning
    ...                                 This form contains fields that can't be found. Please check with your administrator.
    Perform Action On Object Field      unselect                      Account 1           Field not found
    Click Gift Entry Button             Save & Close
    Go To Page                          Landing                       GE_Gift_Entry
    Create Gift Entry Batch             Default Gift Entry Template   ${ACCOUNT}[Name] first batch
    Current Page Should Be              Form                          Gift Entry
    ${BATCH_Id} =   Save Current Record ID For Deletion               ${NS}DataImportBatch__c
    Set Suite Variable                  ${BATCH_Id}
    Page Should Not Contain Locator     gift_entry.page_error
    Fill Gift Entry Form
    ...                                 Donor Type=Account1
    ...                                 Existing Donor Organization Account=${ACCOUNT}[Name]
    ...                                 Donation Amount=5
    ...                                 Donation Date=Today
    Click Gift Entry Button             Save & Enter New Gift
    Verify Table Field Values           Batch Gifts
    ...                                 Donor Name=${ACCOUNT}[Name]
    ...                                 Status=Dry Run - Error
    #Create the field again and verify errors are automaticlly resolved
    Rename Object Field                 Account                       custom_acc_texts     custom_acc_text
    Verify No Errors Displayed on AM Page And Object Group            Account 1           custom_acc_text
    Go To Page                          Landing                       GE_Gift_Entry
    Click Link                          Templates
    Select Template Action              Default Gift Entry Template   Edit
    Current Page Should Be              Template                      GE_Gift_Entry
    Click Gift Entry Button             Next: Form Fields
    Page Should Not Contain Locator     gift_entry.page_error
    Page Should Not Contain Locator     gift_entry.object_field_checkbox    Account 1    Field not found
    Perform Action On Object Field      select                        Account 1          custom_acc_text
    Page Should Not Contain Locator     gift_entry.field_error        custom_acc_text    Field not found
    Perform Action On Object Field      unselect                      Account 1          custom_acc_text
    Click Gift Entry Button             Save & Close
    Go To Page                          Landing                       GE_Gift_Entry
    Create Gift Entry Batch             Default Gift Entry Template   ${ACCOUNT}[Name] second batch
    Current Page Should Be              Form                          Gift Entry
    ${BATCH_Id} =   Save Current Record ID For Deletion                     ${NS}DataImportBatch__c
    Set Suite Variable                  ${BATCH_Id}
    Page Should Not Contain Locator     gift_entry.page_error
    Fill Gift Entry Form
    ...                                 Donor Type=Account1
    ...                                 Existing Donor Organization Account=${ACCOUNT}[Name]
    ...                                 Donation Amount=5
    ...                                 Donation Date=Today
    Click Gift Entry Button             Save & Enter New Gift
    Verify Table Field Values           Batch Gifts
    ...                                 Donor Name=${ACCOUNT}[Name]
    ...                                 Status=Dry Run - Validated
