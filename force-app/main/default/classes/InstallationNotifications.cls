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

   private List<Custom_Notification__mdt> activeNotifications;
   private List<CustomNotificationType> customNotificationTypes;
   private Map<String, CustomNotificationType> activeNotificationsByType;

   public InstallationNotifications() {
      this.activeNotifications = installationNotificationsSelector.getActiveCustomNotifications();
      if (!shouldPublishNotifications(this.activeNotifications)) { return; }
      this.customNotificationTypes = notificationTypeSelector.getCustomNotificationTypes();
      this.activeNotificationsByType = buildActiveNotificationsByType(this.customNotificationTypes);
   }

   private Boolean shouldPublishNotifications (List<Custom_Notification__mdt> activeNotifications) {
      return !activeNotifications.isEmpty() && activeNotifications != null;
   }

   @TestVisible
   private InstallationNotificationsSelector installationNotificationsSelector {
      get {
         if (installationNotificationsSelector == null) {
            installationNotificationsSelector = new InstallationNotificationsSelector();
         }
         return installationNotificationsSelector;
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
         if (getAudience(notification.Audience_Implementation__c) == null) { continue; }
         if (activeNotificationsByType.containsKey(notification.Notification_Channel__c)) {
            ElevateAdNotificationContent content = getNotificationContent(
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
   }

   private String buildPageReferenceFor(Custom_Notification__mdt notification) {
      String namespace = getNamespace();
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

   private ElevateAdNotificationContent getNotificationContent(String notificationContentImpl) {
      return (ElevateAdNotificationContent)getClassType(notificationContentImpl).newInstance();
   }

   private UserIds getAudience(String audienceImpl) {
      USNonElevateCustomers nonElevateCustomers = (USNonElevateCustomers)getClassType(audienceImpl).newInstance();
      return nonElevateCustomers.audience();
   }

   private Type getClassType(String classImpl) {
      String namespace = getNamespace();
      Type classType = String.isNotBlank(namespace)
          ? Type.forName(namespace, classImpl)
          : Type.forName(classImpl);
      return classType;
   }

   private String getNamespace() {
      return UTIL_Namespace.getNamespace();
   }

}