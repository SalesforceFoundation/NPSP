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
...             Create Customfield In Object Manager    Object=Account  Field_Type=Text     Field_Name=custom_acc_text
...  AND        Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]  creates a test organization account
    &{ACCOUNT} =    API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{ACCOUNT}

*** Test Cases ***

Validate Errors When Field Is Deleted
    [Documentation]         Deletes a field thats mapped, verifies warnings and error are thrown on AM, Object group page, template builder.
    ...                     Verifys that saving the gift throws an error. Creates the field and verifys no errors or warnings are thrown on AM,
    ...                     object group, and template builder. Verifys that gift can be created successfully.

    [tags]                              unstable                      feature:GE          W-8292840
    Load Page Object                    Custom                        ObjectManager
    Delete Object Field                 Account                       custom_acc_text
    Verify Error Message on AM Page And Object Group                  Account 1           custom_acc_text
    Go To Page                          Landing                       GE_Gift_Entry
    Click Link                          Templates
    Select Template Action              Default Gift Entry Template   Edit
    Current Page Should Be              Template                      GE_Gift_Entry
    Click Gift Entry Button             Next: Form Fields
    Perform Action On Object Field      select                        Account 1          Field not found
    Verify Errors On Template Builder   Account 1                     Field not found
    ...                                 warning
    ...                                 This form contains fields that can't be found. Please check with your administrator.
    Perform Action On Object Field      unselect                      Account 1          Field not found
    Click Gift Entry Button             Cancel
    Go To Page                          Landing                       GE_Gift_Entry
    Click Gift Entry Button             New Single Gift
    Current Page Should Be              Form                          Gift Entry
    Page Should Not Contain Locator     gift_entry.page_error
    Fill Gift Entry Form
    ...                                 Donor Type=Account1
    ...                                 Existing Donor Organization Account=${ACCOUNT}[Name]
    ...                                 Donation Amount=10
    ...                                 Donation Date=Today
    Click Gift Entry Button             Save
    Page Should Contain Element         npsp:gift_entry.page_error
    #Create the field again and verify errors are automaticlly resolved
    Create Customfield In Object Manager
    ...                                 Object=Account
    ...                                 Field_Type=Text
    ...                                 Field_Name=custom_acc_text
    Verify No Errors Displayed on AM Page And Object Group            Account 1           custom_acc_text
    Go To Page                          Landing                       GE_Gift_Entry
    Click Link                          Templates
    Select Template Action              Default Gift Entry Template   Edit
    Current Page Should Be              Template                      GE_Gift_Entry
    Click Gift Entry Button             Next: Form Fields
    Page Should Not Contain Locator     gift_entry.page_error
    Page Should Not Contain Locator     gift_entry.object_field_checkbox    Account 1  Field not found
    Perform Action On Object Field      select                      Account 1          custom_acc_text
    Page Should Not Contain Locator     gift_entry.field_error      custom_acc_text    Field not found
    Perform Action On Object Field      unselect                    Account 1          custom_acc_text
    Click Gift Entry Button             Cancel
    Go To Page                          Landing                       GE_Gift_Entry
    Click Gift Entry Button             New Single Gift
    Current Page Should Be              Form                          Gift Entry
    Page Should Not Contain Locator     gift_entry.page_error
    Fill Gift Entry Form
    ...                                 Donor Type=Account1
    ...                                 Existing Donor Organization Account=${ACCOUNT}[Name]
    ...                                 Donation Amount=15
    ...                                 Donation Date=Today
    Click Gift Entry Button             Save
    Current Page Should Be              Details                       Opportunity
    ${opp_id} =                         Save Current Record ID For Deletion     Opportunity