*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    &{account} =         API Create Organization Account    Name=${faker.company()}
    Set suite variable   &{ACCOUNT}
    ${date} =            Get Current Date         result_format=%Y-%m-%d
    Set suite variable   ${DATE}
    &{CONTACT} =         API Create Contact
    ...                  FirstName=${faker.first_name()}
    ...                  LastName=${faker.last_name()}
    ...                  npe01__HomeEmail__c=test@example.com
    Set suite variable   &{CONTACT}

*** Test Cases ***
Create Gift For Contact Using New Gift Button
    # [Documentation]                      Create an organization account with open opportunity (with payment record) via API. Go to SGE form
    # ...                                  select the donor as account and the account created. Verify review donations modal but select to create alternative opportunity.
    # ...                                  Enter details and save. Verify that new opportunity and payment are created with right info
    [tags]                               unstable      feature:GE                    W-039584
    Go To Page                           Details              Contact       object_id=${CONTACT}[Id]
    Current Page Should Be               Details              Contact
    Click Link                           title=New Gift
    Current Page Should Be               Form                          Gift Entry
    Verify Field Default Value
    ...                                  Existing Donor Contact=${CONTACT}[Name]
    ...                                  Contact First Name=${CONTACT}[FirstName]
    ...                                  Contact Last Name=${CONTACT}[LastName]
    ...                                  Contact Personal Email=${CONTACT}[npe01__HomeEmail__c]
    Fill Gift Entry Form
    ...                                  Donation Date=Today
    ...                                  Donation Amount=150
    Click Button                         Save
    #verify new opportunity and its payment are created with correct info
    Current Page Should Be               Details              Opportunity
    ${newopp_id}                         Save Current Record ID For Deletion    Opportunity
    Verify Expected Values               nonns                Opportunity       ${newopp_id}
    ...                                  Amount=150.0
    ...                                  CloseDate=${DATE}
    ...                                  StageName=Closed Won
    &{payment} =  API Query Record       npe01__OppPayment__c      npe01__Opportunity__c=${newopp_id}
    Verify Expected Values               nonns                          npe01__OppPayment__c    ${payment}[Id]
    ...                                  npe01__Payment_Amount__c=150.0
    ...                                  npe01__Payment_Date__c=${DATE}
    ...                                  npe01__Paid__c=True

Create Gift For Account Using New Gift Button
    # [Documentation]                      Create an organization account with open opportunity (with payment record) via API. Go to SGE form
    # ...                                  select the donor as account and the account created. Verify review donations modal but select to create alternative opportunity.
    # ...                                  Enter details and save. Verify that new opportunity and payment are created with right info
    [tags]                               unstable      feature:GE                    W-039584
    Go To Page                           Details              Account       object_id=${ACCOUNT}[Id]
    Current Page Should Be               Details              Account
    Click Link                           title=New Gift
    Current Page Should Be               Form                          Gift Entry
    Verify Field Default Value
    ...                                  Existing Donor Organization=${ACCOUNT}[Name]
    # ...                                  Contact First Name=${CONTACT}[FirstName]
    # ...                                  Contact Last Name=${CONTACT}[LastName]
    # ...                                  Contact Personal Email=${CONTACT}[npe01__HomeEmail__c]
    Fill Gift Entry Form
    ...                                  Donation Date=Today
    ...                                  Donation Amount=1500
    Click Button                         Save
    #verify new opportunity and its payment are created with correct info
    Current Page Should Be               Details              Opportunity
    ${newopp_id}                         Save Current Record ID For Deletion    Opportunity
    Verify Expected Values               nonns                Opportunity       ${newopp_id}
    ...                                  Amount=1500.0
    ...                                  CloseDate=${DATE}
    ...                                  StageName=Closed Won
    &{payment} =  API Query Record       npe01__OppPayment__c      npe01__Opportunity__c=${newopp_id}
    Verify Expected Values               nonns                          npe01__OppPayment__c    ${payment}[Id]
    ...                                  npe01__Payment_Amount__c=1500.0
    ...                                  npe01__Payment_Date__c=${DATE}
    ...                                  npe01__Paid__c=True
