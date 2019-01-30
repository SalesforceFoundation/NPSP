*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Merge Contacts
    # Manually creating contact records, sosl doesn't always return api generated contacts
    Go To Object Home  Contact
    Click Link  title:New
    Populate Form
    ...                       First Name=Robot
    ...                       Last Name=One
    Click Modal Button        Save & New
    Populate Form
    ...                       First Name=Robot
    ...                       Last Name=Two
    Click Modal Button        Save
    ${winning_id} =  Get Current Record Id
    Store Session Record  Contact  ${winning_id}
    Go To Object Home  Contact
    Page Should Contain  Robot One
    Page Should Contain  Robot Two
    Go To Setup Home
    Open App Launcher
    Input Text  //input[@placeholder='Search apps or items...']  Contact Merge
    Click Link  Contact Merge
    Select Frame with ID  vfFrameId
    Input Text  //input[@placeholder='Search Contacts']  Robot
    Click Element  //input[@value='Search']
    Click Element  (//span[@id='fauxCBSelect'])[1]
    Click Element  (//span[@id='fauxCBSelect'])[2]
    Click Element  //input[@value='Next']
    Click Button  name:Merge
    Click Element  //input[@value='Merge']
    Unselect Frame
    # Validate Results
    Reload Page
    Location Should Contain  ${winning_id}
    Go To Object Home  Contact
    Page Should Not Contain  Robot One
    Page Should Contain  Robot Two