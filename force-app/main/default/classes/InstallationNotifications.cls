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
      this.customNotificationTypes = notificationTypeSelector.getCustomNotificationTypes();
      this.activeNotifications = installationNotificationsSelector.getActiveCustomNotifications();
      this.activeNotificationsByType = buildActiveNotificationsByType(this.customNotificationTypes);
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
      for (CustomNotificationType customNotificationType : notifications) {
         activeNotificationsByType.put(customNotificationType.CustomNotifTypeName, customNotificationType);
      }
      return activeNotificationsByType;
   }

   public void publish() {
      String DUMMY_ID = '000000000000000AAA';
      for (Custom_Notification__mdt notification : this.activeNotifications) {
         if (activeNotificationsByType.containsKey(notification.Notification_Channel__c)) {
            ElevateAdNotificationContent content = getNotificationContent(
                notification.Notification_Content_Implementation__c);
            Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
            customNotification.setBody(content.body());
            customNotification.setTitle(content.title());
            customNotification.setNotificationTypeId(
                activeNotificationsByType.get(notification.Notification_Channel__c).Id);
            customNotification.setTargetId(DUMMY_ID);
            customNotification.send(getAudience(notification.Audience_Implementation__c));
         }
      }
   }

   private ElevateAdNotificationContent getNotificationContent(String notificationContentImpl) {
      return (ElevateAdNotificationContent)getClassType(notificationContentImpl).newInstance();
   }

   private Set<String> getAudience(String audienceImpl) {
      USNonElevateCustomers nonElevateCustomers = (USNonElevateCustomers)getClassType(audienceImpl).newInstance();
      return nonElevateCustomers.audience().stringValues();
   }

   private Type getClassType(String classImpl) {
      String namespace = UTIL_Namespace.getNamespace();
      Type classType = String.isNotBlank(namespace)
          ? Type.forName(namespace, classImpl)
          : Type.forName(classImpl);
      return classType;
   }

}