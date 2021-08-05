/**
 * Created by voduyemi on 8/5/21.
 */

public with sharing class UserId {

   private Id userId;

   public UserId(Id userId) {
      if (!isUserId(userId)) {
         throw new UserIdException('Invalid User Id');
      }
      this.userId = userId;
   }

   private Boolean isUserId(Id userId) {
      SObjectType providedIdSObjectType = userId.getSobjectType();
      if (providedIdSObjectType == User.getSObjectType()) {
         return true;
      }
      return false;
   }

   public Id value() {
      return this.userId;
   }

   public String stringValue() {
      return (String)this.userId;
   }

   public class UserIdException extends Exception {}
}