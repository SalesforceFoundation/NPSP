/*
 * Copyright (c) 2020 Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */
import { LightningElement } from 'lwc';
import { buildErrorMessage } from 'c/utilTemplateBuilder';
import { isEmpty } from 'c/utilCommon';

import messageLoading from '@salesforce/label/c.labelMessageLoading';
import insufficientPermissions from '@salesforce/label/c.commonInsufficientPermissions';
import commonAdminPermissionErrorMessage from '@salesforce/label/c.commonAdminPermissionErrorMessage';

import setGatewayId from '@salesforce/apex/PS_GatewayManagement.setGatewayId';
import getGatewayIdFromConfig from '@salesforce/apex/PS_GatewayManagement.getGatewayIdFromConfig';
import checkForElevateCustomer from '@salesforce/apex/PS_GatewayManagement.isElevateCustomer';
import checkForSystemAdmin from '@salesforce/apex/PS_GatewayManagement.isSystemAdmin';

export default class GePaymentGatewayManagement extends LightningElement {

    showSpinner;
    gatewayId;

    isReadOnly = true;
    errorMessage;

    isElevateCustomer;
    isSystemAdmin;
    hasAccess;

    CUSTOM_LABELS = { messageLoading, insufficientPermissions, commonAdminPermissionErrorMessage };

    async connectedCallback() {
        try {
            this.isSystemAdmin = await checkForSystemAdmin();
            this.isElevateCustomer = await checkForElevateCustomer();

            this.hasAccess = !!(this.isElevateCustomer && this.isSystemAdmin);
        } catch(ex) {
            this.errorMessage = buildErrorMessage(ex);
            this.isError = true;
        }

        if (this.hasAccess) {
            this.gatewayId = await getGatewayIdFromConfig();
        }
    }

    _isSuccess;
    get isSuccess() {
        return this._isSuccess;
    }
    set isSuccess(value) {
        this._isSuccess = value;

        if (value) { this.isError = false; }
    }

    _isError;
    get isError() {
        return this._isError;
    }
    set isError(value) {
        this._isError = value;

        if (value) { this.isSuccess = false; }
    }

    get noAccessErrorMessage() {
        if (!this.isSystemAdmin) {
            return this.CUSTOM_LABELS.commonAdminPermissionErrorMessage
        }
        // Temporary Hardcoded Text until this functionality is moved out of NPSP entirely
        if (!this.isElevateCustomer) {
            return 'You must be an Elevate customer to use this setting.';
        }
    }

    handleEdit() {
        this.isReadOnly = false;
    }

    handleCancel() {
        this.template.querySelector("[data-id='gatewayIdField']").value = this.gatewayId;
        this.resetAlert();
        this.clearFieldErrors();

        this.isReadOnly = true;
    }

    async handleSave(event) {
        this.resetAlert();

        let gatewayId = this.validateGatewayId();

        if (isEmpty(gatewayId)) {
            return;
        }

        this.showSpinner = true;

        try {

            await setGatewayId({ gatewayId: gatewayId});

            this.isReadOnly = true;
            this.isSuccess = true;
            this.showSpinner = false;
        } catch(ex) {
            this.errorMessage = buildErrorMessage(ex);
            this.showSpinner = false;
            this.isError = true;
        }
    }

    validateGatewayId() {
        // Temporary Hardcoded Text until this functionality is moved out of NPSP entirely

        let gatewayIdField = this.template.querySelector("[data-id='gatewayIdField']");

        if (isEmpty(gatewayIdField.value)) {

            gatewayIdField.setCustomValidity('Invalid Gateway ID.');
            gatewayIdField.reportValidity();


            this.errorMessage = 'Enter a valid gateway ID.'
            this.isError = true;
        } else {
            this.clearFieldErrors();

            return gatewayIdField.value;
        }
    }

    clearFieldErrors() {
        let gatewayIdField = this.template.querySelector("[data-id='gatewayIdField']");
        if (!gatewayIdField.valid) {
            gatewayIdField.setCustomValidity('');
            gatewayIdField.reportValidity();
        }
    }

    resetAlert() {
        this.isSuccess = null;
        this.isError = null;
    }
}
