public with sharing class HH_ManageHH_CTRL {

    @AuraEnabled
    public Account accHH { get; set; }

    @AuraEnabled
    public list<Contact> listCon { get; set; }
    
    public HH_ManageHH_CTRL(ApexPages.StandardController controller) {
        accHH = (Account)controller.getRecord();
        accHH = [select Id, Name from Account where Id = :accHH.Id];
        listCon = [select Id, Firstname, Lastname from Contact where AccountId = :accHH.Id];
        
    }
    
}