*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Fixed Length Recurring Donation Multiply By
    [Documentation]              This test verifies that Opportunities with the proper mulitplied amount are created for a Recurring Donation.
    ...                          This test case also verified the correct number of opportunities are created and related Account, Contact, 
    ...                          and Soft Credit Contact rollups are udpated.
    
    #Create two Contacts in the Same Household
    ${ns} =  Get NPSP Namespace Prefix
    &{contact} =                 API Create Contact           Email=jjoseph@robot.com
    Store Session Record         Account                      &{contact}[AccountId]
    &{contact2} =                API Create Contact           AccountId=&{contact}[AccountId]
    
    #Create a Fixed Length Recurring Donation
    Go To Record Home            &{contact}[Id]
    &{recurringdonation} =       API Create Recurring Donation  npe03__Contact__c=&{contact}[Id]
    ...                          Name=Julian Recurring Donation
    ...                          npe03__Amount__c=10
    ...                          npe03__Installments__c=50
    ...                          npe03__Schedule_Type__c=Multiply By
    ...                          npe03__Installment_Period__c=Weekly
    Go To Record Home            &{recurringdonation}[Id]

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity1} =            Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=&{recurringdonation}[Id]
    ...                          ${ns}Recurring_Donation_Installment_Name__c=(1 of 50)

    Go To Record Home            ${opportunity1}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity2} =            Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=&{recurringdonation}[Id]
    ...                          ${ns}Recurring_Donation_Installment_Name__c=(2 of 50)

    Go To Record Home            ${opportunity2}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Open NPSP Settings and run Rollups Donations Batch job
    Run Donations Batch Process

    #Check if 50th Opportunity for Recurring Donation Exists
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=&{recurringdonation}[Id]
    ...                          ${ns}Recurring_Donation_Installment_Name__c=(50 of 50)
    Go To Record Home            ${opportunity}[0][Id]

    #Check Rollups on Recurring Donation
    Go To Record Home            &{recurringdonation}[Id]
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

    #Cleanup Closed Won Opportunities to assist Suite Teardown
    Salesforce Delete            Opportunity              ${opportunity1}[0][Id]
    Salesforce Delete            Opportunity              ${opportunity2}[0][Id]