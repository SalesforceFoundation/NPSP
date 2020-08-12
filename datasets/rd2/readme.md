# Using the RD SnowFakery Data Factories

Snowfakery Documentation: https://snowfakery.readthedocs.io/en/docs/#function-blocks

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
   - Create 0 or 1 Enhanced Recurring Donation
       - 95% of them are for this Household Contact
       - 5% of them have this Contact and an Organization Account
       - DateEstablished/EffectiveDate is within the last 2 years
       - 5% of them have an Allocation and/or a linked Campaign
       - 95% of RD's are Open, the other 5% is Fixed length
       - There is a random distribution of Installment Periods, DayOfMonth, etc.
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