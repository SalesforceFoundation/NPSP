// Import utility method
import { format } from 'c/utilCommon';

// Import custom labels
import commonAssistiveError from '@salesforce/label/c.commonAssistiveError';
import commonAssistiveInfo from '@salesforce/label/c.commonAssistiveInfo';
import commonAssistiveSuccess from '@salesforce/label/c.commonAssistiveSuccess';
import commonAssistiveWarning from '@salesforce/label/c.commonAssistiveWarning';
import commonBatches from '@salesforce/label/c.commonBatches';
import commonCancel from '@salesforce/label/c.commonCancel';
import commonClone from '@salesforce/label/c.commonClone';
import commonDefaultValue from '@salesforce/label/c.commonDefaultValue';
import commonDelete from '@salesforce/label/c.commonDelete';
import commonEdit from '@salesforce/label/c.commonEdit';
import commonError from '@salesforce/label/c.commonError';
import commonFieldLabel from '@salesforce/label/c.commonFieldLabel';
import commonNoItems from '@salesforce/label/c.commonNoItems';
import commonReadMore from '@salesforce/label/c.commonReadMore';
import commonRequired from '@salesforce/label/c.commonRequired';
import commonSave from '@salesforce/label/c.commonSave';
import commonSaveAndClose from '@salesforce/label/c.commonSaveAndClose';
import commonTemplates from '@salesforce/label/c.commonTemplates';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';
import commonViewAll from '@salesforce/label/c.commonViewAll';
import commonViewMore from '@salesforce/label/c.commonViewMore';
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
import geAssistiveRemoveSelectedOption from '@salesforce/label/c.geAssistiveRemoveSelectedOption';
import geAssistiveSectionDown from '@salesforce/label/c.geAssistiveSectionDown';
import geAssistiveSectionUp from '@salesforce/label/c.geAssistiveSectionUp';
import geAssistiveShowMenu from '@salesforce/label/c.geAssistiveShowMenu';
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
import geBodyTemplatesTabDescription from '@salesforce/label/c.geBodyTemplatesTabDescription';
import geButtonBuilderNavBackFormFields from '@salesforce/label/c.geButtonBuilderNavBackFormFields';
import geButtonBuilderNavBackTemplateInfo from '@salesforce/label/c.geButtonBuilderNavBackTemplateInfo';
import geButtonBuilderNavBatchHeader from '@salesforce/label/c.geButtonBuilderNavBatchHeader';
import geButtonBuilderNavFormFields from '@salesforce/label/c.geButtonBuilderNavFormFields';
import geButtonEnterGifts from '@salesforce/label/c.geButtonEnterGifts';
import geButtonFormFieldsAddSection from '@salesforce/label/c.geButtonFormFieldsAddSection';
import geButtonFormFieldsCollapseAll from '@salesforce/label/c.geButtonFormFieldsCollapseAll';
import geButtonFormFieldsExpandAll from '@salesforce/label/c.geButtonFormFieldsExpandAll';
import geButtonFormFieldsModalDeleteSectionAndFields from '@salesforce/label/c.geButtonFormFieldsModalDeleteSectionAndFields';
import geButtonTemplatesTabCreateTemplate from '@salesforce/label/c.geButtonTemplatesTabCreateTemplate';
import geErrorCompleteThisField from '@salesforce/label/c.geErrorCompleteThisField';
import geErrorExistingTemplateName from '@salesforce/label/c.geErrorExistingTemplateName';
import geErrorFieldPermission from '@salesforce/label/c.geErrorFieldPermission';
import geErrorPageLevelAdvancedMappingBody from '@salesforce/label/c.geErrorPageLevelAdvancedMappingBody';
import geErrorPageLevelAdvancedMappingHeader from '@salesforce/label/c.geErrorPageLevelAdvancedMappingHeader';
import geErrorPageLevelFieldPermission1 from '@salesforce/label/c.geErrorPageLevelFieldPermission1';
import geErrorPageLevelFieldPermission2 from '@salesforce/label/c.geErrorPageLevelFieldPermission2';
import geErrorPageLevelMissingRequiredFields from '@salesforce/label/c.geErrorPageLevelMissingRequiredFields';
import geErrorPageLevelMissingRequiredGroupFields from '@salesforce/label/c.geErrorPageLevelMissingRequiredGroupFields';
import geErrorRequiredField from '@salesforce/label/c.geErrorRequiredField';
import geHeaderBatchHeaderLeftCol from '@salesforce/label/c.geHeaderBatchHeaderLeftCol';
import geHeaderBatchHeaderRightCol from '@salesforce/label/c.geHeaderBatchHeaderRightCol';
import geHeaderCustomTableHeaders from '@salesforce/label/c.geHeaderCustomTableHeaders';
import geHeaderEmptyFormSection from '@salesforce/label/c.geHeaderEmptyFormSection';
import geHeaderFormFieldsDefaultSectionName from '@salesforce/label/c.geHeaderFormFieldsDefaultSectionName';
import geHeaderFormFieldsLeftCol from '@salesforce/label/c.geHeaderFormFieldsLeftCol';
import geHeaderFormFieldsModalDeleteSection from '@salesforce/label/c.geHeaderFormFieldsModalDeleteSection';
import geHeaderFormFieldsModalRenameSection from '@salesforce/label/c.geHeaderFormFieldsModalRenameSection';
import geHeaderFormFieldsModalSectionSettings from '@salesforce/label/c.geHeaderFormFieldsModalSectionSettings';
import geHeaderFormFieldsRightCol from '@salesforce/label/c.geHeaderFormFieldsRightCol';
import geHeaderGiftEntry from '@salesforce/label/c.geHeaderGiftEntry';
import geHeaderNewSection from '@salesforce/label/c.geHeaderNewSection';
import geHeaderNewTemplate from '@salesforce/label/c.geHeaderNewTemplate';
import geHeaderPageLevelError from '@salesforce/label/c.geHeaderPageLevelError';
import geHeaderTemplateInfoLeftCol from '@salesforce/label/c.geHeaderTemplateInfoLeftCol';
import geHelpTextBatchHeaderFieldLabelLabel from '@salesforce/label/c.geHelpTextBatchHeaderFieldLabelLabel';
import geHelpTextFormFieldsFieldCustomLabel from '@salesforce/label/c.geHelpTextFormFieldsFieldCustomLabel';
import geHelpTextFormFieldsFieldLabelLabel from '@salesforce/label/c.geHelpTextFormFieldsFieldLabelLabel';
import geLabelCustomTableSelectedFields from '@salesforce/label/c.geLabelCustomTableSelectedFields';
import geLabelCustomTableSourceFields from '@salesforce/label/c.geLabelCustomTableSourceFields';
import geLabelSectionName from '@salesforce/label/c.geLabelSectionName';
import geLabelTemplateInfoDescriptionField from '@salesforce/label/c.geLabelTemplateInfoDescriptionField';
import geLabelTemplateInfoNameField from '@salesforce/label/c.geLabelTemplateInfoNameField';
import geSearchPlaceholder from '@salesforce/label/c.geSearchPlaceholder';
import geTabBatchHeader from '@salesforce/label/c.geTabBatchHeader';
import geTabFormFields from '@salesforce/label/c.geTabFormFields';
import geTabTemplateInfo from '@salesforce/label/c.geTabTemplateInfo';
import geTextListViewItemCount from '@salesforce/label/c.geTextListViewItemCount';
import geTextListViewItemsCount from '@salesforce/label/c.geTextListViewItemsCount';
import geTextListViewSortedBy from '@salesforce/label/c.geTextListViewSortedBy';
import geTextListViewUpdatedAgo from '@salesforce/label/c.geTextListViewUpdatedAgo';
import geToastListViewUpdated from '@salesforce/label/c.geToastListViewUpdated';
import geToastSaveFailed from '@salesforce/label/c.geToastSaveFailed';
import geToastSelectActiveSection from '@salesforce/label/c.geToastSelectActiveSection';
import geToastTemplateCreateSuccess from '@salesforce/label/c.geToastTemplateCreateSuccess';
import geToastTemplateDeleteSuccess from '@salesforce/label/c.geToastTemplateDeleteSuccess';
import geToastTemplateTabError from '@salesforce/label/c.geToastTemplateTabError';
import geToastTemplateTabsError from '@salesforce/label/c.geToastTemplateTabsError';
import geToastTemplateUpdateSuccess from '@salesforce/label/c.geToastTemplateUpdateSuccess';
import geWarningFormFieldsModalDeleteSection from '@salesforce/label/c.geWarningFormFieldsModalDeleteSection';

class GeLabelService {

    /*******************************************************************************
    * @description Expose imported custom labels. We freeze this object because any
    * import of this service component within the same session is shared across
    * components. We disallow mutations of labels at this level. Components importing
    * the provided labels must clone in order to mutate/format the labels. A 'format'
    * utility method is provided.
    */
    CUSTOM_LABELS = Object.freeze({
        commonAssistiveError,
        commonAssistiveInfo,
        commonAssistiveSuccess,
        commonAssistiveWarning,
        commonBatches,
        commonCancel,
        commonClone,
        commonDefaultValue,
        commonDelete,
        commonEdit,
        commonError,
        commonFieldLabel,
        commonNoItems,
        commonReadMore,
        commonRequired,
        commonSave,
        commonSaveAndClose,
        commonTemplates,
        commonUnknownError,
        commonViewAll,
        commonViewMore,
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
        geAssistiveShowMenu,
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
        geBodyTemplatesTabDescription,
        geButtonBuilderNavBackFormFields,
        geButtonBuilderNavBackTemplateInfo,
        geButtonBuilderNavBatchHeader,
        geButtonBuilderNavFormFields,
        geButtonEnterGifts,
        geButtonFormFieldsAddSection,
        geButtonFormFieldsCollapseAll,
        geButtonFormFieldsExpandAll,
        geButtonFormFieldsModalDeleteSectionAndFields,
        geButtonTemplatesTabCreateTemplate,
        geErrorCompleteThisField,
        geErrorExistingTemplateName,
        geErrorFieldPermission,
        geErrorPageLevelAdvancedMappingBody,
        geErrorPageLevelAdvancedMappingHeader,
        geErrorPageLevelFieldPermission1,
        geErrorPageLevelFieldPermission2,
        geErrorPageLevelMissingRequiredFields,
        geErrorPageLevelMissingRequiredGroupFields,
        geErrorRequiredField,
        geHeaderBatchHeaderLeftCol,
        geHeaderBatchHeaderRightCol,
        geHeaderCustomTableHeaders,
        geHeaderEmptyFormSection,
        geHeaderFormFieldsDefaultSectionName,
        geHeaderFormFieldsLeftCol,
        geHeaderFormFieldsModalDeleteSection,
        geHeaderFormFieldsModalRenameSection,
        geHeaderFormFieldsModalSectionSettings,
        geHeaderFormFieldsRightCol,
        geHeaderGiftEntry,
        geHeaderNewSection,
        geHeaderNewTemplate,
        geHeaderPageLevelError,
        geHeaderTemplateInfoLeftCol,
        geHelpTextBatchHeaderFieldLabelLabel,
        geHelpTextFormFieldsFieldCustomLabel,
        geHelpTextFormFieldsFieldLabelLabel,
        geLabelCustomTableSelectedFields,
        geLabelCustomTableSourceFields,
        geLabelSectionName,
        geLabelTemplateInfoDescriptionField,
        geLabelTemplateInfoNameField,
        geAssistiveRemoveSelectedOption,
        geSearchPlaceholder,
        geTabBatchHeader,
        geTabFormFields,
        geTabTemplateInfo,
        geTextListViewItemCount,
        geTextListViewItemsCount,
        geTextListViewSortedBy,
        geTextListViewUpdatedAgo,
        geToastListViewUpdated,
        geToastSaveFailed,
        geToastSelectActiveSection,
        geToastTemplateCreateSuccess,
        geToastTemplateDeleteSuccess,
        geToastTemplateTabError,
        geToastTemplateTabsError,
        geToastTemplateUpdateSuccess,
        geWarningFormFieldsModalDeleteSection,
    });

    /*******************************************************************************
    * @description Pass through method for imported 'format' utility method.
    * Javascript method comparable to Apex's String.format(...).
    * Replaces placeholders in Custom Labels ({0}, {1}, etc) with provided values.
    *
    * @param {string} string: Custom Label to be formatted.
    * @param {list} replacements: List of string to use as replacements.
    * @return {string} formattedString: Formatted custom label
    */
    format = (string, replacements) => format(string, replacements);
}

export default new GeLabelService();