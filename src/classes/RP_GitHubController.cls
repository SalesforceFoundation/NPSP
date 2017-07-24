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
*
* @group Resource Page
*
* @description Component that brings the latest release notes from Github using Salesforce org HEROKU APP.
*/
public with sharing class RP_GitHubController {

    private static final String CUSTOM_METADATA_LAST_REPOSITORY_NAME = 'RP_GitHubLastRepositoryVersion';

    public GitHubWrapper gitHubData {get; set;}

    public RP_GitHubController() {

        updateGitHubLatestReleaseInformation();
    }

    private String getSalesforceOrgEndpoint () {

        String salesforceOrgEndpoint = '';

        RP_GitHub__mdt gitHubData;

        gitHubData = [SELECT
                        RP_GitHub_Salesforce_Org_Endpoint__c,
                        Label
                        FROM RP_Github__mdt
                        WHERE DeveloperName =: CUSTOM_METADATA_LAST_REPOSITORY_NAME
                        LIMIT 1
                      ];

        if (gitHubData != null) {

            salesforceOrgEndpoint = gitHubData.RP_GitHub_Salesforce_Org_Endpoint__c;
        }

        return salesforceOrgEndpoint;

    }

    private void updateGitHubLatestReleaseInformation() {

        String responseBody;
        RP_GitHubLatestReleaseClient client = new RP_GitHubLatestReleaseClient();
        String salesforceOrgEndpoint = getSalesforceOrgEndpoint();
        HttpResponse response = client.getSFORGInformation(salesforceOrgEndpoint);

        if (response != null) {

            responseBody = response.getBody();

            Map<String, Object> mapResponseBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            gitHubData = new GitHubWrapper(mapResponseBody);

        }

    }

    public class GitHubWrapper {

        public String latestDate {get; set;}
        public String latestDownloadUrl {get; set;}
        public Object latestVersion {get; set;}
        public String latestReleaseNotes {get; set;}
        public Object latestProductName {get; set;}


        public GitHubWrapper (Map<String, Object> mapResponseBody) {

            if (mapResponseBody != null) {

                Map<String, Object> mapLatestRelease = (Map<String, Object>) mapResponseBody.get('latest_release');
                latestProductName = mapResponseBody.get('product_name');

                if (mapLatestRelease != null) {

                    latestReleaseNotes = (String) mapLatestRelease.get('release_notes_html');
                    latestDownloadUrl = (String) mapLatestRelease.get('url');
                    latestVersion = (String) mapLatestRelease.get('version');

                    String timeCreated = (String) mapLatestRelease.get('time_created');
                    latestDate = formatDate (timeCreated);
                }

            }
        }

        private String formatDate (String releaseDate) {

            String result = '';

            if (releaseDate != null) {

                releaseDate = releaseDate.replaceAll('T', ' ');
                releaseDate = releaseDate.replaceAll('Z', '');

                Datetime releaseDatetime = Datetime.valueOf(releaseDate);

                result = releaseDatetime.format('dd/MM/YY @ hh:mm aa');
                result = result.toLowerCase();
            }

            return result;
        }

    }


}