public with sharing class ADDR_Validator_TDTM extends TDTM_Runnable {
	
	public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
    TDTM_TriggerActionHelper.Action triggerAction, Schema.DescribeSObjectResult objResult) { 
        
        DmlWrapper wrapper = new DmlWrapper();
        
        Address_Verification_Settings__c settings = Address_Verification_Settings__c.getInstance();
        if (settings.enable_automatic_verification__c) {
            /*
            if(trigger.isBefore && trigger.isUpdate)
                processBeforeUpdate(newlist, Trigger.oldMap);
            
            if(trigger.isAfter)
                processAfter(newlist, Trigger.oldMap); */
        }
        return wrapper;
    }
/*    
    public static void processBeforeUpdate(list<Address__c> newlist, map<id, Address__c> oldMap) {

        for (Address__c a : newlist) {
            if (!LiveAddressVerification.nowUpdating.contains(a.id)) {

                // if we cleared out the address or changed to non-US, clear mapped fields as well
                Address__c old = oldMap.get(a.id);
                if (changedBA(a, old) && (a.BillingStreet == null || !billingIsUS(a)))
                    LiveAddressVerification.clearMappedFields( a, 'Address__c', 'Billing' );
                if (changedSA(a, old) && (a.ShippingStreet == null || !shippingIsUS(a)))
                    LiveAddressVerification.clearMappedFields( a, 'Address__c', 'Shipping' );
            }
        }
    }

    public static void processAfter(list<Address__c> newList, map<Id, Address__c> oldMap) {

        // collect all the addresses for verification
        list<Address__c> addresses = new list<Address__c>();

        for (Address__c a : newList) {
            if (!LiveAddressVerification.nowUpdating.contains(a.id)) {

                // has any address field changed?
                Address__c old = (oldMap == null) ? (new Address__c()) : oldMap.get(a.id);

                if (shippingIsUS(a) && changedSA(a, old) && !shippingIsBlank(a)) {
                    Address__c av = new Address__c(
                        Address__c = a.id,
                        address_field_type__c = 'Shipping',
                        original_street__c = a.ShippingStreet,
                        original_city__c = a.ShippingCity,
                        original_state__c = a.ShippingState,
                        original_postal_code__c = a.ShippingPostalCode,
                        original_country__c = a.ShippingCountry
                    );
                    addresses.add(av);
                }
                if (billingIsUS(a) && changedBA(a, old) && !billingIsBlank(a)) {
                    Address__c av = new Address__c(
                        Address__c__c = a.id,
                        address_field_type__c = 'Billing',
                        original_street__c = a.BillingStreet,
                        original_city__c = a.BillingCity,
                        original_state__c = a.BillingState,
                        original_postal_code__c = a.BillingPostalCode,
                        original_country__c = a.BillingCountry
                    );
                    addresses.add(av);
                }               
            }   
        }
        insertAndVerifyList( addresses );
    }

    static void insertAndVerifyList(list<Address__c> addresses) {
        if (!addresses.isEmpty()) {
            insert addresses;
            map<Id, Address__c> avMap = new map<Id, Address__c>(addresses);

            // call the webservice future method to verify addresses
            LiveAddressVerification.verifyRecords( avMap.keyset() );
        }
    }

    static Boolean changedBA(Address__c a, Address__c old) {
        return (a.BillingStreet != old.BillingStreet || 
            a.BillingCity != old.BillingCity || a.BillingState != old.BillingState ||
            a.BillingPostalCode != old.BillingPostalCode || a.BillingCountry != old.BillingCountry);
    }
    
    static Boolean changedSA(Address__c a, Address__c old) {
        return (a.ShippingStreet != old.ShippingStreet || 
            a.ShippingCity != old.ShippingCity || a.ShippingState != old.ShippingState ||
            a.ShippingPostalCode != old.ShippingPostalCode || a.ShippingCountry != old.ShippingCountry);
    }

    static Boolean billingIsUS(Address__c a) {
        return (a.BillingCountry == null || a.BillingCountry == 'US' || a.BillingCountry == 'USA' || 
                        a.BillingCountry == 'United States' || a.BillingCountry == 'United States of America');
    }

    static Boolean shippingIsUS(Address__c a) {
        return (a.ShippingCountry == null || a.ShippingCountry == 'US' || a.ShippingCountry == 'USA' || 
                        a.ShippingCountry == 'United States' || a.ShippingCountry == 'United States of America');
    }

    static Boolean billingIsBlank(Address__c a) {
        return (a.BillingStreet == null && (a.BillingCity == null || a.BillingState == null) && a.BillingPostalCode == null);
    }

    static Boolean shippingIsBlank(Address__c a) {
        return (a.ShippingStreet == null && (a.ShippingCity == null || a.ShippingState == null) && a.ShippingPostalCode == null);
    } */

}