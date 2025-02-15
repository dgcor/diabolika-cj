package Diabolika

import dgengine.*
import encoding.json.*

func parseDocumentElem(game: Game, name: String, elem: JsonValue, replaceVars: Box<ReplaceVars>): Bool {
    match (name) {
        case "level" => parseDocumentElemArray(parseLevel, game, name, elem, replaceVars)
        case "unit" => parseDocumentElemArray(parseUnit, game, name, elem, replaceVars)
        case "unitClass" => parseDocumentElemArray(parseUnitClass, game, name, elem, replaceVars)
        case _ => return false
    }
    return true
}
