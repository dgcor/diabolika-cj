package Diabolika

import dgengine.*
import encoding.json.*
import std.collection.*

func parseLevelScores(scoreManager: LevelScoreManager, elem: JsonArray): Unit {
    var score = LevelScore()
    let scores = ArrayList<LevelScore>()
    for (val in elem.getItems()) {
        score.name = getStringKey(val, "name")
        score.level = getInt64Key(val, "level")
        score.score = getInt64Key(val, "score")
        scores.append(score)
    }
    scoreManager.set(scores)
}
