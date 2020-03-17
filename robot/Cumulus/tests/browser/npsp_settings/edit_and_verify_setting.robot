*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Make Changes to Settings and Verify Changes
    [tags]  unstable
    Go To Page                 Custom                          NPSP_Settings
    Open Main Menu             People
    Open Sub Link              Account Model
    Click Settings Button      idPanelCon                      Edit
    Edit Selection             Household Account Record Type   Organization
    Click Settings Button      idPanelCon                      Save
    Verify Selection           Household Account Record Type   Organization
    Click Settings Button      idPanelCon                      Edit
    Edit Selection             Household Account Record Type   Household Account
    Click Settings Button      idPanelCon                      Save
    Verify Selection           Household Account Record Type   Household Account
