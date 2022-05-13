public with sharing class RD2_EntryFormPermissions {

    public class ForSaveRecurringDonation implements IDefinePermissions {

        private List<Schema.SObjectField> customFieldReferences;
        private Map<String, ObjectAccessDefinition> accessDefinitionByObjectType;


        public ForSaveRecurringDonation(List<Schema.SObjectField> customFieldReferences) {
            this.customFieldReferences = customFieldReferences;
            this.accessDefinitionByObjectType = this.buildAccessDefinitions();
        }

        private Map<String, ObjectAccessDefinition> buildAccessDefinitions() {
            Map<String, ObjectAccessDefinition> accessDefinitionsMap = new Map<String, ObjectAccessDefinition>();
            ObjectAccessDefinition rdAccess = new ObjectAccessDefinition(npe03__Recurring_Donation__c.SObjectType, DataAccessLevel.MODIFY);
            rdAccess.addFields(this.getRdFieldDefinitions());
            accessDefinitionsMap.put(String.valueOf(npe03__Recurring_Donation__c.SObjectType), rdAccess);
            return accessDefinitionsMap;
        }

        public ObjectAccessDefinition getAccessDefinitionsByObjectName(String sObjectName) {
            return accessDefinitionByObjectType.get(sObjectName);
        }

        public List<ObjectAccessDefinition> getAccessDefinitions() {
            return accessDefinitionByObjectType.values();
        }

        private List<FieldAccessDefinition> getRdFieldDefinitions() {
            List<FieldAccessDefinition> fieldAccessDefinitions = new List<FieldAccessDefinition>{
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.Status__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.ClosedReason__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.npe03__Contact__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.npe03__Organization__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.npe03__Date_Established__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.npe03__Amount__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.npe03__Installment_Period__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.InstallmentFrequency__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.StartDate__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.Day_of_Month__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.npe03__Installments__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.RecurringType__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.CommitmentId__c),
                    new FieldAccessDefinition(npe03__Recurring_Donation__c.PaymentMethod__c)
            };
            for (Schema.SObjectField fieldRef : this.customFieldReferences) {
                fieldAccessDefinitions.add(new FieldAccessDefinition(fieldRef));
            }
            return fieldAccessDefinitions;
        }
    }

    public class ForGetInitialView implements IDefinePermissions {

        public List<ObjectAccessDefinition> getAccessDefinitions() {
            return null;
        }

        public ObjectAccessDefinition getAccessDefinitionsByObjectName(String objectName) {
            return null;
        }
    }
}