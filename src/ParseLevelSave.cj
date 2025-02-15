package Diabolika

import cjsfml.system.*
import dgengine.*
import encoding.json.*
import std.collection.*

func parseLevelSaveUnit(level: Level, elem: JsonValue): ?UnitObject {
    if (let Some(cls) <- level.getUnitClass(getStringKey(elem, "unit"))) {
        let pos = getVector2iKey(elem, "position", default: Vector2i(-1, -1))
        return UnitObject(
            cls,
            boardPosition: (Int64(pos.x), Int64(pos.y)),
            direction: getUIntKey(elem, "direction")
        )
    }
    return None
}

func parseLevelSaveObj(level: Level, elem: JsonValue): LevelSaveObject {
    var levelSave = LevelSaveObject()

    levelSave.state.state = LevelState.create(getInt64Key(elem, "state"))
    levelSave.state.level = Int64(getUIntKey(elem, "level"))
    levelSave.state.score = Int64(getUInt64Key(elem, "score"))
    levelSave.state.chain = Int64(getUIntKey(elem, "chain"))
    levelSave.state.units = Int64(getUIntKey(elem, "units"))
    levelSave.state.detonators = Int64(getUIntKey(elem, "detonators"))
    let pos = getVector2iKey(elem, "selectedPosition")
    levelSave.state.selectedPosition = (Int64(pos.x), Int64(pos.y))

    if (let Some(elem) <- getValidArray(elem, "board")) {
        for (val in elem.getItems()) {
            if (getBoolKey(val, "wall") == true) {
                let pos = getVector2iKey(val, "position", default: Vector2i(-1, -1))
                levelSave.boardWalls.append((Int64(pos.x), Int64(pos.y)))
                continue
            }

            if (let Some(unit) <- parseLevelSaveUnit(level, val)) {
                levelSave.boardUnits.append(unit)

                let val = val.asObject()
                if (let Some(val) <- val.get("linkedTo")) {
                    let pos = getVector2iVal(val)
                    levelSave.links.append((unit.boardPosition, ((Int64(pos.x), Int64(pos.y)))))
                }
            }
        }
    }

    if (let Some(elem) <- getValidArray(elem, "queue")) {
        var queueIdx = -1
        for (queueElem in elem.getItems()) {
            levelSave.queues.append(ArrayList())

            if (let Some(queueElem) <- getValidArray(queueElem)) {
                for (val in queueElem.getItems()) {
                    if (let Some(unit) <- parseLevelSaveUnit(level, val)) {
                        unit.position = Vector2f(-1.0, -1.0)
                        let queue = levelSave.queues[levelSave.queues.size - 1]
                        queue.append(unit)

                        let val = val.asObject()
                        if (let Some(val) <- val.get("linkedTo")) {
                            let pos = getVector2iVal(val)
                            levelSave.links.append(((queueIdx, queue.size - 1), (Int64(pos.x), Int64(pos.y))))
                        }
                    }
                }
                queueIdx--
            }
        }
    }

    if (let Some(elem) <- getValidArray(elem, "explosions")) {
        for (val in elem.getItems()) {
            let pos = getVector2iVal(val)
            levelSave.explosions.append((Int64(pos.x), Int64(pos.y)))
        }
    }

    return levelSave
}
