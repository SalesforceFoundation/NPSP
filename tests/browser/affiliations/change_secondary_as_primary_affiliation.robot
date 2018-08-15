*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Secondary Affiliation for Contact
    # Create Organization Account
    ${acc}    ${con}    Create Secondary Affiliation
    &{account} =  Salesforce Get  Account  ${acc}
    &{contact} =  Salesforce Get  Contact  ${con}
    Page Should Contain    &{contact}[LastName]
    Page Should Contain    &{account}[Name]
    Scroll Page To Location    50    600
    Sleep    5
    Click Id    &{account}[Name]
    Sleep    5
    Scroll Page To Location    0    400
    Click Edit Button    Edit Primary
    Sleep    5
    Select Checkbox    //div[contains(@class, "uiInput")]/label/following-sibling::input[@type='checkbox']
    Click Record Button    Save
    Sleep    5
    Click link    link=&{contact}[FirstName] &{contact}[LastName]
    Select Tab    Details
    Verify Field Value    Primary Affiliation    &{account}[Name]    Y