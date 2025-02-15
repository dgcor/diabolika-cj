package Diabolika

import dgengine.*

struct LevelCell {
    var tileGroupIdx = 0u32
    var tile = Animation()
    var anim = Animation()
    var unit: ?UnitObject = None
    var isWall = false
}
