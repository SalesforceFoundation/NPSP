public with sharing class ALLO_Multicurrency_TDTM {
	public ALLO_Multicurrency_TDTM() {
		
	}
    
    /*** Multicurrency ***/
    //set when multicurrency check is called, holds the field string/sobject mapping
    public static Map<String, SObjectField> mcFieldValues = new Map<String, SObjectField>();
    public static boolean multiCurrency;
    //exchangerate store
    static map<string, decimal> exchangeRates = new map<string,decimal>();
    //corporate currency
    static string currCorporate; 

    //returns a boolean if we are in a multi-currency org or not.
    //on first execution sets up static variables etc
    public static boolean isMultiCurrency(){                    
        if (multiCurrency==null){
            //create currency field handles for later dynamic dml
            mcFieldValues.put('Opportunity', Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode'));
            mcFieldValues.put('Allocation__c', Schema.sObjectType.Account.fields.getMap().get('CurrencyIsoCode'));
            mcFieldValues.put('General_Accounting_Unit__c', Schema.sObjectType.Contact.fields.getMap().get('CurrencyIsoCode'));

            String queryExchangeRates = 'select IsoCode,ConversionRate,IsCorporate from CurrencyType';
            SObjectType soCurrencyType = Schema.getGlobalDescribe().get('CurrencyType'); 

            //are we in a multi-currency org?
            if (mcFieldValues.get('Opportunity') != null && mcFieldValues.get('Allocation__c') != null && 
                mcFieldValues.get('General_Accounting_Unit__c') != null && soCurrencyType != null){
                multiCurrency = true;
 
                map<string,SObjectField> ctFields = soCurrencyType.getDescribe().fields.getMap();
                SObjectField ctIsoCode = ctFields.get('IsoCode');
                SObjectField ctConversionRate = ctFields.get('ConversionRate');
                SObjectField ctCorporate = ctFields.get('IsCorporate');

                //iterate over all the currencies in the org (inc. inactive ones as they may have been used previously)
                //this allows us to put them in a map and use the ISO code as key and also set the corporate
                for(sObject ct: Database.query(queryExchangeRates)){
                    exchangeRates.put((string)ct.get(ctIsoCode),(decimal)ct.get(ctConversionRate));
                    if((boolean)ct.get(ctCorporate))currCorporate=(string)ct.get(ctIsoCode);
                }
            }
            else
                multiCurrency = false; 
        }        
        return multiCurrency;
    }

    //do a conversion from amount in corporate currency to the currency specified by the ISO code
    public static decimal convertFromCorporate(String ISO,Decimal amt){
        if(currCorporate == ISO || currCorporate == null) // no need to convert
            return amt;
        else //return value to 2DP
            return (amt * exchangeRates.get(ISO)).setScale(2) ;
    }

    public static decimal convertCurrency(String fromISO, String toISO, Decimal amt){
        if(fromISO == toISO) // no need to convert
            return amt;
        else //return value to 2DP
            return ((amt / exchangeRates.get(fromISO)) * exchangeRates.get(toISO)).setScale(2) ;
    }

}