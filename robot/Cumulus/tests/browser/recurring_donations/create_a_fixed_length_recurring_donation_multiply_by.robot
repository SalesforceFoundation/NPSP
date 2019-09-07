*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Fixed Length Recurring Donation
    
    #Create two Contacts in the Same Household
    &{contact} =                 API Create Contact           Email=jjoseph@robot.com
    Store Session Record         Account                      &{contact}[AccountId]
    &{contact2} =                API Create Contact           AccountId=&{contact}[AccountId]
    
    #Create a Fixed Length Recurring Donation
    Go To Record Home            &{contact}[Id]
    Click Link                   link=Show more actions
    Click Link                   link=New Recurring Donation
    Wait Until Modal Is Open
    Populate Form
    ...                          Recurring Donation Name=Robot Recurring Donation
    ...                          Amount=10 
    ...                          Installments=50
    Click Dropdown               Installment Period
    Click Link                   link=Weekly
    Click Dropdown               Schedule Type
    Click Link                   link=Multiply By
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
    ...                          Recurring_Donation_Installment_Name__c=(1 of 50)

    Go To Record Home            ${opportunity}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(2 of 50)

    Go To Record Home            ${opportunity}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Open NPSP Settings and run Rollups Donations Batch job
    Run Donations Batch Process

    #Check if 50th Opportunity for Recurring Donation Exists
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(50 of 50)
    Go To Record Home            ${opportunity}[0][Id]

    #Check Rollups on Recurring Donation
    Go To Record Home            ${recurringdonation}[0][Id]
    Confirm Value                Total Paid Installments      2         Y
    Confirm Value                Paid Amount                  $20.00    Y

    #Check Soft Credit Rollups on Household Contact
    Go To Record Home            &{contact2}[Id]
    Select Tab                   Details
    Scroll Element Into View     text:Household Donation Info
    Confirm Value                Soft Credit Total            $20.00    Y
    Confirm Value                Number of Soft Credits       2         Y

    #Check Rollups on Recurring Account
    @{account} =                 Salesforce Query             Account
    ...                          select=Id
    ...                          npe01__One2OneContact__c=&{contact}[Id]
    Go To Record Home            ${account}[0][Id]
    Select Tab                   Details
    Scroll Element Into View     text:Membership Information
    Confirm Value                Total Gifts                  $20.00    Y
    Confirm Value                Total Number of Gifts        2         Y