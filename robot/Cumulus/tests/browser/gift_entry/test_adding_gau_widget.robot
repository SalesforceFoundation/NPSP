*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${TEMPLATE}       GAU Widget Template


*** Test Cases ***

Create Template with GAU Widget
    [Documentation]          Create a template with GAU widget. Create a batch with new template
    ...                      verify GAU widget is added to form
    [tags]                   feature:GE               W-8158171
    Go To Page                              Landing                  GE_Gift_Entry
    Click Link                              Templates
    Click Gift Entry Button                 Create Template
    Current Page Should Be                  Template                 GE_Gift_Entry
    Enter Value In Field
    ...        Template Name=${TEMPLATE}
    ...        Description=This is created by automation script
    Click Gift Entry Button                 Next: Form Fields
    Add Field Bundle to Section             GAU Allocations          section=new
    Click Gift Entry Button                 Next: Batch Settings
    Click Gift Entry Button                 Save & Close
    Current Page Should Be                  Landing                  GE_Gift_Entry
    Click Link                              Templates
    Wait Until Page Contains                ${TEMPLATE}
    Store Template Record Id                ${TEMPLATE}
    Create Gift Entry Batch                 ${TEMPLATE}              ${TEMPLATE} Automation Batch
    Current Page Should Be                  Form                     Gift Entry            title=Gift Entry Form
    ${ns} =  Get NPSP Namespace Prefix
    Save Current Record ID For Deletion     ${ns}DataImportBatch__c
    Click Gift Entry Button                 Add New Allocation
    Page Should Contain Element             npsp:link-contains:New Section
    Page Should Contain Element             npsp:label:General Accounting Unit
    Page Should Contain Element             npsp:label:Amount
    Page Should Contain Element             npsp:label:Percent