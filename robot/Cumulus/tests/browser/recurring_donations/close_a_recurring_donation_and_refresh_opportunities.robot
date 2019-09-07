*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Test Cases ***

Create and Close a Recurring Donation and Refresh Opportunities

    #Create a Recurring Donation
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
    Click Dropdown               Open Ended Status
    Click Link                   link=Open
    Click Modal Button           Save
    @{recurringdonation} =       Salesforce Query             npe03__Recurring_Donation__c
    ...                          select=Id
    ...                          npe03__Contact__c=&{contact}[Id]
    Go To Record Home            ${recurringdonation}[0][Id]

    #Find 1st Opportunity for Recurring Donation and Close It
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(1)
    Go To Record Home            ${opportunity}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Find 2nd Opportunity for Recurring Donation and Close It
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(2)
    Go To Record Home            ${opportunity}[0][Id]
    Click Link                   link=Edit
    Click Dropdown               Stage
    Click Link                   link=Closed Won
    Click Modal Button           Save

    #Refresh Opportunities on Recurring Donation
    Go To Record Home            ${recurringdonation}[0][Id]
    Click Link                   link=Show more actions
    Click Link                   link=Refresh Opportunities

    #Find 2nd Opportunity for Recurring Donation
    @{opportunity} =             Salesforce Query             Opportunity
    ...                          select=Id
    ...                          npe03__Recurring_Donation__c=${recurringdonation}[0][Id]
    ...                          Recurring_Donation_Installment_Name__c=(3)
    Go To Record Home            ${opportunity}[0][Id]
    Select Tab                   Details
    Confirm Value                Stage                        Closed Lost    Y