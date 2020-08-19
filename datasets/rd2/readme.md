# Using the RD SnowFakery Data Factories

Snowfakery Documentation: https://snowfakery.readthedocs.io/en/docs/

## YML Files:

### rd1_factory:
- This yml will create RD1 format records
- It is feasible to disable *all* NPSP Triggers before executing this to avoid row lock errors
- Running the standard RD1 batch job after the import completes will create all historical and future installment opportunities

### rd2_factory:
- This yml creates RD2 format records primarily
- A Household Contact or Organization Account is created for each RD
- Installment Periods, OpenEndedStatus types, and other values distributed across all possible options

##### Special Notes:
- Be sure that RD2 is enabled in the org first by using the `enable_rd2` flow
- Do *not* disable all NPSP Triggers before executing this
- Instead, configure RD2 settings as follows:
  - "Automatic Recurring Donation Naming": checked
  - "Installment Opportunity Async Behavior": "ASynchronous_When_Bulk"
  - "Disable CRLP When Creating Installments": checked
  - "Installment Opportunity Auto-Creation": "Disable_First_Installment" 
- Run the standard RD2 batch job after the import completes to allow the first installment opportunity to be created.
  
`cci task run generate_and_load_from_yaml -o generator_yaml datasets/rd2/rd2_factory.yml -o num_records 100 -o num_records_tablename npe03__Recurring_Donation__c --org {org_alias}`
 

### data_factory_with_rd2:
- This yml will create Contacts records with the following:
   - 95% of all created Contacts will have 1 Enhanced Recurring Donation
       - 95% of the RD's are for this Household Contact
       - 5% of the RD's are for an Organization Account (and the Household Contact)
       - DateEstablished/EffectiveDate is within the last 2 years
       - 5% of the RD's have an Allocation and/or a linked Campaign
       - 95% of RD's are Open, the other 5% are Fixed length
       - There is a random distribution of Installment Periods, DayOfMonth, etc.
       - All RD's will get exactly 1 historical ClosedWon Opportunity
   - Create 0 to 5 Opportunities for the Contact & Related Household Account
       - CloseDate between 3 years ago and 6 months in the future (ClosedWon if in the past)

##### Special Notes:
- Be sure that RD2 is enabled in the org first by using the `enable_rd2` flow
- Do *not* disable all NPSP Triggers before executing this
- Instead, configure RD2 settings as follows:
  - "Automatic Recurring Donation Naming": checked
  - "Installment Opportunity Async Behavior": "ASynchronous_When_Bulk"
  - "Disable CRLP When Creating Installments": checked
  - "Installment Opportunity Auto-Creation": "Disable_First_Installment" 
- Run the standard RD2 batch job after the import completes to allow the first installment opportunity to be created.
  
`cci task run generate_and_load_from_yaml -o generator_yaml datasets/rd2/data_factory_with_rd2.yml -o num_records 100 -o num_records_tablename Contact --org {org_alias}`

##### To generate 100 Contacts (the default) with sample RD2 and Opp data:
`cci flow run test_data_rd2 --org {orgname}`

##### To generate 500 Contacts with sample RD2 and Opp data:
`cci flow run test_data_rd2 --org {orgname} -o generate_and_load_from_yaml__num_records 500`
