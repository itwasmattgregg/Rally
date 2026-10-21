import HealthKit
import SwiftUI

struct WorkoutTypeSheet: View {
    @Environment(MatchSession.self) private var match
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(HKWorkoutActivityType.rallySelectable, id: \.rawValue) { type in
                    Button {
                        match.activityType = type
                        dismiss()
                    } label: {
                        HStack {
                            Text(type.rallyDisplayName)
                                .foregroundStyle(ScoreTheme.ink)
                            Spacer()
                            if type == match.activityType {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(ScoreTheme.home)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    WorkoutTypeSheet()
        .environment(MatchSession())
}
