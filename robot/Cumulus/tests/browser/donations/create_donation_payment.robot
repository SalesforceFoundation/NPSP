*** Settings ***

Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/ContactPageObject.py
...             robot/Cumulus/resources/AccountPageObject.py
...             robot/Cumulus/resources/OpportunityPageObject.py
...             robot/Cumulus/resources/NPSP.py
Suite Setup     Run keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Capture Screenshot and Delete Records and Close Browser

***Keywords***
# Sets up all the required data for the test based on the keyword requests
Setup Test Data
    Setupdata   contact   ${contact1_fields}

*** Variables ***
&{contact1_fields}       Email=test@example.com
${opp_name}  Automationtest $100 donation
${Amount}  100
${Stage_Type}  Closed Won

*** Test Cases ***

Create Donation and Opportunity and Create Payment Manually
    [Documentation]  Navigate to Opportunities page and open an Opportunity>In the right sections, go to Payments click on drop down Arrow>New
    ...              Create a new payment for the Opportunity.

    [tags]                                  W-038461                 feature:Donations

    Go To Page                              Listing
    ...                                     Opportunity

    Click Object Button                     New
    Select Record Type                      Donation
    Wait For Modal                          New                       Opportunity: Donation
    # Create a new Opportunity from the UI


    Populate Field                          Opportunity Name    ${opp_name}
    Populate Lookup Field                   Account Name        ${data}[contact][LastName] Household
    Populate Field                          Amount   ${Amount}
    Select Value From Dropdown              Stage    ${Stage_Type}
    Select Date From Datepicker             Close Date          Today
    Set Checkbutton To                      Do Not Automatically Create Payment     checked
    Click Modal Button                      Save
    Wait Until Modal Is Closed
    Current Page Should Be                  Details                                 Opportunity
    Save Current Record ID For Deletion     Opportunity
    Validate Related Record Count           Payments                                0

    #Make A New Payment

    Click Related List Button               Payments                                New
    Wait For Modal                          New                                     Payment
    Select Window
    Populate Modal Form                     Payment Method=Credit Card
    ...                                     Payment Amount=100
    Select Date From Datepicker             Payment Date          Today

    Click Modal Footer Button               Save

    Scroll Page To Location                 0    0
    Validate Related Record Count           Payments                                1

    Go To Page                              Details
    ...                                     Contact
    ...                                     object_id=${data}[contact][Id]
    Wait Until Loading Is Complete
    Current Page Should Be                  Details          Contact
    #Perform Validations
    ${opp_date} =     Get Current Date      result_format=%-m/%-d/%Y

    Navigate To And Validate Field Value    Last Gift Date           contains       ${opp_date}          Donation Totals
    Navigate To And Validate Field Value    Total Gifts              contains       $100.00              Soft Credit Total
    Navigate To And Validate Field Value    Total Number of Gifts    contains       1                    Soft Credit Total
