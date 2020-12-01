*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
...             Enable Gift Entry
# Suite Teardown  Run Keywords
# ...             Query And Store Records To Delete    ${ns}AutoNumber__c   ${ns}Display_Format__c=Robot1-{000}
# ...     AND     Capture Screenshot and Delete Records and Close Browser

*** Variables ***


*** Keywords ***
Setup Test Data
    [Documentation]     Setsup namespace prefix
    ${ns} =         Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    ${first} =      Generate Random String
    ${format1}=     Set Variable    ${first}-{000}
    Set suite variable    ${format1}
    ${second} =     Generate Random String
    ${format2}=     Set Variable    ${second}-{00}
    Set suite variable    ${format2}

*** Test Cases ***

Test Add and Delete Batch Number Formats
    [Documentation]
    [tags]                                  unstable      feature:GE                    W-8246942
    #Create Batch Number Format
    Load Page Object                        Template      GE_Gift_Entry
    Enter Value In Field
    ...     Display Format=${format1}
    ...     Starting Number=0
    Click Button                            Save
    Verify Table Contains Row               ${format1}    Active=False
    Enter Value In Field
    ...     Display Format=${format2}
    ...     Starting Number=1
    Click Button                            Save & Activate
    Verify Table Contains Row               ${format2}    Active=True
    #create batch and verify numbering



