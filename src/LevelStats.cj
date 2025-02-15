package Diabolika

import dgengine.*
import std.collection.*
import std.convert.*

class LevelStats {
    private let m_nunUnitsById = HashMap<String, Int64>()
    private let m_numUnitsByType = HashMap<String, Int64>()

    func countUnitsById(id: String): Int64 {
        m_nunUnitsById.get(id) ?? 0
    }

    func countUnitsByType(unitType: String): Int64 {
        m_numUnitsByType.get(unitType) ?? 0
    }

    func decrementUnitCount(unitClass: UnitClass): Unit {
        var idEntry = m_nunUnitsById.entryView(unitClass.id)
        match (idEntry.getValue()) {
            case Some(count) where count > 0 => idEntry.setValue(count - 1)
            case _ => idEntry.setValue(0)
        }

        var typeEntry = m_numUnitsByType.entryView(unitClass.clsType)
        match (typeEntry.getValue()) {
            case Some(count) where count > 0 => typeEntry.setValue(count - 1)
            case _ => typeEntry.setValue(0)
        }
    }

    func incrementUnitCount(unitClass: UnitClass): Unit {
        var idEntry = m_nunUnitsById.entryView(unitClass.id)
        idEntry.setValue((idEntry.getValue() ?? 0) + 1)

        var typeEntry = m_numUnitsByType.entryView(unitClass.clsType)
        typeEntry.setValue((typeEntry.getValue() ?? 0) + 1)
    }
}
