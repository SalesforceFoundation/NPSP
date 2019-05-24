*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Make Changes to Settings and Verify Changes
    [tags]  unstable
    Select App Launcher Tab  NPSP Settings
    #Sleep    3
    Wait For Locator    frame    Nonprofit Success Pack Settings
    Choose Frame    Nonprofit Success Pack Settings
    Click Link    link=People
    Click Link    link=Account Model
    Click Settings Button    idPanelCon    Edit
    Wait For Locator    npsp_settings.batch-button    idPanelCon    Save
    Select Value From List     Household Account Record Type       Organization
    Click Settings Button   idPanelCon    Save
    Wait For Locator     npsp_settings.list_val       Household Account Record Type    Organization
    Click Settings Button    idPanelCon    Edit
    Wait For Locator    npsp_settings.batch-button    idPanelCon    Save
    Select Value From List     Household Account Record Type    Household Account
    Click Settings Button    idPanelCon    Save
    Wait For Locator    npsp_settings.list_val    Household Account Record Type    Household Account
