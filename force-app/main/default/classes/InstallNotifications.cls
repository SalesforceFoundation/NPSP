/**
 * Created by voduyemi on 8/4/21.
 */

public with sharing class InstallNotifications {

   private String body;
   private String title;
   private Set<String> audience;
   private Id notificationTypeId;
   private List<Custom_Notification__mdt> activeCustomNotificationMetadata;
   private List<CustomNotificationType> customNotificationTypes;

   public InstallNotifications() {
      this.activeCustomNotificationMetadata = customNotificationMetadataSelector.getActiveCustomNotifications();
      this.customNotificationTypes = notificationTypeSelector.getCustomNotificationTypes();
   }

   @TestVisible
   private CustomNotificationMetadataSelector customNotificationMetadataSelector {
      get {
         if (customNotificationMetadataSelector == null) {
            customNotificationMetadataSelector = new CustomNotificationMetadataSelector();
         }
         return customNotificationMetadataSelector;
      }
      set;
   }

   @TestVisible
   private CustomNotificationTypeSelector notificationTypeSelector {
      get {
         if (notificationTypeSelector == null) {
            notificationTypeSelector = new CustomNotificationTypeSelector();
         }
         return notificationTypeSelector;
      }
      set;
   }

   public InstallNotifications withBody(String body) {
      this.body = body;
      return this;
   }

   public InstallNotifications withNotificationTypeId(Id notificationTypeId) {
      this.notificationTypeId = notificationTypeId;
      return this;
   }

   public InstallNotifications withTitle(String title) {
      this.title = title;
      return this;
   }

   public InstallNotifications withAudience(Set<String> audience) {
      this.audience = audience;
      return this;
   }

   public void publishNotifications() {
      for (Custom_Notification__mdt notificationMetaData : activeCustomNotificationMetadata) {
         for (CustomNotificationType notificationType : customNotificationTypes) {
            if (notificationType.CustomNotifTypeName == notificationMetaData.Notification_Channel__c) {
               new InstallNotifications()
                   .withNotificationTypeId(notificationType.Id)
                   .withBody(notificationMetaData.Body__c)
                   .withTitle(notificationMetaData.Title__c)
                   .withAudience(getAudience(notificationMetaData.Audience_Implementation_Class__c))
                   .publish();
            }
         }
      }
   }

   private Set<String> getAudience (String audienceImpl) {
      String namespace = UTIL_Namespace.getNamespace();
      Type classType = String.isNotBlank(namespace)
          ? Type.forName(namespace, audienceImpl)
          : Type.forName(audienceImpl);
      USElevateCustomers elevateCustomers = (USElevateCustomers)classType.newInstance();
      return elevateCustomers.audience();
   }

   private void publish() {
      Messaging.CustomNotification notification = new Messaging.CustomNotification();
      notification.setBody(this.body);
      notification.setTitle(this.title);
      notification.setNotificationTypeId(this.notificationTypeId);
      notification.send(this.audience);
   }

}