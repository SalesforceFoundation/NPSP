*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Delete Level
    ${level_name}     Create Level
    ${contact_id} =  Create Contact
    &{contact} =  Salesforce Get  Contact  ${contact_id} 
    Header Field Value    Account Name    &{contact}[LastName] Household
    Select Tab    Details
    Scroll Page To Location    100    400
    Click Edit Button    Edit Level
    Populate Lookup Field    Level    ${level_name}
    Click Record Button    Save
    Sleep    2
    Verify Field Value    Level    ${level_name}    Y
    Go To Object Home         npsp__Level__c
    Click Link    link=${level_name}
    Click Link    link=Show more actions
    Click Link    link=Delete
    Sleep    2
    Click Modal Button    Delete
    Go To Object Home    Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    Select Tab    Details
    Confirm Value    Level    ${level_name}    N
   
        