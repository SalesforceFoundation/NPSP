public with sharing class STG_PanelRDBatch_CTRL extends STG_Panel { 

    public STG_PanelRDBatch_CTRL() {
    	isRunningBatch = false;
    }
    
    public override string idPanel() { return 'idPanelRDBatch'; }
    
    public boolean isRunningBatch { get; set; }
    
    public PageReference runBatch() {

        isRunningBatch = true;
        string openLabel = system.label.npe03.RecurringDonationOpenStatus;
        string queryRCD = 'select id,npe03__Open_Ended_Status__c, npe03__Next_Payment_Date__c, npe03__Organization__c, ' + 
            'npe03__Contact__c,npe03__Installment_Amount__c,npe03__Installments__c,npe03__Amount__c,npe03__Total__c,npe03__Installment_Period__c, ' +
            'npe03__Date_Established__c,npe03__Donor_Name__c,npe03__Schedule_Type__c,npe03__Recurring_Donation_Campaign__c,npe03__Total_Paid_Installments__c, OwnerId ';

        //add any custom mapping to make sure we have the required fields        
        map<string, npe03__Custom_Field_Mapping__c> cfmMap = STG_SettingsService.stgService.mapRDCustomField;
        for (string s : cfmMap.keySet()) {
            queryRCD = queryRCD + ',' + cfmMap.get(s).npe03__Recurring_Donation_Field__c;
        }
        
        //if currencyiso field exists add it to query for use later
        if (Schema.sObjectType.npe03__Recurring_Donation__c.fields.getMap().get('CurrencyIsoCode') != null)
            queryRCD = queryRCD + ',CurrencyIsoCode';
        queryRCD = queryRCD + ' from npe03__Recurring_Donation__c where npe03__Open_Ended_Status__c = \'' + openLabel + '\'';
        
        if (Test.isRunningTest())
            queryRCD = queryRCD + ' LIMIT 50';
        
        //call the batch job, processing 50 at a time 
        Id batchInstanceId = Database.executeBatch(new RD_RecurringDonations_BATCH(queryRCD), 50); 
    	return null;
    }
 
}