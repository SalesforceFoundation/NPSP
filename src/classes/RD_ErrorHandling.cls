/*
    Copyright (c) 2012, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2012 (2.0)
* @description Handles errors in the recurring donation processes  
*/
public without sharing class RD_ErrorHandling {
    
    public static npe03__Recurring_Donations_Settings__c rds;
    
    public static void handleDMLErrorsOnOppInsert(list<Database.SaveResult> lsr, list<Opportunity> badOpps){ 
        list<Error__c> rdeqList = new list<Error__c>();
        //we only want one error per id, so we filter with this set
        set<id> RDIDs = new set<id>(); 
        integer i = 0;            
        for (Opportunity o : badOpps){
                  
            if (!RDIDs.contains(o.npe03__Recurring_Donation__c)){
                Database.SaveResult thisSR = lsr[i];
                //insert into our custom list setting?                  
                Error__c rdeq = new Error__c();
                rdeq.Record_URL__c = URL.getSalesforceBaseUrl().toExternalForm() + '/' + o.npe03__Recurring_Donation__c;
                rdeq.Full_Message__c = thisSR.getErrors()[0].getMessage();
                rdeqList.add(rdeq);
                RDIDs.add(o.npe03__Recurring_Donation__c);
            }            
            i++;
        }
         
        if (!rdeqList.isEmpty()){
            insert rdeqList;
            //if we're in a batch job, let the batch handle the send notification so it happens
            //at one time
            if (!system.isBatch() && !RD_ProcessControl.batchButton && !system.isFuture())  
                sendErrorQueueEmailNotificationFuture();
            else if (system.isFuture()){
                sendErrorQueueEmailNotification();
            }                 
        }                  
    }
    
    @future
    public static void sendErrorQueueEmailNotificationFuture(){sendErrorQueueEmailNotification();}
    public static void sendErrorQueueEmailNotification(){
        map<Id, Error__c> rdeqMap = new Map<Id, Error__c>([select Id, Record_URL__c, Full_Message__c from Error__c]);
        rds = RD_RecurringDonations.getRecurringDonationsSettings();
        if (!rdeqMap.isEmpty() && rds.npe03__Error_Email_Notifications__c != 'None' && rds.npe03__Error_Email_Notifications__c != null){
            Messaging.SingleEmailMessage sme = createEmailMessage(rdeqMap.values());
            if (!test.isRunningTest())
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{sme});
        }
        //clear the queue if not in a batch, otherwise, save them 
        if (!system.isBatch() && !RD_ProcessControl.batchButton)           
           delete [select id from Error__c];
    } 

    private static Messaging.SingleEmailMessage createEmailMessage(list<Error__c> rdeqList){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setUseSignature(false);
        mail.setSenderDisplayName('Salesforce Recurring Donations');
        mail.setSubject('Salesforce Recurring Donations Errors');
        string bodyString = '';
        bodyString += system.label.npe03.RecurringDonationErrorEmailBody;
        bodyString += '\n\nErrors:';
        for (Error__c rdeq : rdeqlist){
            bodyString += '\n' + rdeq.Record_URL__c;
            bodystring += ' Error Message: ' + rdeq.Full_Message__c;           
        }        
        mail.setPlainTextBody(bodyString);
        list<string> sendList = new list<string>();
        //user, sysadmins or PG
        string mailList = rds.npe03__Error_Email_Notifications__c;
        
        if (mailList.startsWith('005')){
            sendList.add([select email from User where id = :mailList].email);
        }
        else if(mailList == 'All Sys Admins'){
            list<User> sysadminlist = [select email from User where User.Profile.Name = 'System Administrator'];
            for (User u : sysadminlist){
                sendList.add(u.email);              
            }           
        }
        else if(mailList.startsWith('00G')){
            list<GroupMember> groupUsers = [select g.UserOrGroupId from GroupMember g where GroupId = :mailList];
            set<id> userIDs = new set<id>();
            for (GroupMember g : groupUsers)
               userIDs.add(g.UserOrGroupId);
            list<User> userList = [select email from User where id IN :userIDs];
            for (User u : userList){
                sendList.add(u.email);
            }
        }        
        mail.setToAddresses(sendList);                   

        return mail;        
    }
    

}