*** Settings ***		

Resource        robot/Cumulus/resources/NPSP.robot		
Suite Setup     Open Test Browser		
Suite Teardown  Delete Records and Close Browser		


*** Test Cases ***

Create Open Recurring Donation With Monthly Installment
    [Documentation]              This test verifies that a Recurring Donation can be created through the UI.

    &{contact} =                 API Create Contact    Email=skristem@robot.com		
    Go To Record Home            &{contact}[Id]		
    Click More Actions Button		
    Click Link                   link=New Open Recurring Donation		
    Wait Until Modal Is Open		
    Populate Form		
    ...                          Recurring Donation Name= Robot Recurring Donation		
    ...                          Amount=100
    Select Value From Dropdown   Installment Period              Monthly
    Click Modal Button           Save
    Wait Until Modal Is Closed		
    Reload Page		
    Select Tab  Related				
    Check Related List Values    Recurring Donations    Robot Recurring Donation		
    Load Related List            Opportunities		
    Click ViewAll Related List   Opportunities		
    ${return_value}              Verify Payment Details		
    Should be equal as strings   ${return_value}    12