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
* @date 2017
* @group Getting Started
* @description Component that brings the latest release notes from Github using Salesforce org HEROKU APP.
*/
public with sharing class RP_GitHubController {

    //Object used to load all information related to github release notes
    public GitHubWrapper gitHubData {get; set;}
    public Boolean timeoutError {get; set;}
    public Boolean remoteSiteSettingIsNotActive {get; set;}

    public RP_GitHubController() {

        loadLatestReleaseNotes();
    }

    /*******************************************************************************************************
    * @description method to load release notes from github, into GithubWrapper object and use it in github component
    * @return void
    */
    @TestVisible private void loadLatestReleaseNotes() {

        RP_GitHubClient client = new RP_GitHubClient();
        HttpResponse response = client.getLatestReleaseNotes();
        timeoutError = true;
        remoteSiteSettingIsNotActive = client.remoteSiteSettingIsNotActive;
        
        if (response != null) {

            String responseBody = response.getBody();

            Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            gitHubData = new GitHubWrapper(responseBodyMap);

            timeoutError = false;
        }

    }

    /*******************************************************************************************************
    * @description inner class, used to access all github release notes data
    */
    public class GitHubWrapper {

        public String latestDate {get; set;}
        public String latestDownloadUrl {get; set;}
        public Object latestVersion {get; set;}
        public String latestReleaseNotes {get; set;}
        public Object latestProductName {get; set;}


        /*******************************************************************************************************
        * @description GithubWrapper constructor, used to set response map from salesforce org endpoint, into
        * a GithubWrapper object
        * @param a deserialize json load in a map with the response values from salesforce org api
        */
        public GitHubWrapper(Map<String, Object> responseBodyMap) {

            if (responseBodyMap != null && responseBodyMap.containsKey('production_release')) {

                Map<String, Object> latestReleaseMap = (Map<String, Object>) responseBodyMap.get('production_release');
                latestProductName = responseBodyMap.get('product_name');

                if (latestReleaseMap != null && !latestReleaseMap.isEmpty()) {

                    latestReleaseNotes = (String) latestReleaseMap.get('release_notes_html');
                    latestDownloadUrl = (String) latestReleaseMap.get('url');
                    latestVersion = (String) latestReleaseMap.get('version');

                    String timeCreated = (String) latestReleaseMap.get('time_push_prod');
                    latestDate = formatDate(timeCreated);
                }
            }
        }

        /*******************************************************************************************************
        * @description operation to format a String into a different format Date
        * @param String with date to format
        * @return String
        */

        @TestVisible private String formatDate(String releaseDate) {

            String result = '';

            if (releaseDate != null) {

                releaseDate = releaseDate.replaceAll('T', ' ');
                releaseDate = releaseDate.replaceAll('Z', '');

                Datetime releaseDatetime = Datetime.valueOf(releaseDate);

                result = releaseDatetime.format();
                result = result.toLowerCase();
            }

            return result;
        }
    }

}