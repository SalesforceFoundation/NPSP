// Import utility method
import { format } from 'c/utilCommon';

// Import custom labels
import commonAssistiveError from '@salesforce/label/c.commonAssistiveError';
import commonAssistiveInfo from '@salesforce/label/c.commonAssistiveInfo';
import commonAssistiveSuccess from '@salesforce/label/c.commonAssistiveSuccess';
import commonAssistiveWarning from '@salesforce/label/c.commonAssistiveWarning';
import commonBack from '@salesforce/label/c.commonBack';
import commonBatches from '@salesforce/label/c.commonBatches';
import commonCancel from '@salesforce/label/c.commonCancel';
import commonClone from '@salesforce/label/c.commonClone';
import commonDefaultValue from '@salesforce/label/c.commonDefaultValue';
import commonDelete from '@salesforce/label/c.commonDelete';
import commonEdit from '@salesforce/label/c.commonEdit';
import commonError from '@salesforce/label/c.commonError';
import commonFieldLabel from '@salesforce/label/c.commonFieldLabel';
import commonNewGift from '@salesforce/label/c.commonNewGift';
import commonNext from '@salesforce/label/c.commonNext';
import commonNo from '@salesforce/label/c.commonNo';
import commonNoItems from '@salesforce/label/c.commonNoItems';
import commonReadMore from '@salesforce/label/c.commonReadMore';
import commonRequired from '@salesforce/label/c.commonRequired';
import commonSave from '@salesforce/label/c.commonSave';
import commonSaveAndClose from '@salesforce/label/c.commonSaveAndClose';
import commonTemplate from '@salesforce/label/c.commonTemplate';
import commonTemplates from '@salesforce/label/c.commonTemplates';
import commonUnknownError from '@salesforce/label/c.commonUnknownError';
import commonUpdate from '@salesforce/label/c.commonUpdate';
import commonViewAll from '@salesforce/label/c.commonViewAll';
import commonViewMore from '@salesforce/label/c.commonViewMore';
import commonWarning from '@salesforce/label/c.commonWarning';
import commonYes from '@salesforce/label/c.commonYes';
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
import geBodyBatchDefaultValues from '@salesforce/label/c.geBodyBatchDefaultValues';
import geBodyBatchFieldBundleInfo from '@salesforce/label/c.geBodyBatchFieldBundleInfo';
import geBodyBatchHeaderLeftCol from '@salesforce/label/c.geBodyBatchHeaderLeftCol';
import geBodyBatchHeaderRightCol from '@salesforce/label/c.geBodyBatchHeaderRightCol';
import geBodyBatchHeaderWarning from '@salesforce/label/c.geBodyBatchHeaderWarning';
import geBodyEmptyFormSection from '@salesforce/label/c.geBodyEmptyFormSection';
import geBodyFormFieldsLeftCol from '@salesforce/label/c.geBodyFormFieldsLeftCol';
import geBodyFormFieldsLeftColAdditional from '@salesforce/label/c.geBodyFormFieldsLeftColAdditional';
import geBodyFormFieldsModalDeleteSection from '@salesforce/label/c.geBodyFormFieldsModalDeleteSection';
import geBodyFormFieldsRightCol from '@salesforce/label/c.geBodyFormFieldsRightCol';
import geBodyMatchingApplyNewPayment from '@salesforce/label/c.geBodyMatchingApplyNewPayment';
import geBodyMatchingNewOpportunity from '@salesforce/label/c.geBodyMatchingNewOpportunity';
import geBodyMatchingNoPayments from '@salesforce/label/c.geBodyMatchingNoPayments';
import geBodyMatchingPendingDonation from '@salesforce/label/c.geBodyMatchingPendingDonation';
import geBodyMatchingSelectRecord from '@salesforce/label/c.geBodyMatchingSelectRecord';
import geBodyMatchingUpdatingDonation from '@salesforce/label/c.geBodyMatchingUpdatingDonation';
import geBodyTemplateInfoLeftCol from '@salesforce/label/c.geBodyTemplateInfoLeftCol';
import geBodyTemplatesTabDescription from '@salesforce/label/c.geBodyTemplatesTabDescription';
import geButtonBuilderNavBackFormFields from '@salesforce/label/c.geButtonBuilderNavBackFormFields';
import geButtonBuilderNavBackTemplateInfo from '@salesforce/label/c.geButtonBuilderNavBackTemplateInfo';
import geButtonBuilderNavBatchHeader from '@salesforce/label/c.geButtonBuilderNavBatchHeader';
import geButtonBuilderNavFormFields from '@salesforce/label/c.geButtonBuilderNavFormFields';
import geButtonCancelAndClear from '@salesforce/label/c.geButtonCancelAndClear';
import geButtonFormFieldsAddSection from '@salesforce/label/c.geButtonFormFieldsAddSection';
import geButtonFormFieldsCollapseAll from '@salesforce/label/c.geButtonFormFieldsCollapseAll';
import geButtonFormFieldsExpandAll from '@salesforce/label/c.geButtonFormFieldsExpandAll';
import geButtonFormFieldsModalDeleteSectionAndFields from '@salesforce/label/c.geButtonFormFieldsModalDeleteSectionAndFields';
import geButtonMatchingNewOpportunity from '@salesforce/label/c.geButtonMatchingNewOpportunity';
import geButtonMatchingNewPayment from '@salesforce/label/c.geButtonMatchingNewPayment';
import geButtonMatchingReviewDonations from '@salesforce/label/c.geButtonMatchingReviewDonations';
import geButtonMatchingUpdateDonationSelection from '@salesforce/label/c.geButtonMatchingUpdateDonationSelection';
import geButtonMatchingUpdateOpportunity from '@salesforce/label/c.geButtonMatchingUpdateOpportunity';
import geButtonMatchingUpdatePayment from '@salesforce/label/c.geButtonMatchingUpdatePayment';
import geButtonNewBatch from '@salesforce/label/c.geButtonNewBatch';
import geButtonNewSingleGift from '@salesforce/label/c.geButtonNewSingleGift';
import geButtonSaveNewGift from '@salesforce/label/c.geButtonSaveNewGift';
import geButtonTemplatesTabCreateTemplate from '@salesforce/label/c.geButtonTemplatesTabCreateTemplate';
import geErrorAmountDoesNotMatch from '@salesforce/label/c.geErrorAmountDoesNotMatch';
import geErrorCompleteThisField from '@salesforce/label/c.geErrorCompleteThisField';
import geErrorDonorTypeInvalid from '@salesforce/label/c.geErrorDonorTypeInvalid';
import geErrorDonorTypeValidation from '@salesforce/label/c.geErrorDonorTypeValidation';
import geErrorDonorTypeValidationSingle from '@salesforce/label/c.geErrorDonorTypeValidationSingle';
import geErrorExistingTemplateName from '@salesforce/label/c.geErrorExistingTemplateName';
import geErrorFLSBody from '@salesforce/label/c.geErrorFLSBody';
import geErrorFLSHeader from '@salesforce/label/c.geErrorFLSHeader';
import geErrorFieldPermission from '@salesforce/label/c.geErrorFieldPermission';
import geErrorObjectCRUDBody from '@salesforce/label/c.geErrorObjectCRUDBody';
import geErrorObjectCRUDHeader from '@salesforce/label/c.geErrorObjectCRUDHeader';
import geErrorPageLevelAdvancedMappingBody from '@salesforce/label/c.geErrorPageLevelAdvancedMappingBody';
import geErrorPageLevelAdvancedMappingHeader from '@salesforce/label/c.geErrorPageLevelAdvancedMappingHeader';
import geErrorPageLevelFieldPermission1 from '@salesforce/label/c.geErrorPageLevelFieldPermission1';
import geErrorPageLevelFieldPermission2 from '@salesforce/label/c.geErrorPageLevelFieldPermission2';
import geErrorPageLevelMissingRequiredFields from '@salesforce/label/c.geErrorPageLevelMissingRequiredFields';
import geErrorPageLevelMissingRequiredGroupFields from '@salesforce/label/c.geErrorPageLevelMissingRequiredGroupFields';
import geErrorRequiredField from '@salesforce/label/c.geErrorRequiredField';
import geHeaderBatchEnterInfo from '@salesforce/label/c.geHeaderBatchEnterInfo';
import geHeaderBatchGiftEntry from '@salesforce/label/c.geHeaderBatchGiftEntry';
import geHeaderBatchHeaderLeftCol from '@salesforce/label/c.geHeaderBatchHeaderLeftCol';
import geHeaderBatchHeaderRightCol from '@salesforce/label/c.geHeaderBatchHeaderRightCol';
import geHeaderBatchSelectTemplate from '@salesforce/label/c.geHeaderBatchSelectTemplate';
import geHeaderBatchSetDefaultValues from '@salesforce/label/c.geHeaderBatchSetDefaultValues';
import geHeaderCustomTableHeaders from '@salesforce/label/c.geHeaderCustomTableHeaders';
import geHeaderEmptyFormSection from '@salesforce/label/c.geHeaderEmptyFormSection';
import geHeaderFormFieldsDefaultSectionName from '@salesforce/label/c.geHeaderFormFieldsDefaultSectionName';
import geHeaderFormFieldsLeftCol from '@salesforce/label/c.geHeaderFormFieldsLeftCol';
import geHeaderFormFieldsModalDeleteSection from '@salesforce/label/c.geHeaderFormFieldsModalDeleteSection';
import geHeaderFormFieldsModalRenameSection from '@salesforce/label/c.geHeaderFormFieldsModalRenameSection';
import geHeaderFormFieldsModalSectionSettings from '@salesforce/label/c.geHeaderFormFieldsModalSectionSettings';
import geHeaderFormFieldsRightCol from '@salesforce/label/c.geHeaderFormFieldsRightCol';
import geHeaderGiftEntry from '@salesforce/label/c.geHeaderGiftEntry';
import geHeaderMatchingGiftBy from '@salesforce/label/c.geHeaderMatchingGiftBy';
import geHeaderMatchingOpportunity from '@salesforce/label/c.geHeaderMatchingOpportunity';
import geHeaderMatchingPayment from '@salesforce/label/c.geHeaderMatchingPayment';
import geHeaderMatchingReviewDonations from '@salesforce/label/c.geHeaderMatchingReviewDonations';
import geHeaderNewSection from '@salesforce/label/c.geHeaderNewSection';
import geHeaderNewTemplate from '@salesforce/label/c.geHeaderNewTemplate';
import geHeaderPageLevelError from '@salesforce/label/c.geHeaderPageLevelError';
import geHeaderSingleGiftEntry from '@salesforce/label/c.geHeaderSingleGiftEntry';
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
import geSelectPlaceholder from '@salesforce/label/c.geSelectPlaceholder';
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
        commonBack,
        commonBatches,
        commonCancel,
        commonClone,
        commonDefaultValue,
        commonDelete,
        commonEdit,
        commonError,
        commonFieldLabel,
        commonNewGift,
        commonNext,
        commonNo,
        commonNoItems,
        commonReadMore,
        commonRequired,
        commonSave,
        commonSaveAndClose,
        commonTemplate,
        commonTemplates,
        commonUnknownError,
        commonUpdate,
        commonViewAll,
        commonViewMore,
        commonWarning,
        commonYes,
        geAssistiveActiveSection,
        geAssistiveBatchHeaderRemoveField,
        geAssistiveFieldDown,
        geAssistiveFieldUp,
        geAssistiveFormFieldsCollapseAll,
        geAssistiveFormFieldsExpandAll,
        geAssistiveFormFieldsRemoveField,
        geAssistiveFormFieldsSectionEdit,
        geAssistiveModalCancelAndDiscard,
        geAssistiveRemoveSelectedOption,
        geAssistiveSectionDown,
        geAssistiveSectionUp,
        geAssistiveShowMenu,
        geAssistiveSpinner,
        geBodyBatchDefaultValues,
        geBodyBatchFieldBundleInfo,
        geBodyBatchHeaderLeftCol,
        geBodyBatchHeaderRightCol,
        geBodyBatchHeaderWarning,
        geBodyEmptyFormSection,
        geBodyFormFieldsLeftCol,
        geBodyFormFieldsLeftColAdditional,
        geBodyFormFieldsModalDeleteSection,
        geBodyFormFieldsRightCol,
        geBodyMatchingApplyNewPayment,
        geBodyMatchingNewOpportunity,
        geBodyMatchingNoPayments,
        geBodyMatchingPendingDonation,
        geBodyMatchingSelectRecord,
        geBodyMatchingUpdatingDonation,
        geBodyTemplateInfoLeftCol,
        geBodyTemplatesTabDescription,
        geButtonBuilderNavBackFormFields,
        geButtonBuilderNavBackTemplateInfo,
        geButtonBuilderNavBatchHeader,
        geButtonBuilderNavFormFields,
        geButtonCancelAndClear,
        geButtonFormFieldsAddSection,
        geButtonFormFieldsCollapseAll,
        geButtonFormFieldsExpandAll,
        geButtonFormFieldsModalDeleteSectionAndFields,
        geButtonMatchingNewOpportunity,
        geButtonMatchingNewPayment,
        geButtonMatchingReviewDonations,
        geButtonMatchingUpdateDonationSelection,
        geButtonMatchingUpdateOpportunity,
        geButtonMatchingUpdatePayment,
        geButtonNewBatch,
        geButtonNewSingleGift,
        geButtonSaveNewGift,
        geButtonTemplatesTabCreateTemplate,
        geErrorAmountDoesNotMatch,
        geErrorCompleteThisField,
        geErrorDonorTypeInvalid,
        geErrorDonorTypeValidation,
        geErrorDonorTypeValidationSingle,
        geErrorExistingTemplateName,
        geErrorFLSBody,
        geErrorFLSHeader,
        geErrorFieldPermission,
        geErrorObjectCRUDBody,
        geErrorObjectCRUDHeader,
        geErrorPageLevelAdvancedMappingBody,
        geErrorPageLevelAdvancedMappingHeader,
        geErrorPageLevelFieldPermission1,
        geErrorPageLevelFieldPermission2,
        geErrorPageLevelMissingRequiredFields,
        geErrorPageLevelMissingRequiredGroupFields,
        geErrorRequiredField,
        geHeaderBatchEnterInfo,
        geHeaderBatchGiftEntry,
        geHeaderBatchHeaderLeftCol,
        geHeaderBatchHeaderRightCol,
        geHeaderBatchSelectTemplate,
        geHeaderBatchSetDefaultValues,
        geHeaderCustomTableHeaders,
        geHeaderEmptyFormSection,
        geHeaderFormFieldsDefaultSectionName,
        geHeaderFormFieldsLeftCol,
        geHeaderFormFieldsModalDeleteSection,
        geHeaderFormFieldsModalRenameSection,
        geHeaderFormFieldsModalSectionSettings,
        geHeaderFormFieldsRightCol,
        geHeaderGiftEntry,
        geHeaderMatchingGiftBy,
        geHeaderMatchingOpportunity,
        geHeaderMatchingPayment,
        geHeaderMatchingReviewDonations,
        geHeaderNewSection,
        geHeaderNewTemplate,
        geHeaderPageLevelError,
        geHeaderSingleGiftEntry,
        geHeaderTemplateInfoLeftCol,
        geHelpTextBatchHeaderFieldLabelLabel,
        geHelpTextFormFieldsFieldCustomLabel,
        geHelpTextFormFieldsFieldLabelLabel,
        geLabelCustomTableSelectedFields,
        geLabelCustomTableSourceFields,
        geLabelSectionName,
        geLabelTemplateInfoDescriptionField,
        geLabelTemplateInfoNameField,
        geSearchPlaceholder,
        geSelectPlaceholder,
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