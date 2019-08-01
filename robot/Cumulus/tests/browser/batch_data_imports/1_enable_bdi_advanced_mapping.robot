*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Enable Advanced Mapping
    [Documentation]    This test case enables Advanced Mapping for Data Imports 
    [tags]  Unstable
    Log Page Object Keywords
    Go To Page                                Custom          NPSPSettings
    Load Page Object                          Custom          NPSPSettings
    Open Main Menu                            System Tools
    Click Link With Text                      Data Import Advanced Mapping
    Click Toggle Button                       DataImportAdvancedMapping
    Wait Until Advanced Mapping Is Enabled


