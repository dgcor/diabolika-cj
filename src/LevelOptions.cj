package Diabolika

import dgengine.*
import std.collection.*

struct LevelOptions {
    LevelOptions(
        var level!: Int64 = 0,
        var numUnits!: Int64 = 8,
        var numDetonators!: Int64 = 2,
        var maxDemons!: Int64 = 10,
        var walls!: Int64 = 0,
        var maxUnitsById!: HashMap<String, Int64> = HashMap<String, Int64>(),
        var maxUnitsByType!: HashMap<String, Int64> = HashMap<String, Int64>(),
        var insertUnits!: ArrayList<(String, Formula)> = ArrayList<(String, Formula)>(),
        var queueUnits!: ArrayList<String> = ArrayList<String>()
    ) {}

    func clone(): LevelOptions {
        LevelOptions(
            level: level,
            numUnits: numUnits,
            numDetonators: numDetonators,
            maxDemons: maxDemons,
            walls: walls,
            maxUnitsById: maxUnitsById.clone(),
            maxUnitsByType: maxUnitsByType.clone(),
            insertUnits: insertUnits.clone(),
            queueUnits: queueUnits.clone()
        )
    }

    func getMaxUnitsById(id: String): Int64 {
        maxUnitsById.get(id) ?? 0
    }

    func getMaxUnitsByType(clsType: String): Int64 {
        maxUnitsByType.get(clsType) ?? 0
    }
}
