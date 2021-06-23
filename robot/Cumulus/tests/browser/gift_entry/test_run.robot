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

*** Keywords ***
Setup Test Data
    ${TEMPLATE_NAME} =    Generate Random String
	Set suite variable    ${TEMPLATE_NAME}
    ${BATCH_NAME} =       Generate Random String
	Set suite variable    ${BATCH_NAME}
    ${NS} =               Get NPSP Namespace Prefix
    Set suite variable    ${NS}
    ${UI_DATE} =          Get Current Date      result_format=%b %-d, %Y
    Set suite variable    ${UI_DATE}


*** Test Cases ***
Testing Creating a Batch
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
    Click Gift Entry Button          Next: Batch Settings
    Click Gift Entry Button          Save & Close
    Click Link                       Templates
    Store Template Record Id         ${TEMPLATE_NAME}
    Click Gift Entry Button          New Batch
    Wait Until Modal Is Open
    Select Template                  ${TEMPLATE_NAME}
    Load Page Object                 Form   Gift Entry
    Fill Gift Entry Form
    ...                              Batch Name=${BATCH_NAME}
    Click Gift Entry Button          Next
    Verify Field Default Value
    ...                              Opportunity: Close Date=${UI_DATE}
    ...                              Payment: Payment Method=Credit Card
    ...                              Opportunity: custom_text=text
    ...                              Opportunity: Record Type=Major Gift
    Click Gift Entry Button          Save
    Current Page Should Be           Form         Gift Entry            title=Gift Entry Form