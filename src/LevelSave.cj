package Diabolika

import cjsfml.graphics.*
import dgengine.*
import stdx.encoding.json.stream.*
import std.collection.*
import std.io.*

class LevelSave {
    static func load(level: Level, filePath: String): Bool {
        if (let Some(doc) <- JsonUtils.loadFile(filePath)) {
            return load(level, parseLevelSaveObj(level, doc))
        }
        return false
    }

    private static func load(level: Level, levelState: LevelSaveObject): Bool {
        level.gameState.state = levelState.state.state

        level.gameState.level = levelState.state.level
        level.gameState.score = levelState.state.score
        level.gameState.chain = levelState.state.chain

        level.gameState.units = levelState.state.units
        level.gameState.detonators = levelState.state.detonators

        level.gameState.selectedPosition = levelState.state.selectedPosition

        for (pos in levelState.boardWalls) {
            level.addWall(pos)
        }

        for (unit in levelState.boardUnits) {
            level.addUnit(unit)
        }

        for ((index, queue) in levelState.queues |> enumerate) {
            for (unit in queue) {
                level.unitManager.queueUnit(unit, index)
            }
        }

        level.unitManager.updateUnitQueues(level)
        level.options = level.allOptions.get(level.gameState.level)

        for (link in levelState.links) {
            let unit = match (link[0][0] >= 0) {
                case true => level.board[link[0]].unit
                case false => level.unitManager.getQueuedUnit(link[0])
            }

            let unitToLink = match (link[1][0] >= 0) {
                case true => level.board[link[1]].unit
                case false => level.unitManager.getQueuedUnit(link[1])
            }

            match ((unit, unitToLink)) {
                case (Some(unit), Some(unitToLink)) =>
                    if (isObjEq(unit, unitToLink) == false) {
                        UnitObject.updateLink(
                            unit,
                            unitToLink
                        )
                    }
                case _ => ()
            }
        }

        for (explosion in levelState.explosions) {
            if (level.board.isCoordValid(explosion) == true) {
                level.currentExplosions.add(explosion)
            }
        }

        return true
    }

    static func save(level: Level, filePath: String): Unit {
        let stream = ByteBuffer()
        let writer = JsonWriter(stream)
        writer.writeConfig = WriteConfig.pretty
        writer.writeConfig.indent = "  "
        serialize(level, writer)
        writer.flush()
        FileUtils.saveBytes(filePath, stream.bytes())
    }

    private static func serializeUnit(level: Level, writer: JsonWriter, unit: UnitObject, unitInBoard: Bool): Unit {
        SaveUtils.writeValue(writer, "unit", unit.cls.id)

        if (unitInBoard == true) {
            SaveUtils.writeValue(writer, "position", unit.boardPosition)
            SaveUtils.writeValue(writer, "direction", unit.direction)
        }

        if (let Some(link) <- unit.linkedTo) {
            let boardPos = link.boardPosition
            if (boardPos[0] >= 0 && boardPos[1] >= 0) {
                SaveUtils.writeValue(writer, "linkedTo", boardPos)
            } else {
                let queuePos = level.unitManager.getQueuedUnitPosition(link)
                SaveUtils.writeValue(writer, "linkedTo", queuePos)
            }
        }
    }

    private static func serialize(level: Level, writer: JsonWriter): Unit {
        // root
        writer.startObject()

        SaveUtils.writeValue(writer, "state", level.gameState.state.toInt())
        SaveUtils.writeValue(writer, "level", level.gameState.level)
        SaveUtils.writeValue(writer, "score", level.gameState.score)
        SaveUtils.writeValue(writer, "chain", level.gameState.chain)
        SaveUtils.writeValue(writer, "units", level.gameState.units)
        SaveUtils.writeValue(writer, "detonators", level.gameState.detonators)
        SaveUtils.writeValue(writer, "selectedPosition", level.gameState.selectedPosition)

        // board
        writer.writeName("board")
        writer.startArray()

        for (y in 0..level.board.size[1]) {
            for (x in 0..level.board.size[0]) {
                if (level.board.isCoordFree((x, y)) == true) {
                    continue
                }

                let cell = level.board[x, y]

                // wall or unit
                writer.startObject()

                if (cell.isWall == true) {
                    SaveUtils.writeValue(writer, "wall", true)
                    SaveUtils.writeValue(writer, "position", (x, y))
                } else if (let Some(unit) <- cell.unit) {
                    serializeUnit(level, writer, unit, true)
                }

                // wall or unit
                writer.endObject()
            }
        }

        // board
        writer.endArray()

        // queues
        writer.writeName("queue")
        writer.startArray()

        for (queue in level.unitManager) {
            // queue
            writer.startArray()

            if (let Some(unit) <- queue.unit) {
                writer.startObject()
                serializeUnit(level, writer, unit, false)
                writer.endObject()
            } else if (let Some(unit) <- level.unitManager.selectedUnit) {
                writer.startObject()
                serializeUnit(level, writer, unit, false)
                writer.endObject()
            }

            for (unit in queue.queue) {
                if (let Some(unit) <- unit) {
                    writer.startObject()
                    serializeUnit(level, writer, unit, false)
                    writer.endObject()
                }
            }

            // queue
            writer.endArray()
        }

        // shared queue
        writer.startArray()

        for (unit in level.unitManager.sharedUnitsQueue) {
            if (let Some(unit) <- unit) {
                writer.startObject()
                serializeUnit(level, writer, unit, false)
                writer.endObject()
            }
        }

        // shared queue
        writer.endArray()

        // queues
        writer.endArray()

        if (let Exploding <- level.gameState.state) {
            // explosions
            writer.writeName("explosions")
            writer.startArray()

            for (explosion in level.currentExplosions) {
                SaveUtils.writeValue(writer, explosion)
            }

            // explosions
            writer.endArray()
        }

        // root
        writer.endObject()
    }
}
