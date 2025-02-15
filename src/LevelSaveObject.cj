package Diabolika

import std.collection.*

struct LevelSaveObject {
    var state = LevelStateObject()
    var boardWalls = ArrayList<(Int64, Int64)>()
    var boardUnits = ArrayList<UnitObject>()
    var queues = ArrayList<ArrayList<UnitObject>>()
    var links = ArrayList<((Int64, Int64), (Int64, Int64))>()
    var explosions = ArrayList<(Int64, Int64)>()
}
