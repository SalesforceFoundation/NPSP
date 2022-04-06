import { constructErrorMessage } from "c/utilCommon";
import commonUnknownError from "@salesforce/label/c.commonUnknownError";

describe("utilCommon", () => {
    describe("constructErrorMessage", () => {
        it("processes a single error in a saveResult without fields", () => {
            const saveResult = {
                success: false,
                errors: [
                    {
                        message: "Invalid endpoint.",
                        fields: [],
                    },
                ],
            };
            const errorInfo = constructErrorMessage(saveResult);
            expect(errorInfo).toMatchObject({ detail: "Invalid endpoint.", header: commonUnknownError });
        });

        it("processes multiple errors in a saveResult without fields", () => {
            const saveResult = {
                success: false,
                errors: [
                    {
                        message: "Amount must be greater than 1",
                        fields: [],
                    },
                    {
                        message: "Recurring period must not be 1st and 15th",
                        fields: [],
                    },
                ],
            };
            const errorInfo = constructErrorMessage(saveResult);
            expect(errorInfo).toMatchObject({
                detail: "Amount must be greater than 1, Recurring period must not be 1st and 15th",
                header: commonUnknownError,
            });
        });

        it("processes multiple errors in a saveResult with fields", () => {
            const saveResult = {
                success: false,
                errors: [
                    {
                        message: "Amount must be greater than 1",
                        fields: ["npe03__Amount__c"],
                    },
                    {
                        message: "Recurring period must not be 1st and 15th",
                        fields: ["npe03__Installment_Period__c"],
                    },
                ],
            };
            const errorInfo = constructErrorMessage(saveResult);
            expect(errorInfo).toMatchObject({
                detail: "npe03__Amount__c - Amount must be greater than 1, npe03__Installment_Period__c - Recurring period must not be 1st and 15th",
                header: commonUnknownError,
            });
        });
    });
});
