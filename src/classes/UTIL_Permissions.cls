/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2018
* @group Utilities
* @description Object- and field-level security checks
*/
public with sharing class UTIL_Permissions {

    private final static String INSUFFICIENT_PERMISSION_MESSAGE = System.Label.flsError;

    public static Boolean canRead(String obj) {
        return canRead(obj, true);
    }

    public static Boolean canWrite(String obj) {
        return canWrite(obj, true);
    }

    public static Boolean canCreate(String obj) {
        return canCreate(obj, true);
    }

    public static Boolean canDelete(String obj) {
        return canDelete(obj, true);
    }

    public static Boolean canRead(String obj, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(obj).isAccessible()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    public static Boolean canWrite(String obj, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(obj).isUpdateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    public static Boolean canCreate(String obj, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(obj).isCreateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    public static Boolean canDelete(String obj, Boolean throwException) {
        if (!UTIL_Describe.getObjectDescribe(obj).isDeletable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    public static Boolean canRead(String obj, String field, Boolean throwException) {
        if (!UTIL_Describe.getFieldDescribe(obj, field).isAccessible()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    public static Boolean canWrite(String obj, String field, Boolean throwException) {
        if (!UTIL_Describe.getFieldDescribe(obj, field).isUpdateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    public static Boolean canCreate(String obj, String field, Boolean throwException) {
        if (!UTIL_Describe.getFieldDescribe(obj, field).isCreateable()) {
            if (throwException) {
                throw new InsufficientPermissionException(INSUFFICIENT_PERMISSION_MESSAGE);
            } else {
                return false;
            }
        }
        return true;
    }

    public static Boolean canRead(String obj, String field) {
        return canRead(obj, field, true);
    }

    public static Boolean canWrite(String obj, String field) {
        return canWrite(obj, field, true);
    }

    public static Boolean canCreate(String obj, String field) {
        return canCreate(obj, field, true);
    }

    public class InsufficientPermissionException extends Exception {}

}
