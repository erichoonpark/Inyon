import Foundation

enum DerivedData {
    static func lunarBirthday(from date: Date?) -> String {
        guard let date else {
            return "—"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date) + " (approx.)"
    }

    static func zodiacAnimal(from date: Date?) -> String {
        guard let date else {
            return "—"
        }
        let year = Calendar.current.component(.year, from: date)
        let zodiacAnimals = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
                            "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
        let index = (year - 1924) % 12
        let safeIndex = index < 0 ? index + 12 : index
        return zodiacAnimals[safeIndex]
    }
}
