*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Variables ***
${level_name}

*** Test Cases ***

Create Level and Verify
    ${level_name}     Create Level
    Set Global Variable      ${level_name}
    Go To Object Home         npsp__Level__c
    Click Link    link=${level_name}
    ${level_name1}    Get Main Header
    Should be Equal as Strings    ${level_name1}      ${level_name}  
    Confirm Value    Minimum Amount (>=)    0.10    Y
    Confirm Value    Maximum Amount (<)     0.90    Y
    
    
Edit Level and Verify
    Click Link    link=Edit
    Sleep    2
    Select Frame With Title    Levels
    Enter Level Dd Values    Source Field    Smallest Gift
    Enter Level Values
    ...            Minimum Amount=0.01
    ...            Maximum Amount=0.99
    
    Click Level Button    Save
    Go To Object Home         npsp__Level__c
    Click Link    link=${level_name}  
    Confirm Value    Minimum Amount (>=)    0.01    Y
    Confirm Value    Maximum Amount (<)     0.99    Y
    Sleep    2
    Confirm Value    Source Field    npo02__SmallestAmount__c    Y
            
Delete Level
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