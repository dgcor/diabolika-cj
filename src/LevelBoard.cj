package Diabolika

import cjsfml.graphics.*
import cjsfml.system.*
import dgengine.*
import std.collection.*

class LevelBoard <: Iterable<LevelCell> {
    private var m_cells = ArrayList<LevelCell>()
    private var m_size = (0, 0)
    var padding = FloatRect()
    var tileSize: Float32 = 0.0

    // Iterable

    public func iterator(): Iterator<LevelCell> {
        m_cells.iterator()
    }

    // LevelBoard

    func initialize(size: (Int64, Int64)): Unit {
        m_cells.clear()
        m_cells = ArrayList<LevelCell>(size[0] * size[1], {_ => LevelCell()})
        m_size = size
    }

    // board height + unitSize
    prop size: (Int64, Int64) {
        get() {
            m_size
        }
    }

    func toDrawCoord(boardPos: (Int64, Int64)): Vector2f {
        Vector2f(padding.left + (tileSize * Float32(boardPos[0])), padding.top + (tileSize * Float32(boardPos[1])))
    }

    operator func [](x: Int64, y: Int64): LevelCell {
        m_cells[x + y * m_size[0]]
    }

    operator func [](boardPos: (Int64, Int64)): LevelCell {
        m_cells[boardPos[0] + boardPos[1] * m_size[0]]
    }

    operator func [](x: Int64, y: Int64, value!: LevelCell): Unit {
        m_cells[x + y * m_size[0]] = value
    }

    operator func [](boardPos: (Int64, Int64), value!: LevelCell): Unit {
        m_cells[boardPos[0] + boardPos[1] * m_size[0]] = value
    }

    func isCoordValid(boardPos: (Int64, Int64)): Bool {
        (boardPos[0] >= 0 && boardPos[0] < m_size[0] && boardPos[1] >= 0 && boardPos[1] < m_size[1])
    }

    func isCoordFree(boardPos: (Int64, Int64)): Bool {
        if (isCoordValid(boardPos) == true) {
            let cell = this[boardPos]
            return cell.isWall == false && cell.unit.isNone()
        }
        return false
    }

    func hasUnit(boardPos: (Int64, Int64)): Bool {
        if (isCoordValid(boardPos) == true) {
            return this[boardPos].unit.isSome()
        }
        return false
    }

    func addUnit(unit: ?UnitObject, boardPos: (Int64, Int64)): ?UnitObject {
        if (isCoordValid(boardPos) == true) {
            var cell = this[boardPos]
            let oldUnit = cell.unit
            cell.unit = unit
            if (let Some(unit) <- unit) {
                unit.boardPosition = boardPos
            }
            this[boardPos] = cell
            return oldUnit
        }
        return None
    }

    func deleteUnit(boardPos: (Int64, Int64)): Unit {
        if (isCoordValid(boardPos) == true) {
            var cell = this[boardPos]
            if (cell.unit.isSome()) {
                cell.unit = None
                this[boardPos] = cell
            }
        }
    }

    func getUnit(x: Int64, y: Int64): ?UnitObject {
        this[x, y].unit
    }

    func getUnit(boardPos: (Int64, Int64)): ?UnitObject {
        this[boardPos].unit
    }
}
