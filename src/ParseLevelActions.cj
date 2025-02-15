package Diabolika

import dgengine.*
import encoding.json.*

func parseLevelAddHighScore(elem: JsonValue): ?Action {
    ActLevelAddHighScore(
        getStringCharKey(elem, "level"),
        getStringCharKey(elem, "scoreName"),
        Int64(getIntKey(elem, "scoreLevel")),
        getInt64Key(elem, "score")
    )
}

func parseLevelLoadGame(elem: JsonValue): ?Action {
    ActLevelLoadGame(
        getStringCharKey(elem, "level"),
        getStringCharKey(elem, "file")
    )
}

func parseLevelMakeMove(elem: JsonValue): ?Action {
    ActLevelMakeMove(getStringCharKey(elem, "level"))
}

func parseLevelMoveSelectedTile(elem: JsonValue): ?Action {
    let offset = getVector2iKey(elem, "offset")
    return ActLevelMoveSelectedTile(
        getStringCharKey(elem, "level"),
        (Int64(offset.x), Int64(offset.y))
    )
}

func parseLevelNewGame(elem: JsonValue): ?Action {
    ActLevelNewGame(getStringCharKey(elem, "level"))
}

func parseLevelPause(elem: JsonValue): ?Action {
    ActLevelPause(
        getStringCharKey(elem, "level"),
        getBoolKey(elem, "pause", default: true)
    )
}

func parseLevelQueueUnit(elem: JsonValue): ?Action {
    ActLevelQueueUnit(
        getStringCharKey(elem, "level"),
        getStringCharKey(elem, "unit")
    )
}

func parseLevelRotateSelectedUnit(elem: JsonValue): ?Action {
    ActLevelRotateSelectedUnit(getStringCharKey(elem, "level"))
}

func parseLevelSaveGame(elem: JsonValue): ?Action {
    ActLevelSaveGame(
        getStringCharKey(elem, "level"),
        getStringCharKey(elem, "file")
    )
}

func parseLevelSelectTile(elem: JsonValue): ?Action {
    let offset = getVector2iKey(elem, "position")
    return ActLevelSelectTile(
        getStringCharKey(elem, "level"),
        (Int64(offset.x), Int64(offset.y))
    )
}

func parseLevelSelectUnitQueue(elem: JsonValue): ?Action {
    ActLevelSelectUnitQueue(
        getStringCharKey(elem, "level"),
        getInt64Key(elem, "queue", default: -1)
    )
}

func parseLevelSetShader(elem: JsonValue): ?Action {
    ActLevelSetShader(
        getStringCharKey(elem, "level"),
        getStringCharKey(elem, "shader")
    )
}
