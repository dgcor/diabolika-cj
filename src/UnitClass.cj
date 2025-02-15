package Diabolika

import cjsfml.graphics.*
import dgengine.*
import std.collection.*
import std.math.*

class UnitClass <: Equatable<UnitClass> {
    var texturePack: TexturePack
    var explosionTexturePack: ?TexturePack
    var directions: UInt32 = 0
    var points = 0

    var id = String.empty
    var name = String.empty
    var clsType = String.empty

    var spawns = String.empty
    var spawnCount = Formula()
    var spawnArea = IntRect()

    var links = String.empty
    var linkType = NoLink
    var linkCount = Formula()

    var explodePatterns = ArrayList<ArrayList<(Int64, Int64)>>()
    var explodeUnits = Formula()
    var blastExpands = false

    var createAction: ?Action = None
    var destroyAction: ?Action = None

    init(texturePack: TexturePack, explosionTexturePack: ?TexturePack, directions: UInt32) {
        this.texturePack = texturePack
        this.explosionTexturePack = explosionTexturePack
        this.directions = directions
    }

    // Equal

    public operator func ==(right: UnitClass): Bool {
        isObjEq(this, right)
    }

    public operator func !=(right: UnitClass): Bool {
        !(this == right)
    }

    // UnitClass

    func generateSpawnCount(): Int64 {
        min(Int64(spawnCount.eval()), 64)
    }

    func generateLinkCount(): Int64 {
        min(Int64(linkCount.eval()), 64)
    }

    func addExplodePattern(pattern: ArrayList<(Int64, Int64)>): Unit {
        explodePatterns.append(pattern)
    }

    func generateExplodeUnits(): Int64 {
        min(Int64(explodeUnits.eval()), 12 * 12)
    }
}
