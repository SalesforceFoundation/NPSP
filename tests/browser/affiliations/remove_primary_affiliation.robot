*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

 
*** Test Cases ***    
Remove Primary Affiliation for Contact    
    &{account} =  API Create Organization Account
    &{contact} =  API Create Contact    Email=skristem@robot.com    
    Store Session Record    Account    &{contact}[AccountId]
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
    Store Session Record    Account    &{contact}[AccountId]
    API Create Primary Affiliation    &{account}[Id]    &{contact}[Id]
    Go To Object Home          Contact
    Click Link    link=&{contact}[FirstName] &{contact}[LastName]
    # To make sure the field we want to edit has rendered,
    # scroll to the one below it
    Scroll Element Into View  text:Do Not Contact
    Click Button    title:Edit Primary Affiliation
    Wait For Locator  record.edit_form
    Page Scroll To Locator  detail_page.edit_mode.section_header    Contact Information    
    Delete Icon    Primary Affiliation    &{account}[Name]
    Click Record Button    Save 
    Scroll Page To Location    0    0
    Select Tab    Related
    Load Related List    Organization Affiliations
    ${id}    ${status}    Check Status    &{account}[Name]
    Should Be Equal As Strings    ${status}    Former
    Go To Object Home          Account
    Click Link        link=&{account}[Name]
    Load Related List    Affiliated Contacts
    Get Id
    Confirm Value    Status    Former    Y
