package Diabolika

import dgengine.*
import encoding.json.*
import std.collection.*
import std.math.*

func parseLevelOptions(optionsManager: LevelOptionsManager, elem: JsonArray): Unit {
    const maxBound = (12 * 12 / 2)

    var options = LevelOptions()
    let allOptions = ArrayList<LevelOptions>()
    for (val in elem.getItems()) {
        options = options.clone()
        options.level = getInt64Key(val, "level", default: options.level + 1)
        options.numUnits = clamp(getInt64Key(val, "units", default: options.numUnits), 0, maxBound)
        options.numDetonators = clamp(getInt64Key(val, "exploders", default: options.numDetonators), 1, maxBound)
        options.maxDemons = clamp(getInt64Key(val, "maxDemons", default: options.maxDemons), 0, maxBound)
        options.walls = clamp(getInt64Key(val, "walls", default: options.walls), 0, maxBound)

        if (let Some(elem) <- getValidArray(val, "insertUnits")) {
            options.insertUnits.clear()
            for (val in elem.getItems()) {
                let id = getStringKey(val, "id")
                if (id.isEmpty() == true) {
                    continue
                }
                let count = getStringKey(val, "count")
                options.insertUnits.append((id, Formula(count)))
            }
        }
        if (let Some(elem) <- getValidArray(val, "queueUnits")) {
            options.queueUnits.clear()
            for (val in elem.getItems()) {
                let id = getStringVal(val)
                if (id.isEmpty() == true) {
                    continue
                }
                options.queueUnits.append(id)
            }
        }
        if (let Some(elem) <- getValidArray(val, "maxUnitsById")) {
            options.maxUnitsById.clear()
            for (val in elem.getItems()) {
                let id = getStringKey(val, "id")
                if (id.isEmpty() == true) {
                    continue
                }
                let count = Int64(getUIntKey(val, "count"))
                options.maxUnitsById.put(id, count)
            }
        }
        if (let Some(elem) <- getValidArray(val, "maxUnitsByType")) {
            options.maxUnitsByType.clear()
            for (val in elem.getItems()) {
                let unitType = getStringKey(val, "type")
                if (unitType.isEmpty() == true) {
                    continue
                }
                let count = Int64(getUIntKey(val, "count"))
                options.maxUnitsByType.put(unitType, count)
            }
        }
        allOptions.append(options)
    }
    optionsManager.set(allOptions)
}
