/**
 * Created by voduyemi on 8/4/21.
 */

public with sharing class CustomNotificationMetadataSelector {

   public List<Custom_Notification__mdt> getActiveCustomNotifications() {
      return [
          SELECT Id, Body__c, Title__c, Redirect_URL__c, Notification_Channel__c
          FROM Custom_Notification__mdt
          WHERE IsActive__c = TRUE
      ];
   }

}