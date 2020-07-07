*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    &{account} =         API Create Organization Account    Name=${faker.company()}
    Set suite variable   &{account}
    ${date} =            Get Current Date         result_format=%Y-%m-%d
    Set suite variable   ${date}
    &{opportunity} =     API Create Opportunity   ${account}[Id]              Donation  
    ...                  StageName=Prospecting    
    ...                  Amount=150    
    ...                  CloseDate=${date}    
    ...                  npe01__Do_Not_Automatically_Create_Payment__c=false    
    ...                  Name=${account}[Name] Donation
    Set suite variable   &{opportunity}
    ${ns} =              Get NPSP Namespace Prefix
    Set suite variable   ${ns}

*** Test Cases ***

Review Donation And Create Opportunity For SGE
    # [Documentation]                         Create a custom field on opportunity and npsp data import objects. Create advanced mapping to these fields.
    # ...                                     Verify that the mapped field is available for selection while creating a new template and once selected, its avialble on newly created batch gift form
    # ...                                     Remove field from template, delete mapping and verify that the new field is not avaialable for selection while creating template.  
    [tags]                               unstable      feature:GE                    W-   
                               
    Go To Page                           Landing                       GE_Gift_Entry         
    Click Gift Entry Button              New Single Gift
    Current Page Should Be               Form                          Gift Entry
    Fill Gift Entry Form
    ...                                  Donor Type=Account1
    ...                                  Existing Donor Contact=&{Contact}[Name]
    Click Button                         Review Donations
    Wait Until Modal Is Open
    Click Button                         Alternatively, create a new Opportunity.
    Wait Until Modal Is Closed 
    Fill Gift Entry Form
    ...                                  Donation Date=Today
    ...                                  Donation Amount=150
    Click Button                         Save
    Current Page Should Be               Details                        Opportunity
    ${newopp_id}                         Save Current Record ID For Deletion     Opportunity
    Verify Expected Values               nonns    Opportunity    ${newopp_id}
    ...                                  Amount=150.0
    ...                                  CloseDate=${date}
    ...                                  StageName=Closed Won
    Select Tab                           Related
    Click Related Table Item Link        Payments      Paid
    Current Page Should Be               Details       Payments
    ${pay_id}                            Save Current Record ID For Deletion     npe01__OppPayment__c
    Verify Expected Values               nonns    npe01__OppPayment__c    ${pay_id}
    ...                                  npe01__Payment_Amount__c=150.0
    ...                                  npe01__Payment_Date__c=${date}
    ...                                  npe01__Paid__c=True

