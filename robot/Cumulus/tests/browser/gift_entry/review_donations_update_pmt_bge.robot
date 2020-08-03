*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Keywords ***
Setup Test Data
    &{account} =         API Create Organization Account    Name=${faker.company()}
    Set suite variable   &{ACCOUNT}
    ${date} =            Get Current Date         result_format=%Y-%m-%d
    Set suite variable   ${DATE}
    &{opportunity} =     API Create Opportunity   ${ACCOUNT}[Id]              Donation  
    ...                  StageName=Prospecting    
    ...                  Amount=500    
    ...                  CloseDate=${DATE}    
    ...                  npe01__Do_Not_Automatically_Create_Payment__c=false    
    ...                  Name=${ACCOUNT}[Name] Donation
    ${ui_date} =    Get Current Date                   result_format=%b %-d, %Y
    Set suite variable    ${UI_DATE}

*** Test Cases ***
Review Donation And Update Payment For BGE
    # [Documentation]                      Create an organization account with open opportunity (with payment record) via API. Go to SGE form
    # ...                                  select the donor as account and the account created. Verify review donations modal but select to create alternative opportunity.
    # ...                                  Enter details and save. Verify that new opportunity and payment are created with right info 
    [tags]                               unstable      feature:GE                    W-042803   
    #verify Review Donations link is available and update a payment                           
    Go To Page                           Landing                       GE_Gift_Entry         
    Click Gift Entry Button              New Batch
    Wait Until Modal Is Open
    Select Template                      Default Gift Entry Template
    Load Page Object                     Form                          Gift Entry
    Fill Gift Entry Form
    ...                                  Batch Name=${ACCOUNT}[Name]Automation Batch
    ...                                  Batch Description=This is a test batch created via automation script
    Click Gift Entry Button              Next
    Click Gift Entry Button              Save
    Current Page Should Be               Form                          Gift Entry
    Fill Gift Entry Form
    ...                                  Donor Type=Account1
    ...                                  Existing Donor Organization=${ACCOUNT}[Name]
    Click Button                         Review Donations
    Wait Until Modal Is Open
    Click Button                         Update this Payment
    Wait Until Modal Is Closed 
    Fill Gift Entry Form                 Donation Amount=499.50
    Click Button                         Save & Enter New Gift
    Verify Gift Count                    1
    Verify Table Field Values               Batch Gifts
    ...                                     Donor Name=&{ACCOUNT}[Name]
    ...                                     Opportunity: Amount=$499.50
    ...                                     ${DATE}[Field Label]=${UI_DATE}
    Click Gift Entry Button                 Process Batch
    Click Data Import Button                NPSP Data Import                button       Begin Data Import Process
    Wait For Batch To Process               BDI_DataImport_BATCH            Completed
    Click Button With Value                 Close
    