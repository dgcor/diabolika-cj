package Diabolika

import cjsfml.system.*
import dgengine.*
import std.collection.*

class UnitObject <: Animation & TextureQueryable {
    let cls: UnitClass
    var boardPosition: (Int64, Int64)
    var points: Int64
    private var m_direction: UInt32
    private var m_linkedTo: ?UnitObject = None
    private var m_disableExplosion: Bool = false

    init(cls: UnitClass, boardPosition!: (Int64, Int64) = (-1, -1), direction!: UInt32 = 0) {
        this.cls = cls
        this.boardPosition = boardPosition
        m_direction = direction
        this.points = cls.points

        let texturePack = cls.texturePack
        var animInfo = texturePack.getAnimation(0, Int32(direction))
        if (animInfo.refresh == Time.zero) {
            animInfo.refresh = Time(milliseconds: 50)
        }
        setAnimation(texturePack, animInfo)
    }

    prop direction: UInt32 {
        get() {
            m_direction
        }
    }

    func rotateDirection(): Unit {
        let directions = cls.directions
        if (directions > 0 && m_direction < directions - 1) {
            m_direction++
        } else {
            m_direction = 0
        }
        setAnimation(0, Int32(m_direction), true, true)
    }

    prop linkedTo: ?UnitObject {
        get() {
            m_linkedTo
        }
    }

    prop disableExplosion: Bool {
        get() {
            m_disableExplosion
        }
    }

    func getExplodePattern(): ?ArrayList<(Int64, Int64)> {
        cls.explodePatterns.get(Int64(m_direction))
    }

    func explode(game: Game, level: Level, newExplosions: ArrayList<(Int64, Int64)>): Unit {
        match (cls.linkType) {
            case Unidirectional =>
                if (let Some(obj) <- linkedTo) {
                    if (obj.isClosed() == false) {
                        if (level.board.isCoordValid(obj.boardPosition) == true) {
                            obj.m_disableExplosion = false
                            newExplosions.add(obj.boardPosition)
                        }
                    }
                }
            case Bidirectional =>
                if (let Some(obj) <- linkedTo) {
                    if (obj.isClosed() == false) {
                        if (level.board.isCoordValid(obj.boardPosition) == true) {
                            newExplosions.add(obj.boardPosition)
                        }
                    }
                }
            case LinkUnit =>
                let link = cls.links
                let boardSize = level.board.size
                for (y in 0..boardSize[1]) {
                    for (x in 0..boardSize[0]) {
                        let unit = level.board.getUnit(x, y)
                        if (let Some(unit) <- unit) {
                            if (unit.cls.id == link) {
                                newExplosions.add((x, y))
                            }
                        }
                    }
                }
            case _ => ()
        }

        let explodePattern = getExplodePattern()
        if (explodePattern.isSome() && disableExplosion == false) {
            let explodePattern = explodePattern.getOrThrow()
            let blastExpands = cls.blastExpands
            for (explodeBoardPos in explodePattern) {
                if (explodeBoardPos[0] == 0 && explodeBoardPos[1] == 0) {
                    continue
                }
                var x = boardPosition[0] + explodeBoardPos[0]
                var y = boardPosition[1] + explodeBoardPos[1]
                while (level.board.isCoordValid((x, y)) == true) {
                    if (level.board[x, y].isWall == true) {
                        break
                    }
                    if (blastExpands == false) {
                        newExplosions.add((x, y))
                        break
                    }

                    if (level.board.hasUnit((x, y)) == true) {
                        newExplosions.add((x, y))
                    }
                    if (explodeBoardPos[0] > 0) {
                        x++
                    } else if (explodeBoardPos[0] < 0) {
                        x--
                    }
                    if (explodeBoardPos[1] > 0) {
                        y++
                    } else if (explodeBoardPos[1] < 0) {
                        y--
                    }
                }
            }
        } else {
            var explodeUnits = cls.generateExplodeUnits()
            if (explodeUnits > 0) {
                var boardSize = level.board.size
                let maxSize = boardSize[0] * boardSize[1] - 1
                boardSize = (boardSize[0] - 1, boardSize[1] - 1)
                if (explodeUnits > maxSize) {
                    explodeUnits = maxSize
                }
                let randomVec = ArrayList<(Int64, Int64)>()
                let randomVecHashes = HashSet<Int64>()
                var hasher = DefaultHasher()
                while (explodeUnits > 0) {
                    let expPos = (Random.get(boardSize[0]), Random.get(boardSize[1]))
                    hasher.reset()
                    hasher.write(expPos[0])
                    hasher.write(expPos[1])
                    let hash = hasher.finish()
                    if (expPos != boardPosition && randomVecHashes.contains(hash) == false) {
                        randomVec.add(expPos)
                        randomVecHashes.add(hash)
                        explodeUnits--
                    }
                }
                newExplosions.add(all: randomVec)
            }
        }

        if (cls.spawns.isEmpty() == false) {
            if (let Some(newClass) <- level.getUnitClass(cls.spawns)) {
                var spawnCount = cls.generateSpawnCount()
                if (spawnCount > 0) {
                    var boardSize = level.board.size
                    boardSize = (boardSize[0] - 1, boardSize[1] - 1)

                    var spawnArea = cls.spawnArea
                    spawnArea.left = clamp(Int32(boardPosition[0]) + spawnArea.left, 0, Int32(boardSize[0]))
                    spawnArea.top = clamp(Int32(boardPosition[1]) + spawnArea.top, 0, Int32(boardSize[1]))
                    spawnArea.width = clamp(Int32(boardPosition[0]) + spawnArea.width, 0, Int32(boardSize[0]))
                    spawnArea.height = clamp(Int32(boardPosition[1]) + spawnArea.height, 0, Int32(boardSize[1]))

                    if (spawnArea.left == spawnArea.width && spawnArea.top == spawnArea.height) {
                        level.addUnit(newClass, boardPosition)
                        return
                    } else {
                        level.deleteUnit(boardPosition)
                    }

                    var maxTries = 128
                    while (spawnCount > 0 && maxTries > 0) {
                        let pos = (Random.get(Int64(spawnArea.left), Int64(spawnArea.width)), Random.get(
                                Int64(spawnArea.top), Int64(spawnArea.height)))
                        if (level.board.hasUnit(pos) == false) {
                            level.addUnit(newClass, pos)
                            spawnCount--
                            continue
                        }
                        maxTries--
                    }
                    return
                }
            }
        }

        game.events.addBack(cls.destroyAction)
        level.updateScore(this)
        level.deleteUnit(boardPosition)
    }

    public override func getProperty(propName: String): ?Variable {
        if (propName.size <= 1) {
            return None
        }
        let props = splitStringIn2(propName, ".")
        return match (props[0]) {
            case "boardPosition" => Variable.getTuple2iProp(boardPosition, props[1])
            case "direction" => VaInteger(Int64(m_direction))
            case "disableExplosion" => VaBoolean(m_disableExplosion)
            case "name" => VaString(cls.name)
            case "points" => VaInteger(points)
            case "type" => VaString(cls.clsType)
            case _ => super.getProperty(propName)
        }
    }

    public override func getTexture(textureNumber: UInt32): ?TextureInfo {
        let texturePack = cls.texturePack
        let directions = texturePack.getDirectionCount(0)
        if (textureNumber < directions) {
            let idx = texturePack.getAnimation(0, Int32(textureNumber)).indexRange[0]
            return texturePack.get(idx)
        }
        return None
    }

    // links 2 units using the first unit's link type
    static func updateLink(unit: UnitObject, unitToLink: UnitObject): Unit {
        match (unit.cls.linkType) {
            case Unidirectional =>
                unit.m_linkedTo = unitToLink
                unitToLink.m_disableExplosion = true
            case Bidirectional =>
                unit.m_linkedTo = unitToLink
                unitToLink.m_linkedTo = unit
            case _ => ()
        }
    }
}
