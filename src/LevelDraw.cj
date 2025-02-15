package Diabolika

import cjsfml.graphics.*
import cjsfml.system.*
import dgengine.*
import std.collection.*
import std.math.*

class LevelDraw {
    static func addExplosionAnim(level: Level, anim: Animation): Unit {
        if (let Some(explosionTexturePack) <- level.explosionTexturePack) {
            addExplosionAnim(anim, explosionTexturePack, 0)
        }
    }

    static func addExplosionAnim(anim: Animation, texturePack: TexturePack, direction: Int32): Unit {
        var animInfo = texturePack.getAnimation(0, direction)
        animInfo.animType = AnimationType.PlayOnce
        if (animInfo.refresh == Time.zero) {
            animInfo.refresh = Time(milliseconds: 50)
        }
        anim.setAnimation(texturePack, animInfo)
        anim.visible = true
    }

    static func setTileAnimationPosition(level: Level, anim: Animation, boardPos: (Int64, Int64)): Unit {
        let animSize = anim.size
        var drawCoord = level.board.toDrawCoord(boardPos)
        drawCoord.x = drawCoord.x - animSize.x + level.board.tileSize
        drawCoord.y = drawCoord.y - animSize.y + level.board.tileSize
        anim.position = drawCoord
    }

    static func updateBoardAnimations(level: Level, game: Game): Bool {
        var allFinished = true
        for (cell in level.board) {
            cell.tile.update(game)

            var finished = cell.anim.hasPlayOnceAnimationFinished
            if (finished == false) {
                let levelRect = FloatRect(Vector2f(), level.surface.size)
                let animRect = FloatRect(cell.anim.drawPosition, cell.anim.size)
                finished = levelRect.intersects(animRect).isNone()
            }
            if (finished == true) {
                cell.anim.visible = false
            } else {
                allFinished = false
                cell.anim.update(game)
            }
            if (let Some(unit) <- cell.unit) {
                unit.update(game)
            }
        }
        return allFinished
    }

    static func updateSelectedTile(level: Level, game: Game): Unit {
        var boardPos = level.surface.getPosition(game.mousePositionf)
        boardPos.x -= level.board.padding.left
        boardPos.y -= level.board.padding.top
        let newSelectedTile = (Int64(floor((boardPos.x / level.boardRect.width) * Float32(level.board.size[0]))), Int64(floor(
                (boardPos.y / level.boardRect.height) * Float32(level.board.size[1]))))
        level.selectTile(game, newSelectedTile)
    }

    static func updateSelectedTileAnimation(level: Level, game: Game): Unit {
        level.selectedTileAnim.visible = false
        if (level.board.isCoordValid(level.gameState.selectedPosition) == false) {
            return
        }
        if (level.gameState.units > 0 && level.unitManager.hasSelectedUnit) {
            let selectedUnit = level.unitManager.selectedUnit.getOrThrow()
            if (level.selectedTileAnim.texturePack.isSome()) {
                level.selectedTileAnim.setAnimation(None, 0, 0, true, true)
            }

            let direction = selectedUnit.direction
            let vecTex = ArrayList<TextureInfo>()
            var offsetY = 0.0f32
            if (let Some(ti) <- selectedUnit.getTexture(direction)) {
                offsetY = Float32(ti.textureRect.height) - level.board.tileSize
                vecTex.append(ti)
            }

            let exploderPatterns = selectedUnit.cls.explodePatterns
            if (Int64(direction) < exploderPatterns.size && level.explodePatternTexturePack.isSome()) {
                if (let Some(ti) <- level.explodePatternTexturePack?.get(0) ?? None) {
                    var ti2 = ti
                    let direction = Int64(direction)
                    for (exploderPattern in exploderPatterns[direction]) {
                        var patternboardPos = level.gameState.selectedPosition
                        patternboardPos = (patternboardPos[0] + exploderPattern[0], patternboardPos[1] + exploderPattern[1])

                        if (patternboardPos[0] < 0 || patternboardPos[0] >= level.board.size[0] || patternboardPos[1] < 0 ||
                            patternboardPos[1] >= level.board.size[1]) {
                            continue
                        }
                        ti2.offset.x = (Float32(exploderPattern[0]) * level.board.tileSize) + ti.offset.x
                        ti2.offset.y = (Float32(exploderPattern[1]) * level.board.tileSize) + ti.offset.y + offsetY
                        vecTex.append(ti2)
                    }
                }
            }

            if (vecTex.isEmpty() == false) {
                level.selectedTileAnim.setTexture(vecTex, drawAfter: true)
                setTileAnimationPosition(level, level.selectedTileAnim, level.gameState.selectedPosition)
                level.selectedTileAnim.visible = true
            }
        } else if (level.gameState.units == 0) {
            if (let Some(texturePack) <- level.explodeCursorTexturePack) {
                match (level.selectedTileAnim.texturePack) {
                    case None => level.selectedTileAnim.setAnimation(texturePack, 0, 0, true, true)
                    case _ => level.selectedTileAnim.update(game)
                }
                level.selectedTileAnim.visible = true
            }
            setTileAnimationPosition(level, level.selectedTileAnim, level.gameState.selectedPosition)
        }
    }

    static func draw(level: Level, game: Game, target: RenderTarget): Unit {
        if (level.visible == false) {
            return
        }

        let origView = target.view

        level.surface.clear(Color.transparent)

        for (cell in level.board) {
            level.surface.draw(game, cell.tile)

            if (let Some(unit) <- cell.unit) {
                level.surface.draw(game, unit)
            }
        }
        for (cell in level.board) {
            level.surface.draw(game, cell.anim)
        }
        level.surface.draw(game, level.selectedTileAnim)

        var surfaceStates = RenderStates.default
        if (let Some(gameShader) <- level.gameShader) {
            let shader = gameShader.shader
            surfaceStates.shader = shader
            for (uniform in gameShader.uniforms) {
                match (uniform) {
                    case "elapsedTime" => shader.setUniform("elapsedTime", game.totalElapsedTime.seconds)
                    case "mousePosition" =>
                        if (level.hasMouseInside == true) {
                            let surfacePos = level.surface.position
                            let surfaceSize = level.surface.size
                            shader.setUniform(
                                "mousePosition",
                                GlslVec2(
                                    (game.mousePositionf.x - surfacePos.x) / surfaceSize.x,
                                    (game.mousePositionf.y - surfacePos.y) / surfaceSize.y
                                )
                            )
                        }
                    case "textureSize" => shader.setUniform("textureSize", level.surface.size)
                    case "visibleRect" =>
                        let rect = level.surface.visibleRect
                        shader.setUniform(
                            "visibleRect",
                            GlslVec4(
                                rect.left,
                                rect.top,
                                rect.width,
                                rect.height
                            )
                        )
                    case _ => ()
                }
            }
        }
        level.surface.draw(target, states: surfaceStates)

        target.view = origView
    }
}
