import HealthKit

extension HKWorkoutActivityType {
    /// Types Rally can start as a HealthKit workout, sorted for the picker.
    static var rallySelectable: [HKWorkoutActivityType] {
        [
            .americanFootball,
            .archery,
            .australianFootball,
            .badminton,
            .barre,
            .baseball,
            .basketball,
            .bowling,
            .boxing,
            .cardioDance,
            .climbing,
            .cooldown,
            .coreTraining,
            .cricket,
            .crossCountrySkiing,
            .crossTraining,
            .curling,
            .cycling,
            .discSports,
            .downhillSkiing,
            .elliptical,
            .equestrianSports,
            .fencing,
            .fishing,
            .fitnessGaming,
            .flexibility,
            .functionalStrengthTraining,
            .golf,
            .gymnastics,
            .handCycling,
            .handball,
            .highIntensityIntervalTraining,
            .hiking,
            .hockey,
            .hunting,
            .jumpRope,
            .kickboxing,
            .lacrosse,
            .martialArts,
            .mindAndBody,
            .mixedCardio,
            .other,
            .paddleSports,
            .pickleball,
            .pilates,
            .play,
            .preparationAndRecovery,
            .racquetball,
            .rowing,
            .rugby,
            .running,
            .sailing,
            .skatingSports,
            .snowboarding,
            .snowSports,
            .soccer,
            .socialDance,
            .softball,
            .squash,
            .stairClimbing,
            .stairs,
            .stepTraining,
            .surfingSports,
            .swimming,
            .tableTennis,
            .taiChi,
            .tennis,
            .trackAndField,
            .traditionalStrengthTraining,
            .volleyball,
            .walking,
            .waterFitness,
            .waterPolo,
            .waterSports,
            .wheelchairRunPace,
            .wheelchairWalkPace,
            .wrestling,
            .yoga
        ]
        .sorted { $0.rallyDisplayName.localizedCaseInsensitiveCompare($1.rallyDisplayName) == .orderedAscending }
    }

    var rallyDisplayName: String {
        switch self {
        case .americanFootball: "American Football"
        case .archery: "Archery"
        case .australianFootball: "Australian Football"
        case .badminton: "Badminton"
        case .barre: "Barre"
        case .baseball: "Baseball"
        case .basketball: "Basketball"
        case .bowling: "Bowling"
        case .boxing: "Boxing"
        case .cardioDance: "Cardio Dance"
        case .climbing: "Climbing"
        case .cooldown: "Cooldown"
        case .coreTraining: "Core Training"
        case .cricket: "Cricket"
        case .crossCountrySkiing: "Cross Country Skiing"
        case .crossTraining: "Cross Training"
        case .curling: "Curling"
        case .cycling: "Cycling"
        case .discSports: "Disc Sports"
        case .downhillSkiing: "Downhill Skiing"
        case .elliptical: "Elliptical"
        case .equestrianSports: "Equestrian Sports"
        case .fencing: "Fencing"
        case .fishing: "Fishing"
        case .fitnessGaming: "Fitness Gaming"
        case .flexibility: "Flexibility"
        case .functionalStrengthTraining: "Functional Strength"
        case .golf: "Golf"
        case .gymnastics: "Gymnastics"
        case .handCycling: "Hand Cycling"
        case .handball: "Handball"
        case .highIntensityIntervalTraining: "HIIT"
        case .hiking: "Hiking"
        case .hockey: "Hockey"
        case .hunting: "Hunting"
        case .jumpRope: "Jump Rope"
        case .kickboxing: "Kickboxing"
        case .lacrosse: "Lacrosse"
        case .martialArts: "Martial Arts"
        case .mindAndBody: "Mind and Body"
        case .mixedCardio: "Mixed Cardio"
        case .other: "Other"
        case .paddleSports: "Paddle Sports"
        case .pickleball: "Pickleball"
        case .pilates: "Pilates"
        case .play: "Play"
        case .preparationAndRecovery: "Prep and Recovery"
        case .racquetball: "Racquetball"
        case .rowing: "Rowing"
        case .rugby: "Rugby"
        case .running: "Running"
        case .sailing: "Sailing"
        case .skatingSports: "Skating"
        case .snowboarding: "Snowboarding"
        case .snowSports: "Snow Sports"
        case .soccer: "Soccer"
        case .socialDance: "Social Dance"
        case .softball: "Softball"
        case .squash: "Squash"
        case .stairClimbing: "Stair Climbing"
        case .stairs: "Stairs"
        case .stepTraining: "Step Training"
        case .surfingSports: "Surfing"
        case .swimming: "Swimming"
        case .tableTennis: "Table Tennis"
        case .taiChi: "Tai Chi"
        case .tennis: "Tennis"
        case .trackAndField: "Track and Field"
        case .traditionalStrengthTraining: "Strength Training"
        case .volleyball: "Volleyball"
        case .walking: "Walking"
        case .waterFitness: "Water Fitness"
        case .waterPolo: "Water Polo"
        case .waterSports: "Water Sports"
        case .wheelchairRunPace: "Wheelchair Run"
        case .wheelchairWalkPace: "Wheelchair Walk"
        case .wrestling: "Wrestling"
        case .yoga: "Yoga"
        default: "Workout"
        }
    }

    /// Sensible indoor/outdoor default for HealthKit configuration.
    var rallyLocationType: HKWorkoutSessionLocationType {
        switch self {
        case .cycling, .hiking, .running, .walking, .wheelchairRunPace, .wheelchairWalkPace,
             .crossCountrySkiing, .downhillSkiing, .snowboarding, .snowSports, .skatingSports,
             .golf, .fishing, .hunting, .equestrianSports, .surfingSports, .sailing,
             .paddleSports, .rowing, .handCycling:
            .outdoor
        case .swimming:
            .indoor
        default:
            .indoor
        }
    }

    var rallySwimmingLocationType: HKWorkoutSwimmingLocationType? {
        guard self == .swimming else { return nil }
        return rallyLocationType == .outdoor ? .openWater : .pool
    }
}
