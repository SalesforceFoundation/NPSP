/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group API
* @description Class that dispatches to external package APIs
*/
public with sharing class UTIL_IntegrationGateway {
    @TestVisible
    private static final String ACTION_HANDLE_BEFORE_DELETE = 'dso.handleBeforeDelete';

    @TestVisible
    private static final String PARAM_TRIGGER_OLD = 'TriggerOld';

    @TestVisible
    private UTIL_IntegrationConfig archiveBridgeConfig {
        get {
            if (archiveBridgeConfig == null) {
                archiveBridgeConfig = UTIL_IntegrationConfig.getConfig(UTIL_IntegrationConfig.Integration.ArchiveBridge);
            }
            return archiveBridgeConfig;
        }
        set;
    }

    private List<UTIL_IntegrationConfig> listeners {
        get {
            if (listeners == null) {
                listeners = new List<UTIL_IntegrationConfig>{
                    archiveBridgeConfig
                };
            }
            return listeners;
        }
        set;
    }

    /*******************************************************************************************************
     * @description Passes trigger records to listener integrations
     * @param triggerOld records that were passed to the trigger as trigger.old
     */
    public void handleBeforeDelete(List<SObject> triggerOld) {
        Map<String, Object> params = new Map<String, Object> {
            PARAM_TRIGGER_OLD => triggerOld
        };

        for (UTIL_IntegrationConfig listener : listeners) {
            if (listener.isInstalled()) {
                listener.getCallableApi().call(ACTION_HANDLE_BEFORE_DELETE, params);
            }
        }
    }
}