/**
 * Created by voduyemi on 8/4/21.
 */

public with sharing class CustomNotificationTypeSelector {

   public List<CustomNotificationType> getCustomNotificationTypes () {
      return [
        SELECT Id, CustomNotifTypeName
        FROM CustomNotificationType
      ];
   }
}