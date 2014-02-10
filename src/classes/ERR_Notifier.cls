public with sharing class ERR_Notifier {

    public static NotificationOptions notificationOptions = new NotificationOptions();
    
    public class NotificationOptions {
    	public final String sysAdmins = 'All Sys Admins';
    	public final String user = '005';  //specific user (should be a system admin)
    	public final String chatterGroup = '0F9'; //chatter group
    }
    
    public static void sendErrorNotifications(ERR_Handler.Context context) {
    	String errorNotifRecipient = Error_Settings__c.getOrgDefaults().Error_Notifications_To__c;
            
        if (errorNotifRecipient != null) {
        	//We will post to chatter
        	if(errorNotifRecipient instanceof id && errorNotifRecipient.startsWith(NotificationOptions.chatterGroup)) {
        		postErrorsToChatter(errorNotifRecipient);
        	//We will send email
        	} else {
        		List<String> sendList = new List<String>();
                if (errorNotifRecipient instanceof id && errorNotifRecipient.startsWith(NotificationOptions.user)) {
                    sendList.add([select email from User where id = :errorNotifRecipient].email);
                } else if(errorNotifRecipient == NotificationOptions.sysAdmins) {
                    list<User> sysadminlist = [select email from User where User.Profile.Name = 'System Administrator'];
		            for (User u : sysadminlist) {
		                sendList.add(u.email);              
		            }
                }
                sendEmailNotifications(context, sendList);
        	}
        }
    }
    
    public static void sendEmailNotifications(ERR_Handler.Context context, List<String> sendList) {
        if(context != null && context == ERR_Handler.Context.RD) {
            if (!system.isBatch() && !system.isFuture()) {
                sendErrorQueueEmailNotificationFuture(sendList);
            } else if (system.isFuture()){
                sendErrorQueueEmailNotification(sendList);
            }  
        }   
    }
    
    @future
    public static void sendErrorQueueEmailNotificationFuture(List<String> sendList) { 
    	sendErrorQueueEmailNotification(sendList); 
    }
    
    public static void sendErrorQueueEmailNotification(List<String> sendList) {
        List<Error__c> errors = [select Id, Record_URL__c, Full_Message__c from Error__c where Email_Sent__c = false];
        
        if (!errors.isEmpty()) {
            Messaging.SingleEmailMessage sme = createEmailMessage(errors, sendList);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{sme});
            for(Error__c error : errors)
                error.Email_Sent__c = true;
        }
        update errors;
    } 

    private static Messaging.SingleEmailMessage createEmailMessage(List<Error__c> rdeqList, List<String> sendList) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setUseSignature(false);
        mail.setSenderDisplayName('Salesforce NPSP');
        mail.setSubject('Salesforce Errors');
        string bodyString = '';
        bodyString += system.label.npe03.RecurringDonationErrorEmailBody;
        bodyString += '\n\nErrors:';
        for (Error__c rdeq : rdeqlist){
            bodyString += '\n' + rdeq.Record_URL__c;
            bodystring += ' Error Message: ' + rdeq.Full_Message__c;           
        }        
        mail.setPlainTextBody(bodyString);      
        mail.setToAddresses(sendList);         
        return mail;        
    }
    
    public static void postErrorsToChatter(String chatterGroupId) {
    	
    	if(chatterGroupId instanceof Id) {
	    	CollaborationGroup collaborationGroup = [select Id, Name from CollaborationGroup where id = :chatterGroupId];
	        List<Error__c> errors = [select Id, Error_Type__c, Datetime__c, Full_Message__c, Record_URL__c from Error__c 
	                                   where Posted_in_Chatter__c = false];    
	        
	        if (!errors.isEmpty()) {
	        	List<FeedItem> postsToInsert = new List<FeedItem>();
	        	for(Error__c error : errors) {
	        		FeedItem post = new FeedItem();
	        		post.Title = 'NPSP Error';
	        		String body = '\nError Type: ' + error.Error_Type__c;
	        		body += '\nError Date: ' + error.Datetime__c;
	        		body += '\n' + error.Full_Message__c;
	        		body += '\n' + error.Record_URL__c;
	        		post.Body = body;
	        		post.ParentId = collaborationGroup.Id;
	        		postsToInsert.add(post);
	        		error.Posted_in_Chatter__c = true;
	        	}
	        	insert postsToInsert;
	        	update errors; //we don't want to post the same errors again	
	        }  
    	}
    }
    
    public static Error_Settings__c getOrgSettings() {
        Error_Settings__c orgErrorSettings = Error_Settings__c.getOrgDefaults();
        
        if(orgErrorSettings.Id == null) {
	        orgErrorSettings.Store_Errors_On__c = true;
	        orgErrorSettings.Error_Notifications_On__c = true;
	        orgErrorSettings.Error_Notifications_To__c = NotificationOptions.sysAdmins;
	        
	        insert orgErrorSettings;
        }
        return orgErrorSettings;
    }

}