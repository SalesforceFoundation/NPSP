*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Convert Lead To Account
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    ${company} =              Generate Random String  
    Go To Object Home         Lead
    Click Object Button       New
    Populate Form
    ...                       First Name=${first_name}
    ...                       Last Name=${last_name}
    ...                       Company=${company}
    Search Field By Value          Street            50 Fremont Street  
    Search Field By Value          City              San Francisco
    Search Field By Value          Zip/Postal Code   95320
    Search Field By Value          State/Province    CA
    Search Field By Value          Country           USA
    Select Value From Dropdown   Lead Status              Working - Contacted
    Click Modal Button        Save    
    Wait Until Modal Is Closed
    Go To Object Home         Lead
    Click Link                link=${first_name} ${last_name}
    Click Actions Link          Convert
    Click Lead Button    vfFrameId    button    Convert
    Current Page Should Be    Details    Contact
    #Sleep    2
    # Select Frame with Name      vfFrameId
    # Click Element             //input[@value="Convert"]
    #Sleep    2
    Go To Page        Listing         Contact
    Page Should Contain Link    ${first_name} ${last_name}
    Go To Page        Listing         Account
    Page Should Contain Link    ${last_name} Household
    Page Should Contain Link    ${company}

*** Keywords ***
Click Lead Button
    [Arguments]       ${frame_name}    ${ele_path}     @{others}
    Select Frame And Click Element    ${frame_name}    ${ele_path}     @{others}