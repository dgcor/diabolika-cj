package Diabolika

import cjsfml.graphics.*
import cjsfml.system.*
import cjsfml.window.*
import dgengine.*
import std.convert.*

extend Level <: UIObject {
    // Resource

    public func isClosed(): Bool {
        surface.isClosed()
    }

    public func close(): Unit {
        surface.close()
    }

    // UIObject

    public mut prop anchor: Anchor {
        get() {
            surface.anchor
        }
        set(value) {
            surface.anchor = value
        }
    }

    public func updateSize(game: Game): Unit {
        surface.updateSize(game)
    }

    public prop drawPosition: Vector2f {
        get() {
            surface.position
        }
    }

    public mut prop position: Vector2f {
        get() {
            surface.position
        }
        set(value) {
            surface.position = value
        }
    }

    public mut prop size: Vector2f {
        get() {
            surface.size
        }
        set(_) {}
    }

    public mut prop visible: Bool {
        get() {
            surface.visible
        }
        set(value) {
            surface.visible = value
        }
    }

    public func draw(game: Game, target: RenderTarget): Unit {
        LevelDraw.draw(this, game, target)
    }

    public func update(game: Game): Unit {
        if (surface.visible == false || pause == true) {
            return
        }

        if (sleepTime.timeout != Time.zero && sleepTime.updateAndReset(game.elapsedTime) == true) {
            sleepTime.timeout = Time.zero
        }

        if (sleepTime.timeout == Time.zero && allAnimationsFinished == true) {
            processStep(game)
        }

        if (gameState.state.isGameOver == false) {
            if (boardRect.contains(game.mousePositionf) == true) {
                hasMouseInside = true
                if (game.mouseMove.isSome() == true) {
                    LevelDraw.updateSelectedTile(this, game)
                }
                if (sleepTime.timeout == Time.zero && game.mousePress.isSome() == true) {
                    onMouseButtonPressed(game)
                }
            } else {
                hasMouseInside = false
            }
        }

        allAnimationsFinished = LevelDraw.updateBoardAnimations(this, game)

        LevelDraw.updateSelectedTileAnimation(this, game)
    }

    // Queryable

    public func getProperty(propName: String): ?Variable {
        if (propName.size <= 1) {
            return None
        }
        let props = splitStringIn2(propName, ".")
        return match (props[0]) {
            case "id" => VaString(id)
            case "name" => VaString(name)
            case "boardSize" => Variable.getTuple2iProp(board.size, props[1])
            case "pause" => VaBoolean(pause)
            case "demons" => VaInteger(stats.countUnitsByType("demon"))
            case "gameOver" => VaBoolean(gameState.state.isGameOver)
            case "detonators" => VaInteger(gameState.detonators)
            case "level" => VaInteger(gameState.level)
            case "score" => VaInteger(gameState.score)
            case "chain" => VaInteger(gameState.chain)
            case "selectedPosition" =>
                let props2 = splitStringIn2(props[1], '.')
                match (props2[0]) {
                    case "position" => match (board.isCoordValid(gameState.selectedPosition)) {
                        case true => Variable.getTuple2iProp(
                            board[gameState.selectedPosition].tile.position,
                            props2[1]
                        )
                        case false => None
                    }
                    case _ => Variable.getTuple2iProp(gameState.selectedPosition, props2[0])
                }
            case "selectedUnitQueue" => VaInteger(unitManager.selectedUnitQueueIdx)
            case "units" => VaInteger(gameState.units)
            case "walls" => VaInteger(gameState.walls)
            case "hasQueuedUnit" =>
                let idx = Int64.tryParse(props[1]) ?? 0
                VaBoolean(unitManager.hasQueuedUnit(idx))
            case "queuedUnit" =>
                let props2 = splitStringIn2(props[1], '.')
                let idx = Int64.tryParse(props2[0]) ?? 0
                match (unitManager.getQueuedUnit(idx)) {
                    case Some(unit) => unit.getProperty(props2[1])
                    case None => None
                }
            case "hasHighScore" =>
                let idx = Int64.tryParse(props[1]) ?? 0
                VaBoolean(idx < highScores.size)
            case "highScore" => highScores.getProperty(props[1])
            case _ => getProperty(props[0], props[1])
        }
    }

    public func getQueryable(propName: String): ?QueryObject {
        if (propName.isEmpty() == true) {
            return ObjQueryable(this)
        }
        var props = splitStringIn2(propName, '.')
        var queryable: ?Queryable = match (props[0]) {
            case "queue" =>
                props = splitStringIn2(props[1], '.')
                let idx = Int64.tryParse(props[0]) ?? 0
                match (unitManager.getQueuedUnit(idx)) {
                    case Some(unit) => unit
                    case None => None
                }
            case _ => None
        }
        return match (queryable) {
            case Some(queryable) where props[1].isEmpty() == false => queryable.getQueryable(props[1])
            case Some(queryable) => ObjQueryable(queryable)
            case None => None
        }
    }

    private func onMouseButtonPressed(game: Game): Unit {
        match (game.mousePress?.button) {
            case Some(button) where button == MouseButton.Left => game.events.addBack(leftClickAction)
            case Some(button) where button == MouseButton.Right => game.events.addBack(rightClickAction)
            case _ => ()
        }
        game.mousePress = None
    }
}
