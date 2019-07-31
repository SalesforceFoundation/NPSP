*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Enable Advanced Mapping 
    [tags]  Unstable
    Set Selenium Speed    0.25
    Go To Page    Custom    NPSPSettings
    Load Page Object    Custom    NPSPSettings
    Open Main Menu    System Tools
    Click Link With Text    Data Import Advanced Mapping
    Click Toggle Button    DataImportAdvancedMapping
    Wait Until Advanced Mapping Is Enabled
    # ${locator}    Get NPSP Locator    button    Configure Advanced Mapping
    # Wait Until Element Is Enabled    ${locator}    timeout=120

