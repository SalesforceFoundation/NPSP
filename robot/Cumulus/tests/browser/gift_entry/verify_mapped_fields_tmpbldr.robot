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
${template}       AM Template

*** Keywords ***
Setup Test Data
    Validate And Create Required CustomField
    ...                                                    Object=Opportunity
    ...                                                    Field_Type=Text
    ...                                                    Field_Name=Test Mapping
    Validate And Create Required CustomField
    ...                                                    Object=NPSP Data Import
    ...                                                    Field_Type=Text
    ...                                                    Field_Name=Opportunity Test
    ${ns} =  Get NPSP Namespace Prefix
    Set suite variable    ${ns}

*** Test Cases ***

Verify Mapped Field Is Available For Batch Template
    # [Documentation]                           Create a Template and verify template shows up in gift entry landing page. 
    # ...                                       Clone the template and verify that template name has to be unique.
    # ...                                       Delete Template and verify that template is not avaialable for selection while creating a batch.  
    [tags]                                    feature:GE                    W-039562   
    Click Configure Advanced Mapping
    View Field Mappings Of The Object         Opportunity
    Create Mapping If Doesnt Exist            Opportunity Test (Opportunity_Test__c)    Test Mapping (Test_Mapping__c)
    Reload Page
    #Create Template                             
    Go To Page                                Landing                         GE_Gift_Entry
    Click Link                                Templates
    Click Gift Entry Button                   Create Template
    Current Page Should Be                    Template                        GE_Gift_Entry
    Enter Value In Field
    ...                                       Template Name=${template}
    ...                                       Description=This is created by automation script  
    Click Gift Entry Button                   Next: Form Fields
    Object Group Field Action                 select                          Opportunity                     Test Mapping
    Click Gift Entry Button                   Next: Batch Settings
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing                         GE_Gift_Entry
    Click Link                                Templates
    Wait Until Page Contains                  ${template}
    Store Template Record Id                  ${template}
    Click Gift Entry Button                   New Batch
    Wait Until Modal Is Open
    Select Template                           ${template}
    Load Page Object                          Form                            Gift Entry
    Fill Gift Entry Form
    ...                                       Batch Name=Field Mapping Automation Batch
    ...                                       Batch Description=This is a test batch created via automation script
    Click Gift Entry Button                   Next
    Click Gift Entry Button                   Save
    Current Page Should Be                    Form                           Gift Entry         title=Gift Entry Form
    ${batch_id} =                             Save Current Record ID For Deletion     ${ns}DataImportBatch__c
    Wait Until Page Contains                  Test Mapping
    
    #Remove field from template and 
    Go To Page                                Landing                        GE_Gift_Entry
    Click Link                                Templates
    Select Template Action                    ${template}                    Edit
    Click Gift Entry Button                   Next: Form Fields
    Verify Template Builder                   contain                        Test Mapping
    Object Group Field Action                 unselect                       Opportunity                    Test Mapping
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing                        GE_Gift_Entry
    Go To Page                                Custom                         NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry  
    Click Configure Advanced Mapping
    View Field Mappings Of The Object         Opportunity
    Delete Field Mapping                      Opportunity Test
    Reload Page
    Go To Page                                Landing                        GE_Gift_Entry
    Click Link                                Templates
    Click Gift Entry Button                   Create Template
    Current Page Should Be                    Template                       GE_Gift_Entry
    Click Link                                Form Fields
    Verify Template Builder                   does not Contain               Test Mapping        



