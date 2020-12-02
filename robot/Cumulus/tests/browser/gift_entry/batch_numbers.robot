*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
Suite Teardown  Run Keywords
...             Query And Store Records To Delete    ${ns}AutoNumber__c   ${ns}Display_Format__c=${format1}
...     AND     Query And Store Records To Delete    ${ns}AutoNumber__c   ${ns}Display_Format__c=${format2}
...     AND     Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]     Setsup namespace prefix and required number formats
    ${ns} =               Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    ${first} =            Generate Random String
    ${format1}=           Set Variable    ${first}-{000}
    Set suite variable    ${format1}
    ${second} =           Generate Random String
    Set suite variable    ${second}
    ${format2}=           Set Variable    ${second}-{00}
    Set suite variable    ${format2}

Create Batch With Default Template
    [Documentation]     creates a simple batch with given name using default template
    [Arguments]         ${batch_name}
    Click Gift Entry Button                 New Batch
    Wait Until Modal Is Open
    Select Template                         Default Gift Entry Template
    Load Page Object                        Form                            Gift Entry
    Fill Gift Entry Form
    ...                                     Batch Name=${batch_name}
    ...                                     Batch Description=This is a test batch created via automation script
    Click Gift Entry Button                 Next
    Click Gift Entry Button                 Save
    Current Page Should Be                  Form                            Gift Entry
    Save Current Record ID For Deletion     ${NS}DataImportBatch__c

*** Test Cases ***
Test Add and Delete Batch Number Formats
    [Documentation]         Add two batch number formats and activate one.Verify new batch created after the format is activated
    ...                     carry the batch number in the specified format and starting number.Deactivate the active number format,
    ...                     Verify Batch does not have a batch number assigned.
    [tags]                                  unstable      feature:GE    W-8246942
    #Create Batch Number Format
    Load Page Object                        Template      GE_Gift_Entry
    Enter Value In Field
    ...     Display Format=${format1}
    ...     Starting Number=0
    Click Button                            Save
    Verify Table Contains Row               datatable     ${format1}    Active=False
    Enter Value In Field
    ...     Display Format=${format2}
    ...     Starting Number=1
    Click Button                            Save & Activate
    Verify Table Contains Row               datatable     ${format2}    Active=True
    #Create batch and verify numbering
    Go To Page                              Landing       GE_Gift_Entry
    Click Gift Entry Button                 Settings
    Click Link                              Select Fields to Display
    Wait Until Modal Is Open
    Load Page Object                        Template      GE_Gift_Entry
    Add Batch Table Columns                 Batch Number
    Click Gift Entry Button                 Listbox Save
    Wait Until Modal Is Closed
    Create Batch With Default Template      Batch Number Automation Batch
    Go To Page                              Landing       GE_Gift_Entry
    Verify Table Contains Row               Batches       Batch Number Automation Batch    Batch Number=${second}-01
    #Deactivate the batch number format and verify new batch doesn't have batch number
    Go To Page                              Custom        NPSP_Settings
    Open Main Menu                          System Tools
    Click Link With Text                    Advanced Mapping for Data Import & Gift Entry
    Deactivate Batch Number Format          ${format2}
    Go To Page                              Landing       GE_Gift_Entry
    Create Batch With Default Template      Batch Without Number Automation Batch
    Go To Page                              Landing       GE_Gift_Entry
    Verify Table Contains Row               Batches       Batch Number Automation Batch    Batch Number=None




