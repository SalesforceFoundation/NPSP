/*
* inserts two basic templates for testing
*/
public static void insertTemplates() {
    List<Batch_Template__c> templates = new List<Batch_Template__c>();
    templates.add(new Batch_Template__c(Name='Account Gift Entry'));
    templates.add(new Batch_Template__c(Name='Contact Gift Entry'));
    insert templates;
    
    List<String> contactFieldNames = new List<String>{'Id','Contact1_Salutation__c','Contact1_Firstname__c','Contact1_Lastname__c','Contact1_Title__c','Contact1_Personal_Email__c','Contact1_Work_Email__c','Contact1_Preferred_Email__c','Contact1_Home_Phone__c','Contact1_Mobile_Phone__c','Contact1_Work_Phone__c','Contact1_Other_Phone__c','Contact1_Preferred_Phone__c','Contact1_Birthdate__c','Home_Street__c','Home_City__c','Home_State_Province__c','Home_Zip_Postal_Code__c','Home_Country__c','Donation_Campaign_Name__c','Donation_Record_Type_Name__c','Donation_Stage__c','Donation_Name__c','Donation_Amount__c','Donation_Date__c','Donation_Description__c','Donation_Type__c','Payment_Check_Reference_Number__c','Payment_Method__c'};
    List<String> accountFieldNames = new List<String>{ 'Id', 'Donation_Campaign_Name__c', 'Account1_City__c', 'Account1_Country__c', 'Account1_Name__c', 'Account1_Phone__c', 'Account1_State_Province__c', 'Account1_Street__c', 'Account1_Website__c', 'Account1_Zip_Postal_Code__c', 'Donation_Record_Type_Name__c', 'Donation_Stage__c', 'Donation_Name__c', 'Donation_Amount__c', 'Donation_Date__c', 'Donation_Description__c', 'Donation_Type__c', 'Payment_Check_Reference_Number__c', 'Payment_Method__c'};
    List<Batch_Template_Field__c> templateFields = new List<Batch_Template_Field__c>();
    
    for (Integer i=0; i<accountFieldNames.size(); i++) {
        templateFields.add(new Batch_Template_Field__c(Name=accountFieldNames[i], Order__c=i+1, Batch_Template__c=templates[0].Id));
    }
    
    for (Integer i=0; i<contactFieldNames.size(); i++) {
        templateFields.add(new Batch_Template_Field__c(Name=contactFieldNames[i], Order__c=i+1, Batch_Template__c=templates[1].Id));
    }

    insert templateFields;
}