/*
    Copyright (c) 2014, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2014
* @description Notifies specific users or groups by email or Chatter when error occur.
* @group ErrorHandling
* @group-content ../../ApexDocContent/ErrorHandling.htm
*/
public class ERR_Notifier {

    /** @description Filtering options to reduce the number of records processed during the notify job */
    @TestVisible
    private static Integer MAX_RECORDS = 5000;
    @TestVisible
    private static Datetime MAX_AGE_FOR_ERRORS = System.now().addHours(-48);

    /** @description Global error notification settings used in NPSP Settings and here */
    public static final String ERROR_NOTIFICATION_USER_PREFIX = USER_UserService.OBJECT_ID_PREFIX_USER;
    public static final String ERROR_NOTIFICATION_CHATTER_PREFIX = CollaborationGroup.SObjectType.getDescribe().getKeyPrefix();
    public static final String ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS = 'All Sys Admins';

    /** @description Global email constants used for all outbound (system) emails */
    public static final String EMAIL_SYSTEM_ERRORS_TO = 'errors@salesforce.org';
    public static final String EMAIL_REPLY_TO = 'donotreply@salesforce.org';
    public static final String EMAIL_SENDER_NAME = 'Nonprofit Success Pack';

    /** @description the subject for errors sent out of this service only */
    private static final String EMAIL_SUBJECT = 'Salesforce Error';

    /**********************************************************************************************
    * @description Sends error notifications to the receivers specified in the settings, if error
    * notifications are enabled, with all the existing error records that have not been included in
    * previous error notifications.
    * @param context The context that triggered the error notification.
    * @return void
    */
    public static void sendErrorNotifications(String context) {

        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        String errorNotifRecipient = errorSettings.Error_Notifications_To__c;

        if (errorSettings.Error_Notifications_On__c == true && errorNotifRecipient != null) {

            ERR_Notifier notifierService = new ERR_Notifier();

            Boolean isChatterGroup = errorNotifRecipient instanceof Id
                    && errorNotifRecipient.startsWith(ERROR_NOTIFICATION_CHATTER_PREFIX);

            if (isChatterGroup && Schema.SObjectType.User.isFeedEnabled()) {

                notifierService.postErrorsToChatter(errorNotifRecipient);

            } else {

                notifierService.sendEmailNotifications(context,
                        notifierService.getErrorEmailRecipients(errorNotifRecipient));
            }
        }
    }

    /** @description Private constructor so the class cannot be instantiated outside of this class */
    @TestVisible
    private ERR_Notifier() {}

    // ====================== HELPER METHODS FOR ERROR NOTIFICATION SERVICE =========================

    /**********************************************************************************************
     * @description Using the provided error notification user id (or 'All System Admins') or gets
     * all system admin email addresses
     * @param errorNotifRecipient Id or Null
     * @return List<Email>
     */
    private List<String> getErrorEmailRecipients(String errorNotifRecipient) {
        List<String> recipientsList = new List<String>();
        Boolean isUserId = errorNotifRecipient instanceof Id
                && errorNotifRecipient.startsWith(ERROR_NOTIFICATION_USER_PREFIX);

        if (isUserId) {
            List<User> users = [SELECT Email FROM User WHERE Id = :errorNotifRecipient AND IsActive = TRUE LIMIT 1];
            if (!users.isEmpty()) {
                recipientsList.add(users[0].Email);
            }

        } else if (errorNotifRecipient == ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS) {
            recipientsList.addAll(getSystemAdminEmails());
        }

        return recipientsList;
    }

    /**********************************************************************************************
    * @description Get the active System Administrators' emails.
    * @return List<String> Emails
    */
    @TestVisible
    private List<String> getSystemAdminEmails() {
        Set<String> emails = new Set<String>();
        List<Id> sysAdminProfileIds = UTIL_Profile.getInstance().getProfileIds(UTIL_Profile.SYSTEM_ADMINISTRATOR);

        if (sysAdminProfileIds.isEmpty() == false) {
            for (User usr : [
                    SELECT Email 
                    FROM User 
                    WHERE ProfileId IN :sysAdminProfileIds 
                    AND IsActive = true
            ]) {
                emails.add(usr.Email);
            }
        }

        return new List<String>(emails);
    }

    /**********************************************************************************************
    * @description Sends error email notifications.
    * @param context The context that triggered the error notification
    * @param recipientsList The list of email addresses to send notifications to.
    * @return void
    */
    private void sendEmailNotifications(String context, List<String> recipientsList) {

        if (!System.isBatch() && !System.isFuture() && Limits.getAsyncCalls() < Limits.getLimitAsyncCalls()) {
            sendErrorQueueEmailNotificationFuture(recipientsList);

        } else if (System.isFuture()) {
            sendErrorQueueEmailNotification(context, recipientsList);
        }
    }

    /**********************************************************************************************
    * @description Sends error email notifications in a future (asynchronously). It will send an email
    * with all the existing error records not already sent in a notification.
    * @param context The context that triggered the error notification.
    * @param recipientsList The list of email addresses to send notifications to.
    * @return void
    */
    @future
    private static void sendErrorQueueEmailNotificationFuture(List<String> recipientsList) {
        ERR_Notifier notifierService = new ERR_Notifier();
        notifierService.sendErrorQueueEmailNotification(null, recipientsList);
    }

    /**********************************************************************************************
    * @description Sends error email notifications synchronously. It will send an email with all the
    * existing error records not already sent in a notification.
    * @param context The context that triggered the error notification.
    * @param recipientsList The list of email addresses to send notifications to.
    * @return void
    */
    private void sendErrorQueueEmailNotification(String context, List<String> recipientsList) {
        List<Error__c> errors = getErrorsPendingNotification();

        if (!errors.isEmpty() && !recipientsList.isEmpty()) {
            try {
                Messaging.SingleEmailMessage email = createEmailMessage(context, errors, recipientsList);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
            } catch (Exception ex) {
                // Swallow any errors generating the email
            }

            for (Error__c error : errors) {
                error.Email_Sent__c = true;
            }
            update errors;
        }
    }

    /**********************************************************************************************
    * @description Creates the email message to send as error notification.
    * @param context The context that triggered the error notification.
    * @param errorList The list of errors to include in the email.
    * @param recipientsList The list of email recipients.
    * @return 
    */
    private Messaging.SingleEmailMessage createEmailMessage(String context, List<Error__c> errorList, List<String> recipientsList) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setUseSignature(false);
        mail.setReplyTo(EMAIL_REPLY_TO);
        mail.setSenderDisplayName(EMAIL_SENDER_NAME);
        mail.setSubject(EMAIL_SUBJECT);

        String bodyStringTemplate = 'Organization: {0} ({1})\nUser: {2} ({3})\n\n';
        String bodyString = String.format(bodyStringTemplate, new List<String>{
                UserInfo.getOrganizationName(), UserInfo.getOrganizationId(), UserInfo.getUserName(), UserInfo.getUserId()
        });

        bodyString += System.Label.ErrorEmailMessage + '\n';
        if (context == ERR_Handler_API.Context.RD.name()) {
            bodyString += System.Label.npe03.RecurringDonationErrorEmailBody;
        }

        bodyString += '\n\nErrors:';
        Integer i = 1;
        for (Error__c error : errorList) {
            bodyString += '\n\n----------\n Error #' + i + ': \n' + buildErrorMessageBody(error);
            i++;
        }

        mail.setPlainTextBody(bodyString);
        mail.setToAddresses(recipientsList); 
        return mail;        
    }

    /**********************************************************************************************
    * @description Post a message to Chatter with information about all the existing error records
    * that were not already posted.
    * @param chatterGroupId The ID of the Chatter group to post to.
    * @return void
    */
    private void postErrorsToChatter(String chatterGroupId) {

        if (!(chatterGroupId instanceof Id)) {
            return;
        }

        SObject collaborationGroup = Database.query('SELECT Id, Name' +
                ' FROM CollaborationGroup' +
                ' WHERE Id = :chatterGroupId' +
                ' LIMIT 1');

        List<Error__c> errors = getErrorsPendingNotification();

        if (!errors.isEmpty()) {

            List<SObject> postsToInsert = new List<SObject>();
            for (Error__c error : errors) {
                postsToInsert.add(createChatterPost(error, collaborationGroup.Id));
                error.Posted_in_Chatter__c = true;
            }

            try {
                insert postsToInsert;
            } catch (Exception ex) {
                // swallow any errors posting the errors to chatter
            }

            update errors; //we don't want to post the same errors again
        }
    }

    /**********************************************************************************************
     * @description Create a chatter post for a specific Error__c log record
     * @param error
     * @param groupId
     * @return FeedItem
     */
    private SObject createChatterPost(Error__c error, Id groupId) {
        String body = buildErrorMessageBody(error);

        SObject post = (SObject)System.Type.forName('FeedItem').newInstance();
        post.put('Title', 'Salesforce Error');
        post.put('Body', body);
        post.put('ParentId', groupId);

        return post;
    }

    /**********************************************************************************************
    * @description Creates the body of the error message for a specific error record.
    * @param error The error record to create the message String from.
    * @return String The String representing the error record.
    */
    private String buildErrorMessageBody(Error__c error) {

        String body = '\nError Type: ' + error.Error_Type__c;
        body += '\nError Date: ' + error.Datetime__c;
        body += '\nMessage: "' + error.Full_Message__c + '"';

        if (error.Record_URL__c != null) {
            body += '\n' + error.Record_URL__c;
        }

        if (error.Context_Type__c != null) {
            body += '\nContext: ' + error.Context_Type__c;
        }

        body += '\n\nStack Trace:\n ' + error.Stack_Trace__c;

        return body;
    }

    /**********************************************************************************************
     * @description Return a list of errors pending notification (email or chatter). Limits the list to
     * the defined maximum number of records, and only those created in the defined period of time
     * @return List<Error__c>
     */
    @TestVisible
    private List<Error__c> getErrorsPendingNotification() {
        return [SELECT  Id, 
                        Error_Type__c, 
                        Datetime__c, 
                        Full_Message__c,
                        Record_URL__c, 
                        Context_Type__c, 
                        Stack_Trace__c
                FROM Error__c
                WHERE Email_Sent__c = FALSE
                    AND Posted_in_Chatter__c = FALSE
                    AND Datetime__c >= :MAX_AGE_FOR_ERRORS
                ORDER BY CreatedDate ASC
                LIMIT :MAX_RECORDS
            ];
    }
}