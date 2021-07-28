# Using the LDV SnowFakery Data Factory

- Snowfakery Documentation: https://snowfakery.readthedocs.io/en/docs/
- NPSP LDV Org Data Loading Documentation: https://salesforce.quip.com/aoqmAzdgQYJL
 
## YML Files:

##### Special Notes:
- Do *not* disable all NPSP Triggers before executing. 
- Follow the directions in the Quip Doc above to pre-configure the LDV org for data loading
  
### donations_recipe.yml:
- This yml will create Contacts records with the following:
   - 100% of all created Contacts will have between 1 and 7 Opportunity record
     - CloseDate between 3 years ago and 45 days in the future (ClosedWon if in the past)
   - An additional 100 Multi-Person Households is created
     - Each household will have 2 Contacts
     - Each household will have between 2 and 6 Opportunities, the majority of which will be Closed/Won 
- Note: Allocation records are always inserted using the Bulk Serial api as defined in the related load.yml file.

##### To generate 500000 Contacts with Opp data:
`cci flow run ldv_test_data -o generate_and_load_from_yaml__num_records 500000 --org {orgname}`
