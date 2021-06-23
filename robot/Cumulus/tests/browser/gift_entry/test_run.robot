*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/BatchGiftEntryPageObject.py
# ...             robot/Cumulus/resources/DataImportPageObject.py
# ...             robot/Cumulus/resources/OpportunityPageObject.py
# ...             robot/Cumulus/resources/PaymentPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             API Check And Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    ${NS} =               Get NPSP Namespace Prefix
    Set suite variable    ${NS}
    ${UI_DATE} =          Get Current Date      result_format=%b %-d, %Y
    Set suite variable    ${UI_DATE}


*** Test Cases ***
Testing Clicking Checkbox
    [Documentation]                 Set default values in batch template and verify they auto poputale in batch for.
    ...                             Change default values in batch template and verify the auto poputale in batch form.
    ...                             Leave default values blank and verify they do not auto popuate in batch form

    [Tags]                           unstable               feature:GE          W-8279550

    Go To Page                       Landing                GE_Gift_Entry
    Click Gift Entry Button          New Single Gift
    Current Page Should Be           Form         Gift Entry
    Fill Gift Entry Form
    ...                     Contact 1: Contact1 Checkbox To Checkbox=check
    Sleep  10
    