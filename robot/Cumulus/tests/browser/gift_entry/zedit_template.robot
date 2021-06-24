*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/PaymentPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
&{method}         Default Value=Check
&{check}          Default Value=abc11233
&{date_default}   Default Value=Today
&{custom}         Required=checked
${amount}         50
${msg}            Automation test

*** Keywords ***
Setup Test Data
    &{contact} =    API Create Contact                 FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable    &{contact}
    &{account} =    API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{account}
    ${org_ns} =     Get Org Namespace Prefix
    Set suite variable    ${org_ns}
    ${ns} =         Get NPSP Namespace Prefix
    Set suite variable    ${ns}
    ${ui_date} =    Get Current Date                   result_format=%b %-d, %Y
    Set suite variable    ${ui_date}
    ${date} =       Get Current Date                   result_format=%Y-%m-%d
    Set suite variable    ${date}
    ${batch_name} =  Generate Random String
    Set Suite Variable    ${batch_name}

*** Test Cases ***

Edit GE Template And Verify Changes
    [Documentation]                  This test case makes edits to Default gift entry template and verifies that edits are saved
    ...                              and available when a Single gift or batch gift are created.

    [tags]                           feature:GE          W-039559
    # Edit Default template to add some default values and add a new field to form
    Go To Page                       Landing                       GE_Gift_Entry
    Click Link                       Templates
    Select Template Action           Default Gift Entry Template   Edit
    Current Page Should Be           Template                      GE_Gift_Entry
    Click Gift Entry Button          Next: Form Fields
    Perform Action On Object Field   select                        Account 1                     custom_acc_text
    Perform Action On Object Field   select                        Opportunity                   Donation Imported
    Fill Template Form
    ...                              Account 1: custom_acc_text=&{custom}
    ...                              Opportunity: Close Date=&{date_default}
    ...                              Payment: Check/Reference Number=&{check}
    ...                              Payment: Payment Method=&{method}
    Click Gift Entry Button          Next: Batch Settings
    Add Batch Table Columns          Donor Name     Donation Name       Status      Failure Information
    Click Gift Entry Button          Save & Close
    #Verify Default values are displayed on the Single Gift Form
    Current Page Should Be           Landing                       GE_Gift_Entry
    Click Gift Entry Button          New Single Gift
    Current Page Should Be           Form                          Gift Entry
    Verify Field Default Value
    ...                              Donation Date=${ui_date}
    ...                              Check/Reference Number=abc11233
    ...                              Payment Method=Check
    # Verify Single Gift form throws error when a required field is not filled, correct and save
    Fill Gift Entry Form
    ...                              Donor Type=Account1
    ...                              Existing Donor Organization Account=${account}[Name]
    ...                              Donation Amount=${amount}
    Click Gift Entry Button          Save
    Verify Error For Field
    ...                              Account 1: custom_acc_text=Complete this field.
    cumulusci.robotframework.Salesforce.Scroll Element Into View         npsp:gift_entry.form_header:New Gift
    Fill Gift Entry Form
    ...                              Account 1: custom_acc_text=${msg}
    Click Special Button             Save
    # Verify default values and newly added field to the form on payment and account records
    Current Page Should Be           Details                       Opportunity
    ${opp_id} =                      Save Current Record ID For Deletion     Opportunity
    ${pay_id} =                      API Get Id                    npe01__OppPayment__c        npe01__Opportunity__c=${opp_id}
    Verify Expected Values           nonns    npe01__OppPayment__c    ${pay_id}
    ...                              npe01__Payment_Amount__c=50.0
    ...                              npe01__Payment_Date__c=${date}
    ...                              npe01__Paid__c=True
    ...                              npe01__Check_Reference_Number__c=abc11233
    ...                              npe01__Payment_Method__c=Check
    Verify Expected Values           nonns    Account     ${account}[Id]
    ...                              ${org_ns}custom_acc_text__c=${msg}
    #Create a new batch and verify default values are displayed on the Batch Gift Form
    Go To Page                       Landing                       GE_Gift_Entry
    Create Gift Entry Batch          Default Gift Entry Template   ${batch_name}
    Current Page Should Be           Form                          Gift Entry
    ${batch_id} =                    Save Current Record ID For Deletion     ${ns}DataImportBatch__c
    Verify Field Default Value
    ...                              Donation Date=${ui_date}
    ...                              Check/Reference Number=abc11233
    ...                              Payment Method=Check
    # Verify batch gift form throws error when a required field is not filled, correct and save
    Fill Gift Entry Form
    ...                              Donor Type=Contact1
    ...                              Existing Donor Contact=${contact}[Name]
    ...                              Donation Amount=${amount}
    Click Gift Entry Button          Save & Enter New Gift
    Verify Error For Field
    ...                              Account 1: custom_acc_text=Complete this field.
    # Added scrolls to fix menu from blocking 'Process Batch' button.
    cumulusci.robotframework.Salesforce.Scroll Element Into View         npsp:gift_entry.button:button Process Batch
    Fill Gift Entry Form
    ...                              Account 1: custom_acc_text=${msg}
    Click Special Button             Save & Enter New Gift
    Verify Gift Count                1
    # Added scrolls to fix menu from blocking 'Process Batch' button.
    cumulusci.robotframework.Salesforce.Scroll Element Into View         npsp:gift_entry.form_header:${batch_name}
    Click Gift Entry Button          Process Batch
    Wait Until BGE Batch Processes   ${batch_name}
    # Verify default values stored on payment and custom_account_text field doesn't have value on houshold account as its not relavent
    Current Page Should Be           Form                          Gift Entry
    Click Field Value Link           Donation Name
    Current Page Should Be           Details                       npe01__OppPayment__c
    ${pay_id} =                      Save Current Record ID For Deletion        npe01__OppPayment__c
    Verify Expected Values           nonns    npe01__OppPayment__c    ${pay_id}
    ...                              npe01__Payment_Amount__c=50.0
    ...                              npe01__Payment_Date__c=${date}
    ...                              npe01__Paid__c=True
    ...                              npe01__Check_Reference_Number__c=abc11233
    ...                              npe01__Payment_Method__c=Check
    Verify Expected Values           nonns    Account     ${contact}[AccountId]
    ...                              ${org_ns}custom_acc_text__c=None
