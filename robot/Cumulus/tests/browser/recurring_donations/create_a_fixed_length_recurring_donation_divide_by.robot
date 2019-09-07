*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create Fixed Length Recurring Donation Divide By
    
    #Create a Recurring Donation
    &{contact} =                 API Create Contact           Email=jjoseph@robot.com
    Go To Record Home            &{contact}[Id]
    Click Link                   link=Show more actions
    Click Link                   link=New Recurring Donation
    Wait Until Modal Is Open
    Populate Form
    ...                          Recurring Donation Name=Robot Recurring Donation
    ...                          Amount=1200 
    ...                          Installments=12
    Click Dropdown               Installment Period
    Click Link                   link=Monthly
    Click Dropdown               Schedule Type
    Click Link                   link=Divide By
    Click Modal Button           Save
    @{recurringdonation} =       Salesforce Query             npe03__Recurring_Donation__c
    ...                          select=Id
    ...                          npe03__Contact__c=&{contact}[Id]
    Go To Record Home            ${recurringdonation}[0][Id]

    #Find 1st Opportunity for Recurring Donation and Check Amount
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(1 of 12)
    ...                          StageName=Pledged
    Go To Record Home            ${opportunity}[0][Id]
    Select Tab                   Details
    Confirm Value                Amount                       $100.00    Y

    #Find 2nd Opportunity for Recurring Donation and Check Amount
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(12 of 12)
    ...                          StageName=Pledged
    Go To Record Home            ${opportunity}[0][Id]
    Select Tab                   Details
    Confirm Value                Amount                       $100.00    Y