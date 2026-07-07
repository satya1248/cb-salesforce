import { LightningElement, api } from 'lwc';
import {
    RETAIL_JOURNEY,
    SME_JOURNEY,
    RETAIL_SCENARIOS,
    SME_CRN_SCENARIOS,
    PRESCORE_RULES
} from './onboardingScenarios';

export default class CbOnboardingGuide extends LightningElement {
    @api guideType = 'Retail';

    get onboardingType() {
        return this.guideType;
    }

    get isRetail() {
        return this.guideType === 'Retail';
    }

    get isSme() {
        return this.guideType === 'SME';
    }

    get journeySteps() {
        return this.isSme ? SME_JOURNEY : RETAIL_JOURNEY;
    }

    get scenarioRows() {
        const rows = this.isSme ? SME_CRN_SCENARIOS : RETAIL_SCENARIOS;
        return rows.map((row) => ({
            ...row,
            rowKey: row.key || row.crn
        }));
    }

    get prescoreRules() {
        return PRESCORE_RULES;
    }

    get introText() {
        if (this.isSme) {
            return 'Capture business and director details below, then choose a demo CRN and individual-check persona. KYB runs first, then the retail-style integration chain for the director.';
        }
        return 'Capture realistic customer details below, then choose a demo scenario to drive mock integrations. Pre-score runs first based on nationality, then IDV → bureau → screening → KYC → account open.';
    }

    get afterSubmitText() {
        return 'After you click Next on the final screen, the application is created with In Progress status. Integrations run asynchronously (5–10 seconds). Open CB Onboarding Applications → All Applications and refresh to see the final status, cases, and fin account.';
    }

    outcomeClass(outcome) {
        if (outcome === 'Completed' || outcome.includes('Completed')) {
            return 'slds-badge slds-theme_success';
        }
        if (outcome === 'Rejected') {
            return 'slds-badge slds-theme_error';
        }
        return 'slds-badge slds-theme_warning';
    }
}
