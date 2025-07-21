package Diabolika

import stdx.encoding.json.*

extend JsonValue {
    func isArray(): Bool {
        match (kind()) {
            case JsArray => true
            case _ => false
        }
    }

    func isNumber(): Bool {
        match (kind()) {
            case JsInt | JsFloat => true
            case _ => false
        }
    }
}
