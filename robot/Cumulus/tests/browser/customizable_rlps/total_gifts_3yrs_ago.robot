*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Enable Customizable Rollups
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Calculate CRLPs for Total Gifts 3 Years Ago
    [Documentation]    This test case checks if advanced mapping is enabled. If already enabled 
    ...                then throws an error and if not, enables Advanced Mapping for Data Imports  
    [tags]             feature:Customizable Rollups
    Go To Page                                Custom          NPSP_Settings
    Open Main Menu                            System Tools
    Click Link With Text                      Advanced Mapping for Data Import & Gift Entry
    Verify Advanced Mapping Is Not Enabled
    Click Toggle Button                       Advanced Mapping
    Wait For Message                          Advanced Mapping is enabled


