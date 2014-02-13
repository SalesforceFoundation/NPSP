public with sharing class ERR_Notifier {

    public static NotificationOptions notificationOptions = new NotificationOptions();
    
    public class NotificationOptions {
    	public final String sysAdmins = 'All Sys Admins';
    	public final String user = '005';  //specific user (should be a system admin)
    	public final String chatterGroup = '0F9'; //chatter group
    }
    
    public static void sendErrorNotifications(ERR_Handler.Context context) {
    	String errorNotifRecipient = Error_Settings__c.getOrgDefaults().Error_Notifications_To__c;
            
        if (Error_Settings__c.getOrgDefaults().Error_Notifications_On__c == true && errorNotifRecipient != null) {
        	//We will post to chatter, if enabled
        	if(errorNotifRecipient instanceof id && errorNotifRecipient.startsWith(NotificationOptions.chatterGroup) 
        	&& Schema.SObjectType.User.isFeedEnabled()) {
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
    
    private static void sendEmailNotifications(ERR_Handler.Context context, List<String> sendList) {
        if (!system.isBatch() && !system.isFuture() && Limits.getFutureCalls() < Limits.getLimitFutureCalls()) {
            sendErrorQueueEmailNotificationFuture(sendList);
        } else if (system.isFuture()) {
            sendErrorQueueEmailNotification(sendList);
        }
    }
    
    @future
    private static void sendErrorQueueEmailNotificationFuture(List<String> sendList) { 
    	sendErrorQueueEmailNotification(sendList); 
    }
    
    private static void sendErrorQueueEmailNotification(List<String> sendList) {
        List<Error__c> errors = [select Id, Error_Type__c, Datetime__c, Full_Message__c, Record_URL__c, Context_Type__c,
                                        Stack_Trace__c from Error__c where Email_Sent__c = false];
        
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
        Integer i = 1;
        for (Error__c rdeq : rdeqlist){
            bodystring += '\n\n----------\n Error #' + i + ': \n' + getErrorMessageBody(rdeq);
            i++;           
        }        
        mail.setPlainTextBody(bodyString);      
        mail.setToAddresses(sendList);         
        return mail;        
    }
    
    public static void postErrorsToChatter(String chatterGroupId) {
    	
    	if(chatterGroupId instanceof Id) {
	    	SObject collaborationGroup = Database.query('select Id, Name from CollaborationGroup where id = :chatterGroupId');
	        List<Error__c> errors = [select Id, Error_Type__c, Datetime__c, Full_Message__c, Record_URL__c, Context_Type__c,
	                                    Stack_Trace__c from Error__c where Posted_in_Chatter__c = false];    
	        
	        if (!errors.isEmpty()) {
	        	List<SObject> postsToInsert = new List<SObject>();
	        	for(Error__c error : errors) {
	        		SObject post = (SObject)System.Type.forName('FeedItem').newInstance();
	        		post.put('Title', 'NPSP Error');
	        		String body = getErrorMessageBody(error);
	        		post.put('Body', body);
	        		post.put('ParentId', collaborationGroup.Id);
	        		postsToInsert.add(post);
	        		error.Posted_in_Chatter__c = true;
	        	}
	        	insert postsToInsert;
	        	update errors; //we don't want to post the same errors again	
	        }  
    	}
    }
    
    private static String getErrorMessageBody(Error__c error) {
    	String body = '\nError Type: ' + error.Error_Type__c;
	    body += '\nError Date: ' + error.Datetime__c;
	    body += '\nMessage: "' + error.Full_Message__c + '"';
	    if(error.Record_URL__c != null)
	        body += '\n' + error.Record_URL__c;
	    if(error.Context_Type__c != null)
	        body += '\nContext: ' + error.Context_Type__c;
	    body += '\n\nStack Trace:\n ' + error.Stack_Trace__c;
	    return body;
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