import { fireEvent } from 'c/pubsubNoPageRef';

class ElevateWidgetDisplay {
    _state = DISPLAY_DEFINITIONS.initialState;
    _componentContext;

    init(context) {
        this._componentContext = context;
    }

    transitionTo(nextState) {
        const currentStateDefinition = DISPLAY_DEFINITIONS[this._state];
        const destinationTransition = currentStateDefinition.transitions[nextState];
        if (!destinationTransition || this._state === nextState) {
            return;
        }

        this.dispatchApplicationEvent('widgetStateChange', {
            state: nextState
        });

        const destinationState = destinationTransition.target;
        const destinationStateDefinition = DISPLAY_DEFINITIONS[destinationState];

        currentStateDefinition.actions.onExit.call(this);
        destinationStateDefinition.actions.onEnter.call(this);

        this._state = destinationState;
        this._componentContext.refreshDisplayState();
    }

    currentState() {
        return this._state;
    }

    dispatchApplicationEvent(eventName, payload) {
        fireEvent(null, eventName, payload);
    }
}

const DISPLAY_DEFINITIONS = Object.freeze({
    initialState: 'charge',
    loading: {
        actions: {
            onEnter() {
                this._componentContext.loadingOn();
            },
            onExit() {
                this._componentContext.loadingOff();
            },
        },
        transitions: {
            charge: {
                target: 'charge',
            },
            deactivated: {
                target: 'deactivated',
            },
            readOnly: {
                target: 'readOnly',
            },
            criticalError: {
                target: 'criticalError',
            }
        },
    },
    charge: {
        actions: {
            onEnter() {
                if (!this._componentContext.isMounted) {
                    this._componentContext.loadingOn();
                }
            },
            onExit() {},
        },
        transitions: {
            loading: {
                target: 'loading'
            },
            deactivated: {
                target: 'deactivated'
            },
            userOriginatedDoNotCharge: {
                target: 'doNotCharge'
            },
            readOnly: {
                target: 'readOnly'
            },
            criticalError: {
                target: 'criticalError'
            }
        },
    },
    deactivated: {
        actions: {
            onEnter() {
                this._componentContext.dismount();
                this._componentContext.requestParentNullPaymentFieldsInFormState();
            },
            onExit() {},
        },
        transitions: {
            loading: {
                target: 'loading'
            },
            charge: {
                target: 'charge'
            },
            readOnly: {
                target: 'readOnly'
            }
        },
    },
    doNotCharge: {
        actions: {
            onEnter() {
                this._componentContext.dismount();
                this._componentContext.requestParentNullPaymentFieldsInFormState();
            },
            onExit() {},
        },
        transitions: {
            loading: {
                target: 'loading'
            },
            userOriginatedCharge: {
                target: 'charge'
            },
            userOriginatedDeactivated: {
                target: 'deactivated'
            }
        },
    },
    readOnly: {
        actions: {
            onEnter() {
                this._componentContext.dismount();
            },
            onExit() {},
        },
        transitions: {
            loading: {
                target: 'loading'
            },
            edit: {
                target: 'edit'
            },
            editExpiredTransaction: {
                target: 'edit'
            },
            resetToCharge: {
                target: 'charge'
            },
            resetToDeactivated: {
                target: 'deactivated'
            }
        },
    },
    criticalError: {
        actions: {
            onEnter() {
                this._componentContext.dismount();
            },
            onExit() {},
        },
        transitions: {}
    },
    edit: {
        actions: {
            onEnter() {
                if (!this._componentContext.isMounted) {
                    this._componentContext.loadingOn();
                }
                this._componentContext.requestParentNullPaymentFieldsInFormState();
            },
            onExit() {},
        },
        transitions: {
            readOnly: {
                target: 'readOnly'
            },
            resetToCharge: {
                target: 'charge'
            },
            resetToDeactivated: {
                target: 'deactivated'
            },
            deactivated: {
                target: 'deactivated'
            }
        }
    }
});

export default ElevateWidgetDisplay;
