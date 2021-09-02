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
* @description Installation Notification tests.
*/

@isTest
private class InstallationNotifications_TEST {
   @isTest
   static void shouldNotPublishNotificationWithoutAudience() {
      Test.startTest();
      InstallationNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationNotificationsSelectorMock().withAudience(false).withRedirectURL(false);
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications.installationNotificationsSelector = stubFor(installationsNotificationsSelectorMock);
      InstallationNotifications.notificationTypeSelector = stubFor(customNotificationTypeSelectorMock);
      InstallationNotifications notifications = new InstallationNotifications();
      Test.stopTest();
      System.assert(!notifications.canPublish(notifications.activeNotifications[0]));
      System.assert(MockAudienceImpl.userId == null);
   }

   @isTest
   static void shouldPublishNotificationWithAudience() {

      Test.startTest();
      InstallationNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationNotificationsSelectorMock().withAudience(true);
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications.installationNotificationsSelector = stubFor(installationsNotificationsSelectorMock);
      InstallationNotifications.notificationTypeSelector = stubFor(customNotificationTypeSelectorMock);

      InstallationNotifications notifications = new InstallationNotifications();
      Test.stopTest();

      System.assert(notifications.canPublish(notifications?.activeNotifications[0]));
      System.assert(MockAudienceImpl.userId != null);
   }

   @isTest
   static void shouldPublishNotificationWithoutRedirectURL() {

      Test.startTest();
      InstallationNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationNotificationsSelectorMock().withAudience(true).withRedirectURL(false);
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications.installationNotificationsSelector = stubFor(installationsNotificationsSelectorMock);
      InstallationNotifications.notificationTypeSelector = stubFor(customNotificationTypeSelectorMock);

      InstallationNotifications notifications = new InstallationNotifications();
      Test.stopTest();

      System.assert(notifications.canPublish(notifications?.activeNotifications[0]));
      System.assert(MockAudienceImpl.userId != null);
   }

   @isTest
   static void shouldNotPublishInActiveNotification() {

      Test.startTest();
      InstallationNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationNotificationsSelectorMock().withIsActive(false);
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications.installationNotificationsSelector = stubFor(installationsNotificationsSelectorMock);
      InstallationNotifications.notificationTypeSelector = stubFor(customNotificationTypeSelectorMock);

      InstallationNotifications notifications = new InstallationNotifications();
      Test.stopTest();

      System.assertEquals(notifications.customNotificationTypes, null);
      System.assertEquals(notifications.activeNotificationsByType, null);

   }

   @isTest
   static void shouldNotPublishNotificationWithoutValidAudience() {
      Test.startTest();
      InstallationNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationNotificationsSelectorMock()
              .withAudience(false)
              .withAudienceImpl('FakeImpl');
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications.installationNotificationsSelector = stubFor(installationsNotificationsSelectorMock);
      InstallationNotifications.notificationTypeSelector = stubFor(customNotificationTypeSelectorMock);
      InstallationNotifications notifications = new InstallationNotifications();
      Test.stopTest();
      System.assert(!notifications.canPublish(notifications.activeNotifications[0]));
      System.assert(MockAudienceImpl.userId == null);
   }

   @isTest
   static void shouldPublishNotificationsWithDifferentAudiencesCorrectly() {
      Test.startTest();
      InstallationNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationNotificationsSelectorMock()
              .withAudience(true);
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications.installationNotificationsSelector = stubFor(installationsNotificationsSelectorMock);
      InstallationNotifications.notificationTypeSelector = stubFor(customNotificationTypeSelectorMock);
      InstallationNotifications notifications = new InstallationNotifications();
      Test.stopTest();
      System.assert(notifications.canPublish(notifications.activeNotifications[0]));
      System.assert(MockAudienceImpl.userId != null);
      System.assert(!notifications.canPublish(notifications.activeNotifications[1]));

   }

   private class InstallationNotificationsSelectorMock implements StubProvider {

      private Boolean withRedirectURL = true;
      private Boolean isActive = true;
      private Boolean withAudience = true;
      private String audience = '';

      public InstallationNotificationsSelectorMock withRedirectURL (Boolean withRedirectURL) {
         this.withRedirectURL = withRedirectURL;
         return this;
      }

      public InstallationNotificationsSelectorMock withIsActive (Boolean isActive) {
         this.isActive = isActive;
         return this;
      }

      public InstallationNotificationsSelectorMock withAudience (Boolean withAudience) {
         this.withAudience = withAudience;
         return this;
      }

      public InstallationNotificationsSelectorMock withAudienceImpl (String audience) {
         this.audience = audience;
         return this;
      }

       public Object handleMethodCall(
           Object stubbedObject,
           String stubbedMethodName,
           Type returnType,
           List<Type> listOfParamTypes,
           List<String> listOfParamNames,
           List<Object> listOfArgs) {

           switch on (stubbedMethodName) {
               when 'getActiveCustomNotifications' {
                  if(!isActive) {
                     return new List<Custom_Notification__mdt>();
                  }
                  return buildCustomNotifications();
               }
           }
          return null;
       }

      private List<Custom_Notification__mdt> buildCustomNotifications() {
         Id DUMMY_CUSTOM_NOTIFICATION_ID =
             UTIL_UnitTestData_TEST.mockId(Custom_Notification__mdt.getSObjectType());
         List<Custom_Notification__mdt> notifications = new List<Custom_Notification__mdt>{
             new Custom_Notification__mdt(
                 Id = DUMMY_CUSTOM_NOTIFICATION_ID,
                 Notification_Channel__c = 'Fake Notification',
                 Audience_Implementation__c = withAudience ? 'MockAudienceImpl' : audience,
                 Notification_Content_Implementation__c = 'MockNotificationContentImpl',
                 Redirect_URL__c = withRedirectURL ? 'https://test.org' : '',
                 IsActive__c = isActive
             ),
             new Custom_Notification__mdt(
                 Id = DUMMY_CUSTOM_NOTIFICATION_ID,
                 Notification_Channel__c = 'Fake Notification',
                 Audience_Implementation__c = 'FakeImpl',
                 Notification_Content_Implementation__c = 'MockNotificationContentImpl',
                 Redirect_URL__c = withRedirectURL ? 'https://test.org' : '',
                 IsActive__c = isActive
             )
         };
         return notifications;
      }
   }



   private class CustomNotificationTypeSelectorMock implements StubProvider {
      public Object handleMethodCall(
          Object stubbedObject,
          String stubbedMethodName,
          Type returnType,
          List<Type> listOfParamTypes,
          List<String> listOfParamNames,
          List<Object> listOfArgs) {

         switch on (stubbedMethodName) {
            when 'getCustomNotificationTypesFor' {
               Id DUMMY_CUSTOM_NOTIFICATION_ID = UTIL_UnitTestData_TEST.mockId(CustomNotificationType.getSObjectType());

               List<CustomNotificationType> customNotificationTypes = new List<CustomNotificationType>{
                   new CustomNotificationType(
                       Id = DUMMY_CUSTOM_NOTIFICATION_ID,
                       CustomNotifTypeName = 'Fake Notification'
                   )
               };
               return customNotificationTypes;
            }
         }
         return null;
      }
   }

   private static CustomNotificationTypeSelector stubFor(
       CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock) {
      return (CustomNotificationTypeSelector) Test.createStub(
          CustomNotificationTypeSelector.class, customNotificationTypeSelectorMock);
   }

   private static InstallationNotificationsSelector stubFor(
       InstallationNotificationsSelectorMock installationsNotificationsSelectorMock) {
      return (InstallationNotificationsSelector) Test.createStub(
          InstallationNotificationsSelector.class, installationsNotificationsSelectorMock);
   }

}
