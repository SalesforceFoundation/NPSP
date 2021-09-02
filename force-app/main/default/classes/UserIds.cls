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
* @description Value object class for user Id.
*/

public inherited sharing class UserIds {

   private Set<String> stringUserIds;
   private Set<Id> userIds = new Set<Id>();

   public UserIds(Set<Id> ids) {
      for (Id userId: ids) {
         if (!isUserId(userId)) {
            throw new UserIdException('Invalid User Id');
         }
         userIds.add(userId);
      }
      this.userIds = userIds;
   }

   private Boolean isUserId(Id userId) {
      SObjectType providedIdSObjectType = userId.getSobjectType();
      if (providedIdSObjectType == User.getSObjectType()) {
         return true;
      }
      return false;
   }

   public Set<Id> values() {
      return this.userIds;
   }


   public Set<String> stringValues() {
      this.stringUserIds = new Set<String>();
      for (Id userId : values()) {
         this.stringUserIds.add(userId);
      }
      return this.stringUserIds;
   }

   public class UserIdException extends Exception {}
}