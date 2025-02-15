package Diabolika

import dgengine.*
import encoding.json.*
import std.collection.*

func getUnitLinkKey(elem: JsonValue, key: String, default!: UnitLink = NoLink): UnitLink {
    if (let Some(str) <- getValidString(elem, key)) {
        return UnitLink.get(str, default: default)
    }
    return default
}

func parseExplodePattern(unitClass: UnitClass, elem: JsonArray): Unit {
    let explodePattern = ArrayList<(Int64, Int64)>()
    for (val in elem.getItems()) {
        if (let Some(val) <- getValidArray(val)) {
            if (val.size() == 2 && val[0].isNumber() && val[1].isNumber()) {
                let explodePoint = getVector2iVal(val)
                if (explodePoint.x == 0 && explodePoint.y == 0) {
                    continue
                }
                explodePattern.append((Int64(explodePoint.x), Int64(explodePoint.y)))
            } else if (val[0].isArray() == true) {
                parseExplodePattern(unitClass, val)
            }
        }
    }
    if (explodePattern.isEmpty() == false) {
        unitClass.addExplodePattern(explodePattern)
    }
}

func parseUnitClass(game: Game, elem: JsonValue): Unit {
    if (let Some(level) <- game.resources.getLevel<Level>(getStringCharKey(elem, "level"))) {
        if (let Some(id) <- getValidString(elem, "id")) {
            if (isValidId(id) == false || level.getUnitClass(id).isSome()) {
                return
            }
            let elem = elem.asObject()
            let texturePack = game.resources.getTexturePack(getStringCharKey(elem, "texturePack"))
            let unitClass = match (texturePack) {
                case Some(tp) =>
                    let explosionTexturePack = game.resources.getTexturePack(
                        getStringCharKey(elem, "explosionTexturePack"))
                    let directions = getUIntKey(elem, "directions")
                    UnitClass(tp, explosionTexturePack, directions)
                case _ => return
            }
            unitClass.id = id
            unitClass.points = Int64(getIntKey(elem, "points"))
            unitClass.name = getStringCharKey(elem, "name")
            unitClass.clsType = getStringCharKey(elem, "type")
            unitClass.spawns = getStringCharKey(elem, "spawns")
            unitClass.spawnCount = Formula(getStringKey(elem, "spawnCount", default: "1"))
            unitClass.spawnArea = getIntRectKey(elem, "spawnArea")
            unitClass.links = getStringCharKey(elem, "links")
            unitClass.linkType = getUnitLinkKey(elem, "linkType")
            unitClass.linkCount = Formula(getStringKey(elem, "linkCount", default: "1"))

            if (let Some(elemPattern) <- getValidArray(elem, "explodePattern")) {
                parseExplodePattern(unitClass, elemPattern)
                unitClass.blastExpands = getBoolKey(elem, "blastExpands")
            } else if (getStringCharKey(elem, "explodePattern") == "random") {
                unitClass.explodeUnits = Formula(getStringKey(elem, "explodeUnits"))
            }

            if (let Some(elem) <- elem.get("onCreate")) {
                unitClass.createAction = getActionVal(game, elem)
            }
            if (let Some(elem) <- elem.get("onDestroy")) {
                unitClass.destroyAction = getActionVal(game, elem)
            }

            level.addUnitClass(id, unitClass)
        }
    }
}
