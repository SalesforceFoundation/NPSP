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
    Select Frame With Title    Nonprofit Success Pack Settings
    Click Link    link=People
    Click Link    link=Account Model
    Click Button With Value    Edit
    Wait For Locator    button    Save
    Select Value From List     Household Account Record Type       Organization
    Click Button With Value    Save
    Wait For Locator     npsp_settings.list_val       Household Account Record Type    Organization
    Click Button With Value    Edit
    Wait For Locator    button    Save
    Select Value From List     Household Account Record Type    Household Account
    Click Button With Value    Save
    Wait For Locator    npsp_settings.list_val    Household Account Record Type    Household Account
