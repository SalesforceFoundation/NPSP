/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Utilities
* @description Utility for Profiles
*/
public class UTIL_Profile {

    /** @description System Administrator Profile Name */
    public static final String SYSTEM_ADMINISTRATOR {
        get {
            switch on (UserInfo.getLanguage()) {
                when 'es' {
                    return 'Administrador del sistema';
                }
                when 'de' {
                    return 'Systemadministrator';
                }
                when 'ja' {
                    return 'システム管理者';
                }
                when 'fr' {
                    return 'Administrateur système';
                }
                when 'NL_nl' {
                    return 'Systeembeheerder';
                }
            }
            return 'System Administrator';
        }
    }

    /** @description Read Only Profile Name */
    public static final String PROFILE_STANDARD_USER {
        get {
            switch on (UserInfo.getLanguage()) {
                when 'es' {
                    return 'Usuario estándar';
                }
                when 'de' {
                    return 'Lesezugriff';
                }
                when 'ja' {
                    return '標準ユーザ';
                }
                when 'fr' {
                    return 'Utilisateur standard';
                }
                when 'NL_nl' {
                    return 'Standaardgebruiker';
                }
            }
            return 'Standard User';
        }
    }

    /** @description Minimum Access - Salesforce Profile Name */
    public static final String PROFILE_MINIMUM_ACCESS = 'Minimum Access - Salesforce';

    /** @description True if the Read Only profile exists in the org */
    private static Boolean hasReadOnlyProfile;

    /*********************************************************************************************************
    * @description Read Only Profile Name
    * Returns PROFILE_MINIMUM_ACCESS if 'Read Only' profile isn't found.
    */
    public static final String PROFILE_READ_ONLY {
        get {
            String readOnly = 'Read Only';

            switch on (UserInfo.getLanguage()) {
                when 'es' {
                    readOnly = 'Sólo lectura';
                }
                when 'de' {
                    readOnly = 'Standardbenutzer';
                }
                when 'ja' {
                    readOnly = '参照のみ';
                }
                when 'fr' {
                    readOnly = 'Lecture seule';
                }
                when 'NL_nl' {
                    readOnly = 'Alleen-lezen';
                }
            }

            if (hasReadOnlyProfile == null) {
                hasReadOnlyProfile = hasProfile(readOnly);
            }

            if (hasReadOnlyProfile == true) {
                return readOnly;
            }
            return PROFILE_MINIMUM_ACCESS;
        }
    }

    /*********************************************************************************************************
    * @description Checks for any Profile records with the provided Name
    * @return BOOLEAN True if query returns at least 1 profile record by the provided Name exists
    */
    private static Boolean hasProfile(String profileName) {
        Integer profileRecordCount = [SELECT count() FROM Profile WHERE Name = :profileName];
        if (profileRecordCount != null && profileRecordCount > 0) {
            return true;
        }
        return false;
    }

    /** @description static instance of the current class (UTIL_Profile). It is used as the instance in a Singleton context */
    private static UTIL_Profile utilProfile;

    /** @description Map of the Profiles grouped by Name */
    private Map<String, List<Profile>> profilesByName;

    /*********************************************************************************************************
    * @description Get the instance of the current class
    * @return UTIL_Profile The instance of the current class.
    */
    public static UTIL_Profile getInstance() {
        if (utilProfile == null) {
            utilProfile = new UTIL_Profile();
        }
        return utilProfile;
    }

    /*********************************************************************************************************
    * @description The Constructor, which is private because we are using the Singleton Pattern.
    * The UTIL_Profile object needs to be constructed only from the static method getInstance()
    */
    private UTIL_Profile() {
        profilesByName = getProfilesByName();
    }

    /*********************************************************************************************************
    * @description Get Profile Ids for the specified Profile Name
    * @param profileName Profile Name
    * @return List<Id> List of Profile Ids
    */
    public List<Id> getProfileIds(String profileName) {
        if (profilesByName.containsKey(profileName) == false) {
            return new List<Id>();
        }

        Set<Id> profileIds = new Map<Id, Profile>(profilesByName.get(profileName)).keySet();
        return new List<Id>(profileIds);
    }

    /*********************************************************************************************************
    * @description Build a Map of Profiles grouped by Name
    * @return Map<String, List<Profile>> Map of Profiles grouped by Name
    */
    private Map<String, List<Profile>> getProfilesByName() {
        Map<String, List<Profile>> result = new Map<String, List<Profile>>();

        for (Profile currentProfile :[
                SELECT Name
                FROM Profile
        ]) {
            if (result.containsKey(currentProfile.Name) == false) {
                result.put(currentProfile.Name, new List<Profile>());
            }

            result.get(currentProfile.Name).add(currentProfile);
        }

        return result;
    }
}