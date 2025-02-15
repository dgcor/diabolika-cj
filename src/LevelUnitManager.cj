package Diabolika

import dgengine.*
import std.collection.*
import std.math.*

class LevelUnitManager <: Iterable<LevelUnitQueue> {
    private var m_unitQueues = Array<LevelUnitQueue>(3, {_ => LevelUnitQueue()})
    private var m_selectedUnit: ?UnitObject = None
    private var m_selectedUnitQueueIdx = -1

    private var m_sharedUnitsQueue = ArrayList<?UnitObject>()

    // Iterable

    public func iterator(): Iterator<LevelUnitQueue> {
        m_unitQueues.iterator()
    }

    // LevelUnitManager

    func hasQueuedUnit(queueIndex: Int64): Bool {
        m_unitQueues.get(queueIndex)?.unit.isSome() ?? false
    }

    func getQueuedUnit(queueIndex: Int64): ?UnitObject {
        m_unitQueues.get(queueIndex)?.unit ?? None
    }

    // get unit from queue position pair with [queueIndex, unitIndex], where queueIndex starts at 1 and unitIndex at 0
    // the abs(queueIndex) value is used, so -1 is equal to queue 1
    func getQueuedUnit(queuePos: (Int64, Int64)): ?UnitObject {
        var queueIndex = queuePos[0]
        if (queueIndex == 0) {
            return None
        }
        queueIndex = abs(queueIndex) - 1

        if (hasQueuedUnit(queueIndex) == true) {
            var unitIndex = queuePos[1]
            if (unitIndex == 0) {
                return m_unitQueues[queueIndex].unit
            }
            unitIndex--
            if (unitIndex < m_unitQueues[queueIndex].queue.size) {
                return m_unitQueues[queueIndex].queue[unitIndex]
            }
        }
        return None
    }

    // get pair with [queueIndex, unitIndex], where queueIndex starts at 1 and unitIndex at 0
    // returns the queueIndex as a negative value
    func getQueuedUnitPosition(unit: ?UnitObject): (Int64, Int64) {
        if (unit.isNone()) {
            return (0, 0)
        }
        for ((index, unitQueue) in m_unitQueues |> enumerate) {
            match ((unit, unitQueue.unit)) {
                case (Some(unit1), Some(unit2)) where isObjEq(unit1, unit2) => return (-index - 1, 0)
                case _ => ()
            }
            for ((indexY, unit2) in unitQueue.queue |> enumerate) {
                match ((unit, unit2)) {
                    case (Some(unit1), Some(unit2)) where isObjEq(unit1, unit2) => return (-index - 1, indexY + 1)
                    case _ => ()
                }
            }
        }
        return (0, 0)
    }

    prop hasSelectedUnit: Bool {
        get() {
            m_selectedUnit.isSome()
        }
    }

    func clearSelectedUnit(level: Level): Unit {
        m_selectedUnit = None
        m_unitQueues[m_selectedUnitQueueIdx] = updateUnitQueue(level, m_unitQueues[m_selectedUnitQueueIdx])
        m_selectedUnitQueueIdx = -1
    }

    prop selectedUnitQueueIdx: Int64 {
        get() {
            m_selectedUnitQueueIdx
        }
    }

    func selectUnitQueue(queueIndex: Int64): Unit {
        if (queueIndex < m_unitQueues.size) {
            if (m_selectedUnit.isNone()) {
                var unitQueue = m_unitQueues[queueIndex]
                m_selectedUnit = unitQueue.unit
                unitQueue.unit = None
                m_unitQueues[queueIndex] = unitQueue
                m_selectedUnitQueueIdx = queueIndex
            } else if (m_selectedUnitQueueIdx == queueIndex) {
                var unitQueue = m_unitQueues[queueIndex]
                unitQueue.unit = m_selectedUnit
                m_unitQueues[queueIndex] = unitQueue
                m_selectedUnit = None
                m_selectedUnitQueueIdx = -1
            }
        }
    }

    prop selectedUnit: ?UnitObject {
        get() {
            m_selectedUnit
        }
    }

    prop sharedUnitsQueue: ArrayList<?UnitObject> {
        get() {
            m_sharedUnitsQueue
        }
    }

    func rotateSelectedUnit(): Unit {
        if (let Some(selectedUnit) <- m_selectedUnit) {
            selectedUnit.rotateDirection()
        }
    }

    func updateUnitQueues(level: Level): Unit {
        for (index in 0..m_unitQueues.size) {
            let unitQueue = m_unitQueues[index]
            m_unitQueues[index] = updateUnitQueue(level, unitQueue)
        }
    }

    private func updateUnitQueue(level: Level, unitQueue: LevelUnitQueue): LevelUnitQueue {
        if (unitQueue.unit.isSome()) {
            return unitQueue
        }
        var unitQueue2 = unitQueue
        if (unitQueue2.queue.isEmpty() == false) {
            unitQueue2.unit = unitQueue2.queue.remove(0)
            return unitQueue2
        }
        if (m_sharedUnitsQueue.isEmpty() == false) {
            unitQueue2.unit = m_sharedUnitsQueue.remove(0)
            return unitQueue2
        }
        if (level.unitsClasses.isEmpty() == true || level.options.queueUnits.isEmpty() == true) {
            return unitQueue2
        }
        let classId = level.options.queueUnits[Random.get(level.options.queueUnits.size - 1)]
        queueUnit(level, classId, unitQueue2.queue)
        if (unitQueue2.queue.isEmpty() == false) {
            unitQueue2 = updateUnitQueue(level, unitQueue2)
        }
        return unitQueue2
    }

    // creates and queues a new unit and its links to the sharedUnitsQueue
    func queueUnit(level: Level, unitId: String): Unit {
        queueUnit(level, unitId, m_sharedUnitsQueue)
    }

    private func queueUnit(level: Level, unitId: String, unitQueue: ArrayList<?UnitObject>): Unit {
        let cls = level.getUnitClass(unitId)
        if (cls.isNone()) {
            return
        }
        let newUnit = UnitObject(cls.getOrThrow())

        unitQueue.append(newUnit)

        let link = newUnit.cls.links
        if (link.isEmpty() == false) {
            if (let Some(linkClass) <- level.getUnitClass(link)) {
                if (linkClass.clsType == "exploder") {
                    var linkCount = newUnit.cls.generateLinkCount()
                    while (linkCount > 0) {
                        let newExplLink = UnitObject(linkClass)

                        UnitObject.updateLink(newUnit, newExplLink)

                        match (newUnit.cls.linkType) {
                            case LinkUnit => m_sharedUnitsQueue.append(newExplLink)
                            case _ => unitQueue.append(newExplLink)
                        }
                        linkCount--
                    }
                }
            }
        }
    }

    // queues a unit to the queue index. queues to the sharedUnitsQueue if the queue index is not valid
    func queueUnit(unit: ?UnitObject, queueIndex: Int64): Unit {
        if (queueIndex >= 0 && queueIndex < m_unitQueues.size) {
            var unitQueue = m_unitQueues[queueIndex]
            if (unitQueue.unit.isNone()) {
                unitQueue.unit = unit
                m_unitQueues[queueIndex] = unitQueue
            } else {
                unitQueue.queue.append(unit)
            }
        } else {
            m_sharedUnitsQueue.append(unit)
        }
    }
}
