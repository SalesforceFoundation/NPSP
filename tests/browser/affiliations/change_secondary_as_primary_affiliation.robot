*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Secondary Affiliation for Contact
    &{account} =  API Create Organization Account
    &{contact} =  API Create Contact    Email=skristem@robot.com    
    API Create Secondary Affiliation    &{account}[Id]    &{contact}[Id]
    Go To Record Home  &{contact}[Id]
    Page Should Contain    &{contact}[LastName]
    Click Related Item Link  Organization Affiliations  &{account}[Name]
    # Scroll down so elements aren't hidden behind the footer
    Scroll Page To Location    0    400
    Click Edit Button    Edit Primary
    Wait For Locator  checkbox  Primary
    Select Lightning Checkbox    Primary
    Click Record Button    Save
    #Sleep    5
    Go To Object Home    Contact
    Click link    link=&{contact}[FirstName] &{contact}[LastName]
    Select Tab    Details
    Verify Field Value    Primary Affiliation    &{account}[Name]    Y
