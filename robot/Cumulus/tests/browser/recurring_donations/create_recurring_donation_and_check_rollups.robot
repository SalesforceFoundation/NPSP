*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Recurring Donation And Check Rollups
    
    #Create a Recurring Donation from a Contact
    &{contact} =                 API Create Contact           Email=jjoseph@robot.com
    Go To Record Home            &{contact}[Id]
    Click Link                   link=Show more actions
    Click Link                   link=New Recurring Donation
    Wait Until Modal Is Open
    Populate Form
    ...                          Recurring Donation Name=Robot Recurring Donation
    ...                          Amount=100 
    ...                          Installments=12
    Click Dropdown               Installment Period
    Click Link                   link=Monthly
    Click Modal Button           Save

    #Find Recurring Donation
    @{recurringdonation} =       Salesforce Query             npe03__Recurring_Donation__c
    ...                          select=Id
    ...                          npe03__Contact__c=&{contact}[Id]
    Go To Record Home            ${recurringdonation}[0][Id]

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(1 of 12)

    Go To Record Home            ${opportunity}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(2 of 12)

    Go To Record Home            ${opportunity}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Open NPSP Settings and run Rollups Donations Batch job
    Run Donations Batch Process

    #Check Rollups on Recurring Donation
    Go To Record Home            ${recurringdonation}[0][Id]
    Confirm Value                Total Paid Installments  2         Y
    Confirm Value                Paid Amount              $16.66    Y

    #Check Rollups on Recurring Contact
    Go To Record Home            &{contact}[Id]
    Select Tab                   Details
    Scroll Element Into View     text:Soft Credit Totals
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
    Go To Record Home            ${recurringdonation}[0][Id]
    Confirm Value                Total Paid Installments  2         Y
    Confirm Value                Paid Amount              $16.66    Y

    #Check Rollups on Recurring Contact
    Go To Record Home            &{contact}[Id]
    Select Tab                   Details
    Scroll Element Into View     text:Soft Credit Totals
    Confirm Value                Total Gifts This Year    $16.66    Y
    Confirm Value                Total Gifts              $16.66    Y

    #Check Rollups on Recurring Account
    Go To Record Home            ${account}[0][Id]
    Select Tab                   Details
    Scroll Element Into View     text:Membership Information
    Confirm Value                Total Gifts              $16.66    Y
    Confirm Value                Total Number of Gifts    2         Y