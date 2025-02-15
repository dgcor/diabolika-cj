package Diabolika

import cjsfml.graphics.*
import cjsfml.system.*
import dgengine.*
import std.collection.*
import std.math.*

class Level {
    let surface = Surface()
    var gameShader: ?GameShader = None

    let board = LevelBoard()
    var boardTiles = Array<UInt32>()

    let selectedTileAnim = Animation()

    var tilesTexturePack: ?TexturePack = None
    var explodeCursorTexturePack: ?TexturePack = None
    var explodePatternTexturePack: ?TexturePack = None
    var explosionTexturePack: ?TexturePack = None

    var id = String.empty
    var name = String.empty

    private var m_boardRect = FloatRect()
    var pause = false
    var hasMouseInside = true
    var allAnimationsFinished = true

    var gameState = LevelStateObject()

    var scoreFormula = Formula()
    private var m_stats = LevelStats()
    var options = LevelOptions()

    private var m_unitManager = LevelUnitManager()

    var sleepTime = ElapsedTime()
    var timeout = Time(milliseconds: 1000)
    private var m_drawExplosions = ArrayList<(Int64, Int64)>()
    private var m_currentExplosions = ArrayList<(Int64, Int64)>()
    private var m_currentWalls = ArrayList<(Int64, Int64)>()

    let allOptions = LevelOptionsManager()

    var leftClickAction: ?Action = None
    var rightClickAction: ?Action = None
    var selectedTileChangeAction: ?Action = None
    var newRoundAction: ?Action = None
    var explosionAction: ?Action = None
    var gameOverAction: ?Action = None

    let unitsClasses = HashMap<String, UnitClass>()

    let highScores = LevelScoreManager()

    // Level

    func initialize(tilesTexturePack: ?TexturePack, explodeCursorTexturePack: ?TexturePack,
        explodePatternTexturePack: ?TexturePack, explosionTexturePack: ?TexturePack, tileSize: Float32, padding: IntRect) {
        this.tilesTexturePack = tilesTexturePack
        this.explodeCursorTexturePack = explodeCursorTexturePack
        this.explodePatternTexturePack = explodePatternTexturePack
        this.explosionTexturePack = explosionTexturePack

        if (tileSize > 0.0) {
            board.tileSize = tileSize
        } else if (let Some(tilesTexturePack) <- tilesTexturePack) {
            board.tileSize = Float32(tilesTexturePack.getTextureSize(0).x)
        }
        if (board.tileSize <= 0.0) {
            board.tileSize = 32.0
        }

        let left = clamp(padding.left, 0, 512)
        let top = clamp(padding.top, 0, 512)
        let width = clamp(padding.width, 0, 512)
        let height = clamp(padding.height, 0, 512)
        board.padding = FloatRect(Float32(left), Float32(top), Float32(width), Float32(height))
    }

    prop boardRect: FloatRect {
        get() {
            m_boardRect
        }
    }

    prop stats: LevelStats {
        get() {
            m_stats
        }
    }

    prop unitManager: LevelUnitManager {
        get() {
            m_unitManager
        }
    }

    prop currentExplosions: ArrayList<(Int64, Int64)> {
        get() {
            m_currentExplosions
        }
    }

    // game related

    func addUnitClass(key: String, cls: UnitClass): Unit {
        unitsClasses.put(key, cls)
    }

    func getUnitClass(key: String): ?UnitClass {
        unitsClasses.get(key)
    }

    func queueUnit(unitId: String): Unit {
        m_unitManager.queueUnit(this, unitId)
    }

    func addUnit(cls: UnitClass, boardPos: (Int64, Int64)): Unit {
        addUnit(UnitObject(cls), boardPos)
    }

    func addUnit(unit: UnitObject): Unit {
        addUnit(unit, unit.boardPosition)
    }

    func addUnit(unit: UnitObject, boardPos: (Int64, Int64)): Unit {
        if (board[boardPos].isWall == true) {
            return
        }
        if (let Some(oldUnit) <- board.addUnit(unit, boardPos)) {
            m_stats.decrementUnitCount(oldUnit.cls)
        }
        LevelDraw.setTileAnimationPosition(this, unit, boardPos)
        m_stats.incrementUnitCount(unit.cls)
    }

    func deleteUnit(boardPos: (Int64, Int64)): Unit {
        if (let Some(unit) <- board.getUnit(boardPos)) {
            m_stats.decrementUnitCount(unit.cls)
            board.deleteUnit(boardPos)
        }
    }

    func addWall(boardPos: (Int64, Int64)): Unit {
        if (board.isCoordFree(boardPos) == false) {
            return
        }

        var cell = board[boardPos]
        if (cell.isWall == false) {
            gameState.walls++

            m_currentWalls.append(boardPos)

            cell.isWall = true
            cell.tile.setAnimation(Int32(cell.tileGroupIdx), 0)
            cell.tile.pause = false
            board[boardPos] = cell
        }
    }

    private func initNewGame(game: Game): Unit {
        pause = false
        board.initialize((12, 12))

        m_boardRect.left = surface.position.x + board.padding.left
        m_boardRect.top = surface.position.y + board.padding.top
        m_boardRect.width = Float32(board.size[0]) * board.tileSize
        m_boardRect.height = Float32(board.size[1]) * board.tileSize

        surface.size = Vector2f(
            m_boardRect.width + (board.padding.left + board.padding.width),
            m_boardRect.height + (board.padding.top + board.padding.height)
        )

        for (y in 0..board.size[1]) {
            for (x in 0..board.size[0]) {
                var cell = LevelCell()

                var numTiles = Int32(tilesTexturePack?.size ?? 0)
                numTiles--

                var groupIdx = -1i32
                var boardIdx = x + y * board.size[1]

                if (boardIdx < boardTiles.size) {
                    groupIdx = Int32(boardTiles[boardIdx])
                } else if (numTiles >= 0) {
                    groupIdx = Random.get(numTiles)
                }

                if (groupIdx >= 0) {
                    cell.tileGroupIdx = UInt32(groupIdx)
                    if (let Some(tilesTexturePack) <- tilesTexturePack) {
                        cell.tile.setAnimation(tilesTexturePack, groupIdx, 0)
                    }
                    cell.tile.pause = true
                }

                cell.tile.position = board.toDrawCoord((x, y))
                board[x, y] = cell
            }
        }

        surface.setCenter()
        surface.initialize(game)
        surface.updateView(game)

        allAnimationsFinished = true
        gameState = LevelStateObject()
        gameState.state = AddUnits
        m_stats = LevelStats()
        options = LevelOptions()
        m_unitManager = LevelUnitManager()
    }

    func newGame(game: Game): Unit {
        initNewGame(game)
        nextRound(game)
    }

    func loadGame(game: Game, filePath: String): Unit {
        initNewGame(game)
        if (LevelSave.load(this, filePath) == true) {
            game.events.addBack(newRoundAction)
        }
    }

    func saveGame(filePath: String): Unit {
        LevelSave.save(this, filePath)
    }

    private func nextRound(game: Game): Unit {
        gameState.level++
        options = allOptions.get(gameState.level)
        gameState.detonators += options.numDetonators
        gameState.units += options.numUnits
        gameState.walls += options.walls
        m_unitManager.updateUnitQueues(this)
        updateLevelWalls()
        addLevelUnits()

        game.events.addBack(newRoundAction)
    }

    protected func processStep(game: Game): Unit {
        match (gameState.state) {
            case Exploding =>
                if (m_currentExplosions.isEmpty() == false) {
                    processExplosions(game)
                } else {
                    if (gameState.detonators > 0) {
                        gameState.state = Detonate
                    } else {
                        gameState.state = CheckStatus
                    }
                }
            case CheckStatus =>
                if (m_stats.countUnitsByType("demon") < options.maxDemons) {
                    nextRound(game)
                    gameState.state = AddUnits
                } else {
                    gameState.state = GameOver
                    game.events.addBack(gameOverAction)
                }
            case _ => ()
        }
    }

    private func processExplosions(game: Game): Unit {
        let newExplosions = ArrayList<(Int64, Int64)>()

        for (boardPos in m_currentExplosions) {
            let cell = board[boardPos]
            if (let Some(unit) <- cell.unit) {
                var unitExplTexPack = unit.cls.explosionTexturePack
                if (unitExplTexPack.isNone()) {
                    unitExplTexPack = explosionTexturePack
                }
                if (let Some(unitExplTexPack) <- unitExplTexPack) {
                    LevelDraw.addExplosionAnim(cell.anim, unitExplTexPack, Int32(unit.direction))
                }
                unit.explode(game, this, newExplosions)
            } else if (cell.isWall == false) {
                LevelDraw.addExplosionAnim(this, cell.anim)
            }
            LevelDraw.setTileAnimationPosition(this, cell.anim, boardPos)
        }

        m_drawExplosions = m_currentExplosions
        m_currentExplosions = newExplosions
        sleepTime.timeout = timeout
        allAnimationsFinished = false
        gameState.chain++

        game.events.addBack(explosionAction)
    }

    private func updateLevelWalls(): Unit {
        for (boardPos in m_currentWalls) {
            var cell = board[boardPos]
            if (cell.isWall == true) {
                cell.isWall = false
                cell.tile.setAnimation(Int32(cell.tileGroupIdx), 1)
                cell.tile.pause = false
                board[boardPos] = cell
            }
        }
        m_currentWalls.clear()

        for (_ in 0..options.walls) {
            let boardPos = (Random.get(board.size[0] - 1), Random.get(board.size[1] - 1))
            addWall(boardPos)
        }
    }

    private func addLevelUnits(): Unit {
        let levelUnitsQueue = ArrayList<UnitObject>()

        for ((classId, numformula) in options.insertUnits) {
            var count = min(Int64(numformula.eval(this)), 64)
            if (count <= 0) {
                continue
            }
            if (let Some(cls) <- getUnitClass(classId)) {
                while (count > 0) {
                    levelUnitsQueue.append(UnitObject(cls))
                    count--
                }
            }
        }

        while (levelUnitsQueue.isEmpty() == false) {
            let id = levelUnitsQueue[0].cls.id
            var max = options.getMaxUnitsById(id)
            if (max > 0 && m_stats.countUnitsById(id) >= max) {
                levelUnitsQueue.remove(0)
                continue
            }
            let clsType = levelUnitsQueue[0].cls.clsType
            max = options.getMaxUnitsByType(clsType)
            if (max > 0 && m_stats.countUnitsByType(clsType) >= max) {
                levelUnitsQueue.remove(0)
                continue
            }
            let boardPos = (Random.get(board.size[0] - 1), Random.get(board.size[1] - 1))
            if (board.isCoordFree(boardPos) == false) {
                continue
            }
            addUnit(levelUnitsQueue.remove(0), boardPos)
        }
    }

    func rotateSelectedUnit(): Unit {
        m_unitManager.rotateSelectedUnit()
    }

    func selectUnitQueue(queueIdx: Int64): Unit {
        m_unitManager.selectUnitQueue(queueIdx)
    }

    func selectTile(game: Game, boardPos: (Int64, Int64)): Unit {
        if (boardPos[0] >= 0 && boardPos[0] < board.size[0] && boardPos[1] >= 0 && boardPos[1] < board.size[1]) {
            if (gameState.selectedPosition != boardPos) {
                game.events.addBack(selectedTileChangeAction)
            }
            gameState.selectedPosition = boardPos
        }
    }

    func moveSelectedTile(game: Game, boardPosOffset: (Int64, Int64)): Unit {
        let pos = gameState.selectedPosition
        let newPos = (pos[0] + boardPosOffset[0], pos[1] + boardPosOffset[1])
        selectTile(game, newPos)
    }

    func makeMove(game: Game): Unit {
        if (surface.visible == false) {
            return
        }
        match (gameState.state) {
            case AddUnits =>
                if (gameState.units > 0 && board.isCoordValid(gameState.selectedPosition) == true) {
                    if (let Some(selectedUnit) <- m_unitManager.selectedUnit) {
                        let cell = board[gameState.selectedPosition]
                        if (cell.isWall == false && cell.unit.isNone()) {
                            addUnit(selectedUnit, gameState.selectedPosition)
                            m_unitManager.clearSelectedUnit(this)
                            gameState.units--
                            game.events.addBack(selectedUnit.cls.createAction)
                            if (gameState.units <= 0) {
                                gameState.state = Detonate
                            }
                        }
                    }
                }
            case Detonate =>
                if (gameState.detonators > 0) {
                    gameState.chain = 0
                    m_currentExplosions.append(gameState.selectedPosition)
                    gameState.detonators--
                    gameState.state = Exploding
                }
            case _ => ()
        }
    }

    func updateScore(unit: UnitObject): Unit {
        gameState.score += Int64(scoreFormula.eval(unit, this))
    }
}
