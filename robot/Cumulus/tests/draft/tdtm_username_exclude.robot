*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Update a Trigger Handler to Exclude a Username
    [tags]  unstable

    # Create a Contact so Trigger Handler records are created
    &{contact1} =                API Create Contact           Email=skristem@robot.com

    # Navigate to Recurring Donation Trigger Handler Record and exclude Scratch User
    @{triggerhandler} =          Salesforce Query             Trigger_Handler__c
    ...                          select=Id
    ...                          Class__c=RD_RecurringDonations_TDTM

    @{scratchuser} =             Salesforce Query             User
    ...                          select=Username
    ...                          Name=User User

    Go To Record Home            ${triggerhandler}[0][Id]
    Select Tab                   Details
    Click Link                   link=Show more actions
    Click Link                   link=Edit
    ${uppercaseusername} =       Convert To Uppercase         ${scratchuser}[0][Username]
    Populate Form
    ...                          Usernames to Exclude=${uppercaseusername}
    Click Button    Save

    # Create a Recurring Donation and verify no Opportunities are created
    &{contact} =                 API Create Contact           Email=jjoseph@robot.com
    Go To Record Home            &{contact}[Id]
    Click Link                   link=Show more actions
    Click Link                   link=New Recurring Donation
    Wait Until Modal Is Open
    Populate Form
    ...                          Recurring Donation Name=Robot Recurring Donation
    ...                          Amount=100 
    Click Dropdown               Installment Period
    Click Link                   link=Monthly
    Click Modal Button           Save
    Reload Page
    Select Tab  Related
    Load Related List            Recurring Donations
    Check Related List Values    Recurring Donations          Robot Recurring Donation
    Load Related List            Opportunities
    Verify Occurrence            Opportunities                0