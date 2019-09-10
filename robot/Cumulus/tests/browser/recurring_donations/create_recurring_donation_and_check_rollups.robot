*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Recurring Donation And Check Rollups
    [Documentation]              This test verifies that Account, Contact, and Soft Credit Contact rollups are udpated
    ...                          when a Recurring Donation's Opportunities are Closed Won.
    
    #Create a Recurring Donation from a Contact
    ${ns} =  Get NPSP Namespace Prefix
    &{contact} =                 API Create Contact           Email=jjoseph@robot.com
    Go To Record Home            &{contact}[Id]
    &{recurringdonation} =       API Create Recurring Donation  npe03__Contact__c=&{contact}[Id]
    ...                          Name=Julian Recurring Donation
    ...                          npe03__Amount__c=100
    ...                          npe03__Installments__c=12
    ...                          npe03__Installment_Period__c=Monthly
    Go To Record Home            &{recurringdonation}[Id]

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity1} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=&{recurringdonation}[Id]
    ...                          ${ns}Recurring_Donation_Installment_Name__c=(1 of 12)

    Go To Record Home            ${opportunity1}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity2} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=&{recurringdonation}[Id]
    ...                          ${ns}Recurring_Donation_Installment_Name__c=(2 of 12)

    Go To Record Home            ${opportunity2}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Open NPSP Settings and run Rollups Donations Batch job
    Run Donations Batch Process

    #Check Rollups on Recurring Donation
    Go To Record Home            &{recurringdonation}[Id]
    Confirm Value                Total Paid Installments  2         Y
    Confirm Value                Paid Amount              $16.66    Y

    #Check Rollups on Recurring Contact
    Go To Record Home            &{contact}[Id]
    Select Tab                   Details
    Scroll Element Into View     text:Soft Credit Total
    Confirm Value                Total Gifts This Year    $16.66    Y
    Confirm Value                Total Gifts              $16.66    Y

    #Check Rollups on Recurring Account
    @{account} =                 Salesforce Query         Account
    ...                          select=Id
    ...                          npe01__One2OneContact__c=&{contact}[Id]
    Go To Record Home            ${account}[0][Id]
    Select Tab                   Details
    Scroll Element Into View     text:Membership Information
    Confirm Value                Total Gifts              $16.66    Y
    Confirm Value                Total Number of Gifts    2         Y

    #Open NPSP Settings and run Recurring Donations Batch job
    Open NPSP Settings           Bulk Data Processes           Recurring Donations Batch
    Click Element With Locator   npsp_settings.batch-button    idPanelRDBatch                   Run Batch
    Wait For Locator             npsp_settings.status          RD_RecurringDonations_BATCH      Completed

    #Check Rollups on Recurring Donation
    Go To Record Home            &{recurringdonation}[Id]
    Confirm Value                Total Paid Installments  2         Y
    Confirm Value                Paid Amount              $16.66    Y

    #Check Rollups on Recurring Contact
    Go To Record Home            &{contact}[Id]
    Select Tab                   Details
    Scroll Element Into View     text:Soft Credit Total
    Confirm Value                Total Gifts This Year    $16.66    Y
    Confirm Value                Total Gifts              $16.66    Y

    #Check Rollups on Recurring Account
    Go To Record Home            ${account}[0][Id]
    Select Tab                   Details
    Scroll Element Into View     text:Membership Information
    Confirm Value                Total Gifts              $16.66    Y
    Confirm Value                Total Number of Gifts    2         Y

    #Cleanup Closed Won Opportunities to assist Suite Teardown
    Salesforce Delete            Opportunity              ${opportunity1}[0][Id]
    Salesforce Delete            Opportunity              ${opportunity2}[0][Id]