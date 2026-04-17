import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    var isAuthorized = false
    var todayActivity = DailyActivity(date: .now)

    private let store = HKHealthStore()

    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.appleExerciseTime),
        HKObjectType.workoutType()
    ]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchTodayActivity()
        } catch {
            print("HealthKit auth failed: \(error)")
        }
    }

    func fetchTodayActivity() async {
        let start = Calendar.current.startOfDay(for: .now)
        let end = Date.now

        async let steps = fetchSum(.stepCount, unit: .count(), start: start, end: end)
        async let calories = fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        async let exercise = fetchSum(.appleExerciseTime, unit: .minute(), start: start, end: end)
        async let workouts = fetchWorkouts(start: start, end: end)

        todayActivity = DailyActivity(
            date: start,
            steps: Int(await steps),
            activeCalories: await calories,
            exerciseMinutes: await exercise,
            workouts: await workouts
        )
    }

    // MARK: - Private

    private func fetchSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double {
        let type = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: type, predicate: predicate), options: .cumulativeSum)
        do {
            let result = try await descriptor.result(for: store)
            return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
        } catch {
            print("Failed to fetch \(identifier): \(error)")
            return 0
        }
    }

    private func fetchWorkouts(start: Date, end: Date) async -> [WorkoutEntry] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sortDescriptor = SortDescriptor(\HKWorkout.startDate, order: .reverse)
        let descriptor = HKSampleQueryDescriptor<HKWorkout>(
            predicates: [.workout(predicate)],
            sortDescriptors: [sortDescriptor]
        )
        do {
            let samples = try await descriptor.result(for: store)
            return samples.map { workout in
                WorkoutEntry(
                    type: workout.workoutActivityType,
                    duration: workout.duration,
                    calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    distance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                    date: workout.startDate
                )
            }
        } catch {
            print("Failed to fetch workouts: \(error)")
            return []
        }
    }
}
