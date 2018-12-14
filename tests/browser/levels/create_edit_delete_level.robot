*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${level_name}

*** Test Cases ***

Create Level and Verify
    ${level_id}  ${level_name}     Create Level
    Set Global Variable      ${level_name}
    Go To Record Home         ${level_id}
    Confirm Value    Minimum Amount (>=)    0.10    Y
    Confirm Value    Maximum Amount (<)     0.90    Y

Edit Level and Verify
    Click Link    link=Show more actions
    Click Link    link=Edit
    Select Frame With Title    Levels
    Enter Level Dd Values    Source Field    Smallest Gift
    Enter Level Values
    ...            Minimum Amount=0.01
    ...            Maximum Amount=0.99
    Set Focus To Element   xpath: //input[@value='Save']
    Click Button  Save
    Unselect Frame
    Wait For Locator  breadcrumb  Level
    Reload Page
    Wait Until Loading Is Complete
    Confirm Value    Minimum Amount (>=)    0.01    Y
    Confirm Value    Maximum Amount (<)     0.99    Y
    Confirm Value    Source Field    npo02__SmallestAmount__c    Y

Delete Level
    [tags]  unstable
    &{contact} =  API Create Contact
    Go To Record Home  &{contact}[Id]
    Select Tab    Details
    Click Edit Button    Edit Level
    Populate Lookup Field    Level    ${level_name}
    Click Record Button    Save
    Verify Field Value    Level    ${level_name}    Y
    Click Link    link=${level_name}
    Click Link    link=Show more actions
    Click Link    link=Delete
    Click Modal Button    Delete
    Go To Object Home    Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    Select Tab    Details
    Confirm Value    Level    ${level_name}    N
