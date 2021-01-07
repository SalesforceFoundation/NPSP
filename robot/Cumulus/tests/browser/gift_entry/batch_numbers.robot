*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    [Documentation]     Setsup namespace prefix and required number formats
    ${NS} =               Get NPSP Namespace Prefix
    Set suite variable    ${NS}
    ${FIRST} =            Generate Random String
    Set suite variable    ${FIRST}
    ${FORMAT1}=           Set Variable    ${FIRST}-{000}
    Set suite variable    ${FORMAT1}
    ${SECOND} =           Generate Random String
    Set suite variable    ${SECOND}
    ${FORMAT2}=           Set Variable    ${SECOND}-{00}
    Set suite variable    ${FORMAT2}

*** Test Cases ***
Test Add and Delete Batch Number Formats
    [Documentation]         Add two batch number formats and activates one.Verifies new batch created after the format is activated
    ...                     carry the batch number in the specified format and starting number. Deactivate the active number format,
    ...                     Activate the other format and verify the new batch carries correct format.Deactivate the number format
    ...                     Verify new batch does not have a batch number assigned.
    [tags]                                  unstable      feature:GE    W-8246942
    #Create Batch Number Formats and activate second format
    Load Page Object                        Template      GE_Gift_Entry
    Enter Value In Field
    ...     Display Format=${FORMAT1}
    ...     Starting Number=0
    Click Button                            Save
    Verify Table Contains Row               datatable     ${FORMAT1}    Active=False
    Enter Value In Field
    ...     Display Format=${FORMAT2}
    ...     Starting Number=1
    Click Button                            Save & Activate
    Verify Table Contains Row               datatable     ${FORMAT2}    Active=True
    #Create batch and verify numbering
    Go To Page                              Landing       GE_Gift_Entry
    Click Gift Entry Button                 Settings
    Click Link                              Select Fields to Display
    Wait Until Modal Is Open
    Load Page Object                        Template      GE_Gift_Entry
    Add Batch Table Columns                 Batch Number
    Click Gift Entry Button                 Listbox Save
    Wait Until Modal Is Closed
    Create Gift Entry Batch                 Default Gift Entry Template                Batch with second format
    Current Page Should Be                  Form                                       Gift Entry
    Save Current Record ID For Deletion     ${NS}DataImportBatch__c
    Go To Page                              Landing       GE_Gift_Entry
    Verify Table Contains Row               Batches       Batch with second format     Batch Number=${SECOND}-01
    #Deactivate the second format and activate first and verify batch numberiing
    Go To Page                              Custom        NPSP_Settings
    Open Main Menu                          System Tools
    Click Link With Text                    Advanced Mapping for Data Import & Gift Entry
    Verify Table Contains Row               datatable     ${FORMAT2}    Max Used Number=1
    Set Batch Number Format Status          ${FORMAT2}    Deactivate
    Set Batch Number Format Status          ${FORMAT1}    Activate
    Go To Page                              Landing       GE_Gift_Entry
    Create Gift Entry Batch                 Default Gift Entry Template                Batch with first format
    Current Page Should Be                  Form                                       Gift Entry
    Save Current Record ID For Deletion     ${NS}DataImportBatch__c
    Go To Page                              Landing       GE_Gift_Entry
    Verify Table Contains Row               Batches       Batch with first format      Batch Number=${FIRST}-000
    #Deactivate the batch number format and verify new batch doesn't have batch number
    Go To Page                              Custom        NPSP_Settings
    Open Main Menu                          System Tools
    Click Link With Text                    Advanced Mapping for Data Import & Gift Entry
    Verify Table Contains Row               datatable     ${FORMAT1}    Max Used Number=0
    Set Batch Number Format Status          ${FORMAT1}    Deactivate
    Go To Page                              Landing       GE_Gift_Entry
    Create Gift Entry Batch                 Default Gift Entry Template                Batch Without Number
    Current Page Should Be                  Form                                       Gift Entry
    Save Current Record ID For Deletion     ${NS}DataImportBatch__c
    Go To Page                              Landing       GE_Gift_Entry
    Verify Table Contains Row               Batches       Batch Without Number         Batch Number=None
