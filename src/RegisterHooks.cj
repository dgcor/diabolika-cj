package Diabolika

import dgengine.*

func registerHooks(): Unit {
    Hooks.parseDocumentElem = parseDocumentElem
    Hooks.parseActionElem = parseActionElem
}
