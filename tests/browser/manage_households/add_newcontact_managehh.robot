*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Contact to Existing Household 
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact}[AccountId]
    Go To Record Home  &{contact}[AccountId] 
    # Click Link    link=Show more actions
    Click Link    link=Manage Household    
    Sleep     5     Input-textbox-notloaded-properly    
    Select Frame With Title   Manage Household
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Populate Field By Placeholder    Find a Contact or add a new Contact to the Household    ${first_name} ${last_name}
    Wait For Locator    manage_hh_page.button    New Contact
    Click Button    text=New Contact
    Wait For Locator    span_button    New Contact    
    Click Span Button    New Contact
    Click Button       title=Save
    Unselect Frame
    Wait Until Page Contains    Account Owner
    Wait For Record To Update    &{contact}[AccountId]    &{contact}[LastName] and ${last_name} Household
    Select Tab    Related
    Load Related List    Contacts
    Verify Related List Items    Contacts    ${first_name} ${last_name}
