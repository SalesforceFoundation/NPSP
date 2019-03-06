*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Merge Contacts
    # Manually creating contact records, sosl doesn't always return api generated contacts
    Go To Object Home  Contact
    Click Object Button  New
    Populate Form
    ...                       First Name=Robot
    ...                       Last Name=One
    Click Modal Button        Save
    ${losing_id} =  Get Current Record Id
    Store Session Record  Contact  ${losing_id}
    Go To Object Home  Contact
    Click Object Button  New
    Populate Form
    ...                       First Name=Robot
    ...                       Last Name=Two
    Click Modal Button        Save
    ${winning_id} =  Get Current Record Id
    Store Session Record  Contact  ${winning_id}
    Go To Object Home  Contact
    Page Should Contain  Robot One
    Page Should Contain  Robot Two
    Select App Launcher Tab  Contact Merge
    Select Frame with Name  vfFrameId
    Wait Until Page Contains Element  //input[@placeholder='Search Contacts']
    Populate Address  Search Contacts  Robot
    Click Button  Search
    Click Element  //tr[./td/a[contains(@href,'${losing_id}')]]/td//span[@id='fauxCBSelect']
    Click Element  //tr[./td/a[contains(@href,'${winning_id}')]]/td//span[@id='fauxCBSelect']
    Click Button  Next
    Click Button  (//button[text()='Merge'])[1]
    Click Element  //input[@value='Merge']
    Unselect Frame
    # Validate Results
    Reload Page
    Location Should Contain  ${winning_id}
    Go To Object Home  Contact
    Page Should Not Contain  Robot One
    Page Should Contain  Robot Two