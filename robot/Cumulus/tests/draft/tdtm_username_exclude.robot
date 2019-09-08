*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
#Suite Teardown  Delete Records and Close Browser

*** Keywords ***

API Modify Trigger Handler
    [Arguments]      ${triggerhandler_id}      &{fields}
    ${ns} =  Get NPSP Namespace Prefix
    Salesforce Update       ${ns}Trigger_Handler__c     ${triggerhandler_id}
    ...                     &{fields}
    @{records} =  Salesforce Query      ${ns}Trigger_Handler__c
    ...              select=Id
    ...              Id=${triggerhandler_id}
    &{triggerhandler} =  Get From List  ${records}  0
    [return]         &{triggerhandler}

*** Test Cases ***

Update a Trigger Handler to Exclude a Username
    [tags]  unstable

    # Create an Account so Trigger Handler records are created
    &{account} =                 API Create Organization Account

    # Navigate to Recurring Donation Trigger Handler Record and exclude Scratch User
    ${ns} =  Get NPSP Namespace Prefix
    @{triggerhandler} =          Salesforce Query             ${ns}Trigger_Handler__c
    ...                          select=Id
    ...                          ${ns}Class__c=RD_RecurringDonations_TDTM

    @{scratchuser} =             Salesforce Query             User
    ...                          select=Username
    ...                          Name=User User

    Go To Record Home            ${triggerhandler}[0][Id]
    ${uppercaseusername} =       Convert To Uppercase         ${scratchuser}[0][Username]
    API Modify Trigger Handler   ${triggerhandler}[0][Id]     ${ns}Usernames_to_Exclude__c=${uppercaseusername}


    # Select Tab                   Details
    # Click Link                   link=Show more actions
    # Click Link                   link=Edit
    # Capture Page Screenshot
    # ${uppercaseusername} =       Convert To Uppercase         ${scratchuser}[0][Username]
    # Capture Page Screenshot
    # Populate Form
    # ...                          Usernames to Exclude=${uppercaseusername}
    # Capture Page Screenshot
    # Click Button                 Save

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