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

@IsTest
private class InstallationsNotifications_TEST {
   @IsTest
   static void shouldNotPublishNotificationWithoutRedirectURL() {

      Test.startTest();
      InstallationsNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationsNotificationsSelectorMock().withRedirectURL(false);
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications notifications = new InstallationNotifications();


      notifications.activeNotifications =
          stubFor(installationsNotificationsSelectorMock).getActiveCustomNotifications();
      notifications.customNotificationTypes =
          stubFor(customNotificationTypeSelectorMock).getCustomNotificationTypes();

      notifications.activeNotificationsByType =
          new Map<String, CustomNotificationType>{
              notifications.customNotificationTypes[0].CustomNotifTypeName => notifications.customNotificationTypes[0]
      };
      System.assert(!notifications.canPublish(notifications.activeNotifications[0]));
      Test.stopTest();
   }

   @IsTest
   static void shouldPublishNotificationWithRedirectURL() {

      Test.startTest();
      InstallationsNotificationsSelectorMock installationsNotificationsSelectorMock =
          new InstallationsNotificationsSelectorMock().withRedirectURL(true);
      CustomNotificationTypeSelectorMock customNotificationTypeSelectorMock =
          new CustomNotificationTypeSelectorMock();

      InstallationNotifications notifications = new InstallationNotifications();

      notifications.activeNotifications =
          stubFor(installationsNotificationsSelectorMock).getActiveCustomNotifications();
      notifications.customNotificationTypes =
          stubFor(customNotificationTypeSelectorMock).getCustomNotificationTypes();

      notifications.activeNotificationsByType =
          new Map<String, CustomNotificationType>{
              notifications.customNotificationTypes[0].CustomNotifTypeName => notifications.customNotificationTypes[0]
          };

      System.assert(notifications.canPublish(notifications.activeNotifications[0]));
      Test.stopTest();
   }

   private class InstallationsNotificationsSelectorMock implements StubProvider {

      private Boolean withRedirectURL;

      public InstallationsNotificationsSelectorMock withRedirectURL (Boolean withRedirectURL) {
         this.withRedirectURL = withRedirectURL;
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
                  Id DUMMY_CUSTOM_NOTIFICATION_ID =
                      UTIL_UnitTestData_TEST.mockId(Custom_Notification__mdt.getSObjectType());

                  List<Custom_Notification__mdt> notifications = new List<Custom_Notification__mdt>{
                      new Custom_Notification__mdt(
                          Id = DUMMY_CUSTOM_NOTIFICATION_ID,
                          Notification_Channel__c = 'Fake Notification',
                          Audience_Implementation__c = 'MockAudienceImpl',
                          Notification_Content_Implementation__c = 'MockNotificationContentImpl',
                          Redirect_URL__c = withRedirectURL ? 'https://test.org' : '',
                          IsActive__c = true
                      )
                  };
                  return notifications;
               }
           }
          return null;
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
            when 'getCustomNotificationTypes' {
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
       InstallationsNotificationsSelectorMock installationsNotificationsSelectorMock) {
      return (InstallationNotificationsSelector) Test.createStub(
          InstallationNotificationsSelector.class, installationsNotificationsSelectorMock);
   }

}
