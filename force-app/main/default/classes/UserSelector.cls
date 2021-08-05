/**
 * Created by voduyemi on 8/4/21.
 */

public with sharing class UserSelector {

   public List<User> getUsers() {
      return [
          SELECT Id
          FROM User LIMIT 10000
      ];
   }
}