public class HH_Canvas_CTRL {
    
    @AuraEnabled
    public static Account getHH(ID hhId) {
        if (hhId == null)
            return null;
        return [select Id, Name from Account where Id = :hhId];
    }	
    
    @AuraEnabled
    public static list<Contact> getContacts(ID hhId) {
        if (hhId == null)
            return null;
        return [select Id, Firstname, Lastname from Contact where AccountId = :hhId];        
    }
}