*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Make Changes to Settings and Verify Changes
    Sleep    5
    Open App Launcher
    Populate Address    Find an app or item    NPSP Settings
    Select App Launcher Link  NPSP Settings
    Sleep    5
    Select Frame With Title    Nonprofit Success Pack Settings
    Click Link    link=People
    Click Link    link=Account Model
    #Page Should Contain Element    //div[@class="slds-form-element"][./label[text()="Household Account Record Type"]]/div/span[text()="Household Account"]
    Click Button With Value    Edit
    Wait For Locator    button    Save
    #Wait Until Element is Visible    //input[@value="Save"]
    #Click Element            //div[contains(@class,'slds-form--horizontal')]/div[@class='slds-form-element'][./label[text()='Household Account Record Type']]/div/select
    Select From List By Label     //div[contains(@class,'slds-form--horizontal')]/div[@class='slds-form-element'][./label[text()='Household Account Record Type']]/div/select           Organization
    Click Button With Value    Save
    Wait Until Element is Visible    //div[@class="slds-form-element"][./label[text()="Household Account Record Type"]]/div/span[text()="Organization"]
    Click Button With Value    Edit
    Wait Until Element is Visible    //input[@value="Save"]
    Select From List By Label     //div[contains(@class,'slds-form--horizontal')]/div[@class='slds-form-element'][./label[text()='Household Account Record Type']]/div/select    Household Account
    Click Button With Value    Save
    Sleep    2
    Page Should Contain Element    //div[@class="slds-form-element"][./label[text()="Household Account Record Type"]]/div/span[text()="Household Account"]