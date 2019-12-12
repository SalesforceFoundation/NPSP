// Import custom labels
import commonAssistiveError from '@salesforce/label/c.commonAssistiveError';
import commonAssistiveInfo from '@salesforce/label/c.commonAssistiveInfo';
import commonAssistiveSuccess from '@salesforce/label/c.commonAssistiveSuccess';
import commonAssistiveWarning from '@salesforce/label/c.commonAssistiveWarning';
import commonCancel from '@salesforce/label/c.commonCancel';
import commonDefaultValue from '@salesforce/label/c.commonDefaultValue';
import commonError from '@salesforce/label/c.commonError';
import commonFieldLabel from '@salesforce/label/c.commonFieldLabel';
import commonReadMore from '@salesforce/label/c.commonReadMore';
import commonRequired from '@salesforce/label/c.commonRequired';
import commonSave from '@salesforce/label/c.commonSave';
import commonSaveAndClose from '@salesforce/label/c.commonSaveAndClose';
import commonWarning from '@salesforce/label/c.commonWarning';
import geAssistiveActiveSection from '@salesforce/label/c.geAssistiveActiveSection';
import geAssistiveBatchHeaderRemoveField from '@salesforce/label/c.geAssistiveBatchHeaderRemoveField';
import geAssistiveFieldDown from '@salesforce/label/c.geAssistiveFieldDown';
import geAssistiveFieldUp from '@salesforce/label/c.geAssistiveFieldUp';
import geAssistiveFormFieldsCollapseAll from '@salesforce/label/c.geAssistiveFormFieldsCollapseAll';
import geAssistiveFormFieldsExpandAll from '@salesforce/label/c.geAssistiveFormFieldsExpandAll';
import geAssistiveFormFieldsRemoveField from '@salesforce/label/c.geAssistiveFormFieldsRemoveField';
import geAssistiveFormFieldsSectionEdit from '@salesforce/label/c.geAssistiveFormFieldsSectionEdit';
import geAssistiveModalCancelAndDiscard from '@salesforce/label/c.geAssistiveModalCancelAndDiscard';
import geAssistiveSectionDown from '@salesforce/label/c.geAssistiveSectionDown';
import geAssistiveSectionUp from '@salesforce/label/c.geAssistiveSectionUp';
import geAssistiveSpinner from '@salesforce/label/c.geAssistiveSpinner';
import geBodyBatchHeaderLeftCol from '@salesforce/label/c.geBodyBatchHeaderLeftCol';
import geBodyBatchHeaderRightCol from '@salesforce/label/c.geBodyBatchHeaderRightCol';
import geBodyBatchHeaderWarning from '@salesforce/label/c.geBodyBatchHeaderWarning';
import geBodyEmptyFormSection from '@salesforce/label/c.geBodyEmptyFormSection';
import geBodyFormFieldsLeftCol from '@salesforce/label/c.geBodyFormFieldsLeftCol';
import geBodyFormFieldsLeftColAdditional from '@salesforce/label/c.geBodyFormFieldsLeftColAdditional';
import geBodyFormFieldsModalDeleteSection from '@salesforce/label/c.geBodyFormFieldsModalDeleteSection';
import geBodyFormFieldsRightCol from '@salesforce/label/c.geBodyFormFieldsRightCol';
import geBodyTemplateInfoLeftCol from '@salesforce/label/c.geBodyTemplateInfoLeftCol';
import geButtonBuilderNavBackFormFields from '@salesforce/label/c.geButtonBuilderNavBackFormFields';
import geButtonBuilderNavBackTemplateInfo from '@salesforce/label/c.geButtonBuilderNavBackTemplateInfo';
import geButtonBuilderNavBatchHeader from '@salesforce/label/c.geButtonBuilderNavBatchHeader';
import geButtonBuilderNavFormFields from '@salesforce/label/c.geButtonBuilderNavFormFields';
import geButtonFormFieldsAddSection from '@salesforce/label/c.geButtonFormFieldsAddSection';
import geButtonFormFieldsCollapseAll from '@salesforce/label/c.geButtonFormFieldsCollapseAll';
import geButtonFormFieldsExpandAll from '@salesforce/label/c.geButtonFormFieldsExpandAll';
import geButtonFormFieldsModalDeleteSectionAndFields from '@salesforce/label/c.geButtonFormFieldsModalDeleteSectionAndFields';
import geErrorExistingTemplateName from '@salesforce/label/c.geErrorExistingTemplateName';
import geErrorFieldPermission from '@salesforce/label/c.geErrorFieldPermission';
import geErrorPageLevelAdvancedMappingBody from '@salesforce/label/c.geErrorPageLevelAdvancedMappingBody';
import geErrorPageLevelAdvancedMappingHeader from '@salesforce/label/c.geErrorPageLevelAdvancedMappingHeader';
import geErrorPageLevelFieldPermission1 from '@salesforce/label/c.geErrorPageLevelFieldPermission1';
import geErrorPageLevelFieldPermission2 from '@salesforce/label/c.geErrorPageLevelFieldPermission2';
import geErrorPageLevelMissingRequiredFields from '@salesforce/label/c.geErrorPageLevelMissingRequiredFields';
import geErrorRequiredField from '@salesforce/label/c.geErrorRequiredField';
import geHeaderBatchHeaderLeftCol from '@salesforce/label/c.geHeaderBatchHeaderLeftCol';
import geHeaderBatchHeaderRightCol from '@salesforce/label/c.geHeaderBatchHeaderRightCol';
import geHeaderEmptyFormSection from '@salesforce/label/c.geHeaderEmptyFormSection';
import geHeaderFormFieldsDefaultSectionName from '@salesforce/label/c.geHeaderFormFieldsDefaultSectionName';
import geHeaderFormFieldsLeftCol from '@salesforce/label/c.geHeaderFormFieldsLeftCol';
import geHeaderFormFieldsModalDeleteSection from '@salesforce/label/c.geHeaderFormFieldsModalDeleteSection';
import geHeaderFormFieldsModalRenameSection from '@salesforce/label/c.geHeaderFormFieldsModalRenameSection';
import geHeaderFormFieldsModalSectionSettings from '@salesforce/label/c.geHeaderFormFieldsModalSectionSettings';
import geHeaderFormFieldsRightCol from '@salesforce/label/c.geHeaderFormFieldsRightCol';
import geHeaderNewSection from '@salesforce/label/c.geHeaderNewSection';
import geHeaderNewTemplate from '@salesforce/label/c.geHeaderNewTemplate';
import geHeaderPageLevelError from '@salesforce/label/c.geHeaderPageLevelError';
import geHeaderTemplateInfoLeftCol from '@salesforce/label/c.geHeaderTemplateInfoLeftCol';
import geHelpTextBatchHeaderFieldLabelLabel from '@salesforce/label/c.geHelpTextBatchHeaderFieldLabelLabel';
import geHelpTextFormFieldsFieldCustomLabel from '@salesforce/label/c.geHelpTextFormFieldsFieldCustomLabel';
import geHelpTextFormFieldsFieldLabelLabel from '@salesforce/label/c.geHelpTextFormFieldsFieldLabelLabel';
import geLabelSectionName from '@salesforce/label/c.geLabelSectionName';
import geLabelTemplateInfoDescriptionField from '@salesforce/label/c.geLabelTemplateInfoDescriptionField';
import geLabelTemplateInfoNameField from '@salesforce/label/c.geLabelTemplateInfoNameField';
import geTabBatchHeader from '@salesforce/label/c.geTabBatchHeader';
import geTabFormFields from '@salesforce/label/c.geTabFormFields';
import geTabTemplateInfo from '@salesforce/label/c.geTabTemplateInfo';
import geToastSaveFailed from '@salesforce/label/c.geToastSaveFailed';
import geToastSelectActiveSection from '@salesforce/label/c.geToastSelectActiveSection';
import geToastTemplateCreateSuccess from '@salesforce/label/c.geToastTemplateCreateSuccess';
import geToastTemplateTabError from '@salesforce/label/c.geToastTemplateTabError';
import geToastTemplateTabsError from '@salesforce/label/c.geToastTemplateTabsError';
import geToastTemplateUpdateSuccess from '@salesforce/label/c.geToastTemplateUpdateSuccess';
import geWarningFormFieldsModalDeleteSection from '@salesforce/label/c.geWarningFormFieldsModalDeleteSection';

class GeLabelService {
    /*******************************************************************************
    * @description Expose imported custom labels.
    */
    CUSTOM_LABELS = {
        commonAssistiveError,
        commonAssistiveInfo,
        commonAssistiveSuccess,
        commonAssistiveWarning,
        commonCancel,
        commonDefaultValue,
        commonError,
        commonFieldLabel,
        commonReadMore,
        commonRequired,
        commonSave,
        commonSaveAndClose,
        commonWarning,
        geAssistiveActiveSection,
        geAssistiveBatchHeaderRemoveField,
        geAssistiveFieldDown,
        geAssistiveFieldUp,
        geAssistiveFormFieldsCollapseAll,
        geAssistiveFormFieldsExpandAll,
        geAssistiveFormFieldsRemoveField,
        geAssistiveFormFieldsSectionEdit,
        geAssistiveModalCancelAndDiscard,
        geAssistiveSectionDown,
        geAssistiveSectionUp,
        geAssistiveSpinner,
        geBodyBatchHeaderLeftCol,
        geBodyBatchHeaderRightCol,
        geBodyBatchHeaderWarning,
        geBodyEmptyFormSection,
        geBodyFormFieldsLeftCol,
        geBodyFormFieldsLeftColAdditional,
        geBodyFormFieldsModalDeleteSection,
        geBodyFormFieldsRightCol,
        geBodyTemplateInfoLeftCol,
        geButtonBuilderNavBackFormFields,
        geButtonBuilderNavBackTemplateInfo,
        geButtonBuilderNavBatchHeader,
        geButtonBuilderNavFormFields,
        geButtonFormFieldsAddSection,
        geButtonFormFieldsCollapseAll,
        geButtonFormFieldsExpandAll,
        geButtonFormFieldsModalDeleteSectionAndFields,
        geErrorExistingTemplateName,
        geErrorFieldPermission,
        geErrorPageLevelAdvancedMappingBody,
        geErrorPageLevelAdvancedMappingHeader,
        geErrorPageLevelFieldPermission1,
        geErrorPageLevelFieldPermission2,
        geErrorPageLevelMissingRequiredFields,
        geErrorRequiredField,
        geHeaderBatchHeaderLeftCol,
        geHeaderBatchHeaderRightCol,
        geHeaderEmptyFormSection,
        geHeaderFormFieldsDefaultSectionName,
        geHeaderFormFieldsLeftCol,
        geHeaderFormFieldsModalDeleteSection,
        geHeaderFormFieldsModalRenameSection,
        geHeaderFormFieldsModalSectionSettings,
        geHeaderFormFieldsRightCol,
        geHeaderNewSection,
        geHeaderNewTemplate,
        geHeaderPageLevelError,
        geHeaderTemplateInfoLeftCol,
        geHelpTextBatchHeaderFieldLabelLabel,
        geHelpTextFormFieldsFieldCustomLabel,
        geHelpTextFormFieldsFieldLabelLabel,
        geLabelSectionName,
        geLabelTemplateInfoDescriptionField,
        geLabelTemplateInfoNameField,
        geTabBatchHeader,
        geTabFormFields,
        geTabTemplateInfo,
        geToastSaveFailed,
        geToastSelectActiveSection,
        geToastTemplateCreateSuccess,
        geToastTemplateTabError,
        geToastTemplateTabsError,
        geToastTemplateUpdateSuccess,
        geWarningFormFieldsModalDeleteSection,
    }

    /*******************************************************************************
    * @description Javascript method comparable to Apex's String.format(...).
    * Replaces placeholders in Custom Labels ({0}, {1}, etc) with provided values.
    *
    * @param {string} string: Custom Label to be formatted.
    * @param {list} replacements: List of string to use as replacements.
    * @return {string} formattedString: Formatted custom label
    */
    format = (string, replacements) => {
        const isNull = string === null || string === undefined;
        let formattedString = isNull ? '' : string;
        if (replacements) {
            let key;
            const type = typeof replacements;
            const args =
                'string' === type || 'number' === type
                    ? Array.prototype.slice.call(replacements)
                    : replacements;
            for (key in args) {
                if (args.hasOwnProperty(key)) {
                    formattedString = formattedString.replace(
                        new RegExp('\\{' + key + '\\}', 'gi'),
                        args[key]
                    );
                }
            }
        }

        return formattedString;
    };
}

export default new GeLabelService();