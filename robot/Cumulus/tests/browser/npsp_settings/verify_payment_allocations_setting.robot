*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Verify Payment Allocations is Disabled by Default
    [tags]  unstable
    Populate Field By Placeholder    Quick Find    Custom Settings
    Click Element With Locator    custom_settings.subtree    Custom Settings
    Select Frame And Click Element    Custom Settings    custom_settings.link    Allocations Settings    Manage
    Choose Frame    Custom Setting Allocations Settings
    Wait Until Element Is Visible  text:Default Organization Level Value
    Checkbox Status    Payment Allocations Enabled    Not Checked
    