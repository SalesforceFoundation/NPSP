*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Remove Primary Affiliation for Contact    
    ${acc}    ${con}    Create Primary Affiliation
    &{account} =  Salesforce Get  Account  ${acc}
    &{contact} =  Salesforce Get  Contact  ${con}
    Go To Object Home          Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    #Sleep    5
    Scroll Page To Location    50    600
    Select Related Row    &{account}[Name]
    Click Link    link=Delete
    Click Modal Button    Delete
    #Sleep    5
    Go To Object Home    Account
    #Sleep    5
    Click Link    link=&{account}[Name]
    Page Should not Contain Link     &{contact}[FirstName]
    
Remove Primary Affiliation for Contact2
    ${acc}    ${con}    Create Primary Affiliation
    &{account} =  Salesforce Get  Account  ${acc}
    &{contact} =  Salesforce Get  Contact  ${con}
    Go To Object Home          Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    Select Tab    Details
    Scroll Page To Location    100    300
    Click Edit Button    Edit Primary Affiliation
    #Sleep    5
    Scroll Page To Location    100    500
    Delete Icon    Primary Affiliation    &{account}[Name]
    Click Record Button    Save 
    #Sleep    5
    Scroll Page To Location    0    100
    Select Tab    Related
    #Sleep    5
    ${id}    ${status}    Check Status    &{account}[Name]
    Should Be Equal As Strings    ${status}    Former
    Go To Object Home          Account
    Click Link        link=&{account}[Name]
    #Sleep    5
    Scroll Page To Location    0    300
    Get Id
    Confirm Value    Status    Former    Y
      