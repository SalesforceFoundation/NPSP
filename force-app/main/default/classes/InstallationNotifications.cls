/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Domain for building and publishing install script triggered user notifications.
*/

public inherited sharing class InstallationNotifications {

   @TestVisible private List<Custom_Notification__mdt> activeNotifications;
   @TestVisible private List<CustomNotificationType> customNotificationTypes;
   @TestVisible private Map<String, CustomNotificationType> activeNotificationsByType;
   private static String namespace = UTIL_Namespace.getNamespace();
   private InstallContext context;

   // Private Constructor for testing purposes
   @TestVisible
   private InstallationNotifications() {
      initializeNotifications();
   }

   public InstallationNotifications(InstallContext context) {
      this.context = context;
      initializeNotifications();
   }

   private void initializeNotifications () {
      this.activeNotifications = installationNotificationsSelector.getActiveCustomNotifications();
      if (!activeNotifications.isEmpty()) {
         this.customNotificationTypes =
             notificationTypeSelector.getCustomNotificationTypesFor(activeNotificationChannels());
         this.activeNotificationsByType = buildActiveNotificationsByType(this.customNotificationTypes);
      }
   }

   private List<String> activeNotificationChannels() {
      List<String> activeNotificationChannels = new List<String>();
      for (Custom_Notification__mdt notification : this.activeNotifications) {
         activeNotificationChannels.add(notification.Notification_Channel__c);
      }
      return activeNotificationChannels;
   }

   @TestVisible
   private static InstallationNotificationsSelector installationNotificationsSelector {
      get {
         if (installationNotificationsSelector == null) {
            installationNotificationsSelector = new InstallationNotificationsSelector();
         }
         return installationNotificationsSelector;
      }
      set;
   }

   @TestVisible
   private static CustomNotificationTypeSelector notificationTypeSelector {
      get {
         if (notificationTypeSelector == null) {
            notificationTypeSelector = new CustomNotificationTypeSelector();
         }
         return notificationTypeSelector;
      }
      set;
   }

   private Map<String, CustomNotificationType> buildActiveNotificationsByType (
       List<CustomNotificationType> notifications) {
      Map<String, CustomNotificationType> customNotificationByType = new Map<String, CustomNotificationType>();
      for (CustomNotificationType customNotificationType : notifications) {
         customNotificationByType.put(customNotificationType.CustomNotifTypeName, customNotificationType);
      }
      return customNotificationByType;
   }

   public void publish() {
      for (Custom_Notification__mdt notification : this.activeNotifications) {
         if (!canPublish(notification)) { continue; }
         IInstallationNotification content = getNotificationContent(
                notification.Notification_Content_Implementation__c);
            Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
            customNotification.setBody(content.body());
            customNotification.setTitle(content.title());
            customNotification.setTargetPageRef(buildPageReferenceFor(notification));
            customNotification.setNotificationTypeId(
                activeNotificationsByType.get(notification.Notification_Channel__c).Id);
            customNotification.send(getAudience(notification.Audience_Implementation__c).stringValues());
      }
   }

   @TestVisible
   private Boolean canPublish(Custom_Notification__mdt notification) {
      return (getAudience(notification.Audience_Implementation__c) != null
          && this.activeNotificationsByType.containsKey(notification.Notification_Channel__c));
   }


   private String buildPageReferenceFor(Custom_Notification__mdt notification) {
      String componentName = (String.isNotBlank(namespace) ? namespace : 'c') + '__notificationRedirecter';
      Map<String, Object> pageRef = new Map<String, Object>{
          'type' => 'standard__component',
          'attributes' => new Map<String, Object> {
              'componentName' => componentName
          },
          'state' => new Map<String, Object> {
              'c__redirectUrl' => notification.Redirect_URL__c
          }
      };
      return JSON.serialize(pageRef);
   }

   private IInstallationNotification getNotificationContent(String notificationContentImpl) {
      return (IInstallationNotification)getClassType(notificationContentImpl).newInstance();
   }

   @TestVisible
   private UserIds getAudience(String audienceImpl) {
      IAudience nonElevateCustomers = (IAudience)getClassType(audienceImpl)?.newInstance();
      return nonElevateCustomers?.audience();
   }

   private Type getClassType(String classImpl) {
      Type classType = String.isNotBlank(namespace)
          ? Type.forName(namespace, classImpl)
          : Type.forName(classImpl);
      return classType;
   }

}