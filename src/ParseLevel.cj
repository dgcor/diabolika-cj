package Diabolika

import dgengine.*
import stdx.encoding.json.*

func parseLevel(game: Game, elem: JsonValue): Unit {
    let id = getStringCharKey(elem, "id")
    var level = game.resources.getLevel<Level>(id)
    if (level.isNone()) {
        if (isValidId(id) == false) {
            return
        }

        let lvl = Level()

        game.resources.addDrawable(id, lvl, manageObjDrawing: true, resourceId: getStringCharKey(elem, "resource"))
        game.resources.setCurrentLevel(lvl)
        lvl.id = id
        lvl.gameShader = game.shaders.level

        parseDrawableProperties(game, elem, lvl)
        level = lvl
    }

    if (let Some(level) <- level) {
        if (let Some(elem) <- getValidObject(elem)) {
            if (let Some(elem) <- elem.get("name")) {
                level.name = getStringChar(elem)
            }
            if (let Some(elem) <- elem.get("scoreFormula")) {
                level.scoreFormula = Formula(getStringChar(elem))
            }
            if (let Some(elem) <- elem.get("timeout")) {
                level.timeout = getTimeUVal(elem)
            }
            if (let Some(elem) <- getValidArray(elem, "levels")) {
                parseLevelOptions(level.allOptions, elem)
            }
            if (let Some(elem) <- getValidArray(elem, "highScores")) {
                parseLevelScores(level.highScores, elem)
            }
            if (let Some(file) <- getValidString(elem, "boardTiles")) {
                let boardTiles = NumberVector<UInt32>(file, default: 0, maxNumElements: 0xFFFF)
                level.boardTiles = boardTiles.data
            }

            if (let Some(elem) <- elem.get("onLeftClick")) {
                level.setAction(
                    "leftClick",
                    getActionVal(game, elem)
                )
            }
            if (let Some(elem) <- elem.get("onRightClick")) {
                level.setAction(
                    "rightClick",
                    getActionVal(game, elem)
                )
            }
            if (let Some(elem) <- elem.get("onNewRound")) {
                level.setAction(
                    "newRound",
                    getActionVal(game, elem)
                )
            }
            if (let Some(elem) <- elem.get("onSelectedTileChange")) {
                level.setAction(
                    "selectedTileChange",
                    getActionVal(game, elem)
                )
            }
            if (let Some(elem) <- elem.get("onExplosion")) {
                level.setAction(
                    "explosion",
                    getActionVal(game, elem)
                )
            }
            if (let Some(elem) <- elem.get("onGameOver")) {
                level.setAction(
                    "gameOver",
                    getActionVal(game, elem)
                )
            }

            let tiles = game.resources.getTexturePack(getStringCharKey(elem, "tilesTexturePack"))
            let explodeCursor = game.resources.getTexturePack(getStringCharKey(elem, "explodeCursorTexturePack"))
            let explodePattern = game.resources.getTexturePack(getStringCharKey(elem, "explodePatternTexturePack"))
            let explosion = game.resources.getTexturePack(getStringCharKey(elem, "explosionTexturePack"))

            let initLevel = getBoolKey(elem, "init")
            if (initLevel == false && tiles.isNone() && explodeCursor.isNone() && explodePattern.isNone() &&
                explosion.isNone()) {
                return
            }

            let tileSize = Float32(getUIntKey(elem, "tileSize"))
            let padding = getIntRectKey(elem, "padding")

            level.initialize(tiles, explodeCursor, explodePattern, explosion, tileSize, padding)
        }
    }
}
