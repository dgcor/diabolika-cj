package Diabolika

struct LevelStateObject {
    var state = GameOver

    var level = 0
    var score = 0
    var chain = 0

    var walls = 0
    var units = 0
    var detonators = 0

    var selectedPosition = (0, 0)
}
