*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Fixed Length Recurring Donation Divide By
    
    #Create a Recurring Donation
    ${ns} =  Get NPSP Namespace Prefix
    &{contact} =                 API Create Contact           Email=jjoseph@robot.com
    Go To Record Home            &{contact}[Id]
    &{recurringdonation} =       API Create Recurring Donation  npe03__Contact__c=&{contact}[Id]
    ...                          Name=Julian Recurring Donation
    ...                          npe03__Amount__c=1200
    ...                          npe03__Installments__c=12
    ...                          npe03__Schedule_Type__c=Divide By
    ...                          npe03__Installment_Period__c=Monthly
    Go To Record Home            &{recurringdonation}[Id]

    #Find 1st Opportunity for Recurring Donation and Check Amount
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=&{recurringdonation}[Id]
    ...                          ${ns}Recurring_Donation_Installment_Name__c=(1 of 12)
    ...                          StageName=Pledged
    Go To Record Home            ${opportunity}[0][Id]
    Select Tab                   Details
    Confirm Value                Amount                       $100.00    Y

    #Find 2nd Opportunity for Recurring Donation and Check Amount
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=&{recurringdonation}[Id]
    ...                          ${ns}Recurring_Donation_Installment_Name__c=(2 of 12)
    ...                          StageName=Pledged
    Go To Record Home            ${opportunity}[0][Id]
    Select Tab                   Details
    Confirm Value                Amount                       $100.00    Y