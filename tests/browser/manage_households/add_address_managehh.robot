*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Add New Address to Household 
    &{contact1} =  API Create Contact    MailingStreet=50 Fremont Street    MailingCity=San Francisco    MailingPostalCode=95320    MailingState=CA    MailingCountry=USA
    Store Session Record    Account    &{contact1}[AccountId]
    Go To Record Home  &{contact1}[AccountId]    
    # Click Link    link=Show more actions
    Click Link    link=Manage Household 
    Wait For Locator    frame    Manage Household   
    Select Frame With Title   Manage Household
    Wait For Locator    span_button    Change Address
    Click Button    Change Address
    Click ManageHH Link     Enter a new address
    Fill Address Form
    ...                       Street=123 Dummy Street
    ...                       City=Tracy
    ...                       State=CA
    ...                       Postal Code=99999
    ...                       Country=US   
    Click Span Button    Set Address
    Click Button       title=Save
    Unselect Frame
    Go To Record Home    &{contact1}[Id]
    Scroll Page To Location    0    1200
    ${status}    Verify Details Address    Mailing Address    123 Dummy Street     Tracy, CA 99999     US
    Should Be Equal as Strings    ${status}    pass
    Go To Object Home          Account
    Click Link    link=&{contact1}[LastName] Household
    Select Tab  Details
    Scroll Page To Location    0    300
    ${status}    Verify Details Address    Billing Address    123 Dummy Street     Tracy, CA 99999     US
    Should Be Equal as Strings    ${status}    pass
