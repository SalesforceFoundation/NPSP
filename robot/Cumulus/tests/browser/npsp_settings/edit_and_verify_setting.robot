*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Test Cases ***

Make Changes to Settings and Verify Changes
    [Documentation]            Go to NPSP Settings>People>Account Model. Edit Household Account Record Type seeing to Organization and Save.
    ...                        Verify that the change is saved and revert the change and Save again. Verify change reverted.
    [tags]                     feature:NPSP Settings           unstable
    Open NPSP Settings         People                          Account Model             
    Click Settings Button      idPanelCon                      Edit
    Edit Selection             Household Account Record Type   Organization
    Click Settings Button      idPanelCon                      Save
    Verify Selection           Household Account Record Type   Organization
    Click Settings Button      idPanelCon                      Edit
    Edit Selection             Household Account Record Type   Household Account
    Click Settings Button      idPanelCon                      Save
    Verify Selection           Household Account Record Type   Household Account
