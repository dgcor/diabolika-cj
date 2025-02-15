package Diabolika

enum UnitLink {
    | NoLink
    | Unidirectional
    | Bidirectional
    | LinkUnit

    static func get(str: String, default!: UnitLink): UnitLink {
        match (str.toAsciiLower()) {
            case "looped" => NoLink
            case "unidirectional" => Unidirectional
            case "bidirectional" => Bidirectional
            case "unit" => LinkUnit
            case _ => default
        }
    }
}
