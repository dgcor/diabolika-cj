package Diabolika

import std.collection.*

struct LevelUnitQueue {
    var unit: ?UnitObject = None
    var queue = ArrayList<?UnitObject>()
}
