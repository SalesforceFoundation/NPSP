*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Enable Advanced Mapping
    [Documentation]    This test case checks if advanced mapping is enabled. If already enabled 
    ...                then throws an error and if not, enables Advanced Mapping for Data Imports  
    [tags]             feature:BDI
    Go To Page                                Custom          NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry
    Verify Advanced Mapping Is Not Enabled
    Click Toggle Button                       Advanced Mapping
    Wait For Message                          Advanced Mapping is enabled


