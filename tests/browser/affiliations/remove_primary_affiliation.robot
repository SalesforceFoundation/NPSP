*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Remove Primary Affiliation for Contact    
    &{account} =  API Create Organization Account
    &{contact} =  API Create Contact    Email=skristem@robot.com    
    API Create Primary Affiliation    &{account}[Id]    &{contact}[Id]
    Go To Object Home          Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    Select Tab  Related
    Click Related Item Popup Link  Organization Affiliations  &{account}[Name]  Delete
    Click Modal Button    Delete
    #Sleep    5
    Go To Object Home    Account
    #Sleep    5
    Click Link    link=&{account}[Name]
    Page Should not Contain Link     &{contact}[FirstName]
    
Remove Primary Affiliation for Contact2
    [tags]  unstable
    &{account} =  API Create Organization Account
    &{contact} =  API Create Contact    Email=skristem@robot.com
    API Create Primary Affiliation    &{account}[Id]    &{contact}[Id]
    Go To Object Home          Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    # To make sure the field we want to edit has rendered,
    # scroll to the one below it
    Scroll Element Into View  text:Do Not Contact
    Click Button    title:Edit Primary Affiliation
    Wait For Locator  record.edit_form
    #Sleep    5
    Scroll Page To Location    100    500
    Delete Icon    Primary Affiliation    &{account}[Name]
    Click Record Button    Save 
    #Sleep    5
    Scroll Page To Location    0    100
    Select Tab    Related
    Scroll Page To Location    0    500
    #Sleep    5
    ${id}    ${status}    Check Status    &{account}[Name]
    Should Be Equal As Strings    ${status}    Former
    Go To Object Home          Account
    Click Link        link=&{account}[Name]
    #Sleep    5
    Scroll Page To Location    0    300
    Get Id
    Confirm Value    Status    Former    Y
