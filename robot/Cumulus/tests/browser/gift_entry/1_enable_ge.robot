*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***
Verify Error Message with GE Disabled and enable GE
    [Documentation]                           This test case checks if advanced mapping is enabled and if disabled, enables it. 
    ...                                       Checks if gift entry is disabled and if enabled, disables it and verifies that GE page has error. 
    ...                                       Then enables gift entry and verifies that gift entry page lands on templates page and has default template  
    [tags]                                    feature:GE    quadrant:q3
    Go To Page                                Custom              NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry
    Enable Advanced Mapping If Not Enabled
    Verify Gift Entry Is Not Enabled
    Go To Page                                Landing              GE_Gift_Entry        default=error
    Wait Until Page Contains                  This feature requires both Advanced Mapping and Gift Entry. Please enable them in NPSP Settings.
    Go To Page                                Custom              NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry
    Click Toggle Button                       Gift Entry
    Wait For Message                          Gift Entry Enabled                              
    Go To Page                                Landing              GE_Gift_Entry
    Click Link                                Templates
    Wait Until Page Contains                  Default Gift Entry Template