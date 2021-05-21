*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
...             robot/Cumulus/resources/ObjectMangerPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
${TEMPLATE}       AM Template

*** Keywords ***
Setup Test Data
    [Documentation]     Setsup namespace prefix
    ${ns} =  Get NPSP Namespace Prefix
    Set suite variable    ${ns}

*** Test Cases ***

Verify Mapped Field Is Available For Batch Template
    [Documentation]                         Create a custom field on opportunity and npsp data import objects. Create advanced mapping to these fields.
    ...                                     Verify that the mapped field is available for selection while creating a new template and once selected, its avialble on newly created batch gift form
    ...                                     Remove field from template, delete mapping and verify that the new field is not avaialable for selection while creating template.
    [tags]                                  unstable     feature:GE                    W-039562
    #Create field mapping
    Click Configure Advanced Mapping
    View Field Mappings Of The Object       Opportunity
    Create Mapping If Doesnt Exist          Opportunity Test (Opportunity_Test__c)    Test Mapping (Test_Mapping__c)
    Reload Page
    #Create new template with new field
    Go To Page                              Landing                         GE_Gift_Entry
    Click Link                              Templates
    Click Gift Entry Button                 Create Template
    Current Page Should Be                  Template                        GE_Gift_Entry
    Enter Value In Field
    ...                                     Template Name=${TEMPLATE}
    ...                                     Description=This is created by automation script
    Click Gift Entry Button                 Next: Form Fields
    Perform Action On Object Field          select                          Opportunity           Test Mapping
    Click Gift Entry Button                 Next: Batch Settings
    Click Gift Entry Button                 Save & Close
    Current Page Should Be                  Landing                         GE_Gift_Entry
    Click Link                              Templates
    Wait Until Page Contains                ${TEMPLATE}
    Store Template Record Id                ${TEMPLATE}
    #Verify field is displayed on newly created batch with new template
    Create Gift Entry Batch                 ${TEMPLATE}                     Field Mapping Automation Batch
    Current Page Should Be                  Form                            Gift Entry            title=Gift Entry Form
    ${batch_id} =                           Save Current Record ID For Deletion     ${ns}DataImportBatch__c
    Wait Until Page Contains                Test Mapping
    #Remove field from template
    Go To Page                              Landing                        GE_Gift_Entry
    Click Link                              Templates
    Select Template Action                  ${TEMPLATE}                    Edit
    Click Gift Entry Button                 Next: Form Fields
    Verify Template Builder                 contain                        Test Mapping
    Perform Action On Object Field          unselect                       Opportunity            Test Mapping
    Click Gift Entry Button                 Save & Close
    Current Page Should Be                  Landing                        GE_Gift_Entry
    #Remove field mapping
    Go To Page                              Custom                         NPSP_Settings
    Open Main Menu                          System Tools
    Click Link With Text                    Advanced Mapping for Data Import & Gift Entry
    Click Configure Advanced Mapping
    View Field Mappings Of The Object       Opportunity
    Delete Field Mapping                    Opportunity Test
    Reload Page
    #Verify field is not available for selection while creating template
    Go To Page                              Landing                        GE_Gift_Entry
    Click Link                              Templates
    Click Gift Entry Button                 Create Template
    Current Page Should Be                  Template                       GE_Gift_Entry
    Click Link                              Form Fields
    Verify Template Builder                 does not Contain               Test Mapping
