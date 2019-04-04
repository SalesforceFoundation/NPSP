*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Donation from a Contact and Delete Opportunity
    &{contact} =  API Create Contact    Email=skristem@robot.com
    Store Session Record    Account    &{contact}[AccountId]
    &{opportunity} =  API Create Opportunity    &{Contact}[AccountId]    Donation    Name=Delete test $100 donation
    Go To Record Home  &{opportunity}[Id]
    ${donation_name}    Get Main Header
    Go To Object Home         Opportunity
    Select Row    ${donation_name}
    #Sleep    5
    Click Link    link=Delete
    Click Modal Button        Delete
    #Sleep    5 
    Page Contains Record    ${donation_name}
    Go To Record Home  &{contact}[AccountId]
    Select Tab    Details
    Scroll Element Into View    text:Membership Information
    Confirm Value           Total Gifts    $0.00    Y
    Confirm Value           Total Number of Gifts    0    Y
