class ElevateWidgetStateMachine {
    _state = DISPLAY_DEFINITIONS.initialState;
    componentContext;

    transitionTo(nextState) {
        const currentStateDefinition = DISPLAY_DEFINITIONS[this._state];
        const destinationTransition = currentStateDefinition.transitions[nextState];
        if (!destinationTransition || this._state === nextState) return;

        const destinationState = destinationTransition.target;
        const destinationStateDefinition = DISPLAY_DEFINITIONS[destinationState];

        destinationTransition.action.call(this)
        currentStateDefinition.actions.onExit.call(this);
        destinationStateDefinition.actions.onEnter.call(this);

        this._state = destinationState;
    }

    currentState() {
        return this._state;
    }
}

const DISPLAY_DEFINITIONS = Object.freeze({
    initialState: 'loading',
    loading: {
        actions: {
            onEnter() {
                console.log('loading: onEnter');
            },
            onExit() {
                console.log('loading: onExit');
            },
        },
        transitions: {
            charge: {
                target: 'charge',
                action() {
                    console.log('transition action for "charge" from "loading" state');
                },
            },
            deactivated: {
                target: 'deactivated',
                action() {
                    console.log('transition action for "deactivated" from "loading" state');
                },
            },
            readOnly: {
                target: 'readOnly',
                action() {
                    console.log('transition action for "readOnly" from "loading" state');
                },
            }
        },
    },
    charge: {
        actions: {
            onEnter() {
                console.log('charge: onEnter');
                if (!this.componentContext.isMounted) {
                    console.log('turn loading on');
                    this.componentContext.loadingOn();
                }
            },
            onExit() {
                console.log('charge: onExit');
            },
        },
        transitions: {
            loading: {
                target: 'loading',
                action() {
                    console.log('transition action for "loading" from "charge" state');
                    // store previous values relevant to widget from formState
                },
            },
            saving: {
                target: 'saving',
                action() {
                    console.log('transition action for "saving" from "charge" state');
                    // store previous values relevant to widget from formState
                },
            },
            deactivated: {
                target: 'deactivated',
                action() {
                    console.log('transition action for "deactivated" from "charge" state');
                    // store previous values relevant to widget from formState
                },
            },
            userOriginatedDoNotCharge: {
                target: 'doNotCharge',
                action() {
                    console.log('transition action for "doNotCharge" from "charge" state');
                },
            },
            readOnly: {
                target: 'readOnly',
                action() {
                    console.log('transition action for "readOnly" from "charge" state');
                },
            },
            criticalError: {
                target: 'criticalError',
                action() {
                    console.log('transition action for "criticalerror" from "charge" state');
                },
            }
        },
    },
    deactivated: {
        actions: {
            onEnter() {
                console.log('deactivated: onEnter');
                this.componentContext.dismount();
            },
            onExit() {
                console.log('deactivated: onExit')
            },
        },
        transitions: {
            loading: {
                target: 'loading',
                action() {
                    console.log('transition action for "loading" from "deactivated" state');
                    // store previous values relevant to widget from formState
                },
            },
            charge: {
                target: 'charge',
                action() {
                    console.log('transition action for "charge" from "deactivated" state');
                },
            },
            readOnly: {
                target: 'readOnly',
                action() {
                    console.log('transition action for "readOnly" from "deactivated" state');
                },
            }
        },
    },
    doNotCharge: {
        actions: {
            onEnter() {
                console.log('doNotCharge: onEnter');
                this.componentContext.dismount();
            },
            onExit() {
                console.log('doNotCharge: onExit')
            },
        },
        transitions: {
            loading: {
                target: 'loading',
                action() {
                    console.log('transition action for "loading" from "doNotCharge" state');
                    // store previous values relevant to widget from formState
                },
            },
            userOriginatedCharge: {
                target: 'charge',
                action() {
                    console.log('transition action for "userOriginatedCharge" from "doNotCharge" state');
                },
            },
            deactivated: {
                target: 'deactivated',
                action() {
                    console.log('transition action for "deactivated" from "doNotCharge" state');
                },
            },
        },
    },
    readOnly: {
        actions: {
            onEnter() {
                console.log('readOnly: onEnter');
                this.componentContext.dismount();
            },
            onExit() {
                console.log('readOnly: onExit')
            },
        },
        transitions: {
            loading: {
                target: 'loading',
                action() {
                    console.log('transition action for "loading" from "readOnly" state');
                    // store previous values relevant to widget from formState
                },
            },
            editExpiredTransaction: {
                target: 'edit',
                action() {
                    console.log('transition action for "charge" from "readOnly" state, aka edit an expired transaction');
                }
            },
            // We shouldn't able to do this below
            userOriginatedEdit: {
                target: 'charge',
                action() {
                    console.log('transition action for "charge" from "readOnly" state, aka user wants to edit transaction');
                }
            },
            charge: {
                target: 'charge',
                action() {
                    console.log('transition action for "charge" from "readOnly" state');
                },
            },
            deactivated: {
                target: 'deactivated',
                action() {
                    console.log('transition action for "deactivated" from "readOnly" state');
                },
            },
        },
    },
    saving: {
        actions: {
            onEnter() {
                console.log('saving: onEnter');
                this.componentContext.dismount();
            },
            onExit() {
                console.log('saving: onExit')
            },
        },
        transitions: {
            loading: {
                target: 'loading',
                action() {
                    console.log('transition action for "loading" from "saving" state');
                },
            },
        }
    },
    criticalError: {
        actions: {
            onEnter() {
                console.log('criticalError: onEnter');
                this.componentContext.dismount();
            },
            onExit() {
                console.log('criticalError: onExit')
            },
        },
        transitions: {}
    },
    edit: {
        actions: {
            onEnter() {
                console.log('criticalError: onEnter');
                this.componentContext.dismount();
            },
            onExit() {
                console.log('criticalError: onExit')
            },
        },
        transitions: {
            readOnly: {
                target: 'readOnly',
                action() {
                    console.log('transition action for "readOnly" from "edit" state');
                },
            }
        }
    }
});

export default ElevateWidgetStateMachine;
