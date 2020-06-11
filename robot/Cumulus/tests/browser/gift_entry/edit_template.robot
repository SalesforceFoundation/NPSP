*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

*** Variables ***
&{method}         Default Value=Check
&{check}          Default Value=abc11233
&{date}           Default Value=Today
&{custom}         Required=checked
${amount}         50
${msg}            Automation test

*** Keywords ***
Setup Test Data
    &{contact} =     API Create Contact                 FirstName=${faker.first_name()}    LastName=${faker.last_name()}
    Set suite variable    &{contact}
    &{account} =     API Create Organization Account    Name=${faker.company()}
    Set suite variable    &{account}


*** Test Cases ***

Edit GE Template And Verify Changes
    [Documentation]                           This test case makes edits to Default gift entry template and verifies that edits are saved 
    ...                                       and available when a Single gift or batch gift are created. 
 
    [tags]                                    unstable  feature:GE          W-039559   
                       
    Go To Page                                Landing                       GE_Gift_Entry
    Click Link                                Templates
    Select Template Action                    Default Gift Entry Template   Edit
    Current Page Should Be                    Template                      GE_Gift_Entry
    Click Gift Entry Button                   Next: Form Fields
    Select Object Group Field                 Account 1                     custom_acc_text 
    Select Object Group Field                 Opportunity                   Donation Imported
    Fill Template Form                      
    ...                                       Account 1: custom_acc_text=&{custom}
    ...                                       Opportunity: Close Date=&{date}
    ...                                       Payment: Check/Reference Number=&{check}
    ...                                       Payment: Payment Method=&{method} 
    Click Gift Entry Button                   Save & Close
    Current Page Should Be                    Landing                       GE_Gift_Entry
    Click Gift Entry Button                   New Single Gift
    Current Page Should Be                    Form                          Gift Entry
    ${ui_date} =                              Get Current Date              result_format=%b %-d, %Y
    Verify Field Default Value
    ...                                       Donation Date=${ui_date}
    ...                                       Check/Reference Number=abc11233
    ...                                       Payment Method=Check
    Fill Gift Entry Form
    ...                                       Donor Type=Account1
    ...                                       Existing Donor Organization Account=&{account}[Name]
    ...                                       Donation Amount=${amount}
    Click Button                              Save
    Verify Error For Field
    ...                                       Account 1: custom_acc_text=Complete this field.
    Fill Gift Entry Form
    ...                                       Account 1: custom_acc_text=${msg}  
    Click Button                              Save
    Current Page Should Be                    Details                       Opportunity


    