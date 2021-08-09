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

   public InstallationNotifications() {
      this.activeNotifications = installationNotificationsSelector.getActiveCustomNotifications();
      this.customNotificationTypes = notificationTypeSelector.getCustomNotificationTypes();
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

   public void publish() {
      String DUMMY_ID = '000000000000000AAA';
      for (Custom_Notification__mdt activeNotification : activeNotifications) {
         for (CustomNotificationType notificationType : customNotificationTypes) {
            if (notificationType.CustomNotifTypeName == activeNotification.Notification_Channel__c) {
               Messaging.CustomNotification notification = new Messaging.CustomNotification();
               notification.setBody(activeNotification.Body__c);
               notification.setTitle(activeNotification.Title__c);
               notification.setNotificationTypeId(notificationType.Id);
               notification.setTargetId(DUMMY_ID);
               notification.send(getAudience(activeNotification.Audience_Implementation_Class__c));
            }
         }
      }
   }

   private Set<String> getAudience(String audienceImpl) {
      String namespace = UTIL_Namespace.getNamespace();
      Type classType = String.isNotBlank(namespace)
          ? Type.forName(namespace, audienceImpl)
          : Type.forName(audienceImpl);
      USNonElevateCustomers nonElevateCustomers = (USNonElevateCustomers)classType.newInstance();
      return nonElevateCustomers.audience().stringValues();
   }

}