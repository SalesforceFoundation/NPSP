*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Verify Payment Allocations is Disabled by Default
    [tags]  stable
    Go To Setup Page    CustomSettings
    Select Frame And Click Element    Custom Settings    custom_settings.link    Allocations Settings    Manage
    Unselect Frame
    Wait Until Loading Is Complete
    Choose Frame    Custom Setting Allocations Settings
    Wait Until Element Is Visible  text:Default Organization Level Value
    Checkbox Status    Payment Allocations Enabled    Not Checked
    