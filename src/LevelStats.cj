package Diabolika

import std.collection.*

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
        match (idEntry.value) {
            case Some(count) where count > 0 => idEntry.value = count - 1
            case _ => idEntry.value = 0
        }

        var typeEntry = m_numUnitsByType.entryView(unitClass.clsType)
        match (typeEntry.value) {
            case Some(count) where count > 0 => typeEntry.value = count - 1
            case _ => typeEntry.value = 0
        }
    }

    func incrementUnitCount(unitClass: UnitClass): Unit {
        var idEntry = m_nunUnitsById.entryView(unitClass.id)
        idEntry.value = (idEntry.value ?? 0) + 1

        var typeEntry = m_numUnitsByType.entryView(unitClass.clsType)
        typeEntry.value = (typeEntry.value ?? 0) + 1
    }
}
