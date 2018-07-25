*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Address to Household 
    #1 contact HouseHold Validation
    ${contact_id1} =  Create Contact with Address
    &{contact1} =  Salesforce Get  Contact  ${contact_id1}
    Header Field Value    Account Name    &{contact1}[LastName] Household  
    
        
    Click Link    link=&{contact1}[LastName] Household    
    Click Link    link=Show more actions
    Click Link    link=Manage Household    
    Sleep     3        
    Select Frame With Title   Manage Household
    Click Button    Change Address
    Click Element     //h4[text()="Enter a new address"]
    Fill Address Form
    ...                       Street=123 Dummy Street
    ...                       City=Tracy
    ...                       State=CA
    ...                       Postal Code=99999
    ...                       Country=US   
    
    Click Managehh Special Button    Set Address
    Sleep    2
    Click Managehh Button       Save
    Sleep    3
    Click Link    link=&{contact1}[FirstName] &{contact1}[LastName]
    Sleep    3
    Select Tab    Details
    Scroll Page To Location    0    1200
    Verify Details Address    Mailing Address    123 Dummy Street, Tracy, CA 99999, US
    Go To Object Home          Account
    Click Link    link=&{contact1}[LastName] Household
    Select Tab    Details
    Scroll Page To Location    0    300
    Verify Details Address    Billing Address    123 Dummy Street, Tracy, CA 99999, US


