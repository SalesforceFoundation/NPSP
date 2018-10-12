*** Settings ***

Resource        tests/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser


*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    ${contact_id} =  Create Contact with Email
    &{contact} =  Salesforce Get  Contact  ${contact_id}
    Header Field Value    Account Name    &{contact}[LastName] Household
    Scroll Page To Location    0    500
    Click Related List Button  Recurring Donations    New
    Populate Form
    ...                       Recurring Donation Name= Robot Recurring Donation
    ...                       Amount=100 
    ...                       Installments=1 
    Click Dropdown    Date Established
    Change Month      Go to previous month
    Pick Date         10 
    Click Dropdown    Open Ended Status
    Click Link        link=Open
    Click Dropdown    Installment Period
    Click Link        link=Monthly
    Click Dropdown    Schedule Type
    Click Link        link=Multiply By
    Click Modal Button        Save