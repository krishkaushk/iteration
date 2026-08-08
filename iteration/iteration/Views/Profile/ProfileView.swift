import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var gymVM = GymViewModel()
    @State private var showAddGym = false
    @State private var showExercises = false
    @State private var newGymName = ""
    @State private var newGymLocation = ""

    private var monthlyGoalBinding: Binding<Int> {
        Binding(
            get: { authViewModel.monthlyGoal },
            set: { newValue in
                let clamped = max(1, newValue)
                authViewModel.monthlyGoal = clamped
                Task { await authViewModel.updateMonthlyGoal(clamped) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Gyms Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("MY GYMS")
                                    .font(.system(size: 11, weight: .medium))
                                    .tracking(1)
                                    .foregroundStyle(Color.appMuted)

                                Spacer()

                                if gymVM.isMutating {
                                    ProgressView().tint(Color.appMuted)
                                } else {
                                    Button { showAddGym = true } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color.appPrimary)
                                    }
                                }
                            }

                            if gymVM.isLoading && gymVM.gyms.isEmpty {
                                VStack(spacing: 8) {
                                    gymRowPlaceholder
                                    gymRowPlaceholder
                                }
                                .redacted(reason: .placeholder)
                            } else if gymVM.gyms.isEmpty {
                                Text("No gyms added yet")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.appMuted)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                ForEach(gymVM.gyms) { gym in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(gym.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(Color.appText)
                                            if !gym.location.isEmpty {
                                                Text(gym.location)
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(Color.appMuted)
                                            }
                                        }

                                        Spacer()

                                        Button {
                                            Task { await gymVM.deleteGym(gym) }
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 14))
                                                .foregroundStyle(Color.appDestructive)
                                        }
                                        .disabled(gymVM.isMutating)
                                    }
                                    .padding(14)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        // Monthly Goal
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MONTHLY GOAL")
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1)
                                .foregroundStyle(Color.appMuted)

                            HStack {
                                Text("\(authViewModel.monthlyGoal) sessions / month")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.appText)
                                Spacer()
                                Stepper("", value: monthlyGoalBinding, in: 1...60)
                                    .labelsHidden()
                            }
                            .padding(14)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Exercise Library
                        Button {
                            showExercises = true
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.appPrimary)
                                Text("Exercise Library")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.appText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appMuted)
                            }
                            .padding(14)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Spacer().frame(height: 20)

                        BlockButton(title: "SIGN OUT", isDestructive: true) {
                            authViewModel.signOut()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await gymVM.loadGyms()
            }
            .sheet(isPresented: $showExercises) {
                ExerciseListView()
            }
            .alert("Add Gym", isPresented: $showAddGym) {
                TextField("Gym name", text: $newGymName)
                TextField("Location (optional)", text: $newGymLocation)
                Button("Add") {
                    Task {
                        await gymVM.addGym(name: newGymName, location: newGymLocation)
                        newGymName = ""
                        newGymLocation = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    newGymName = ""
                    newGymLocation = ""
                }
            }
        }
    }

    private var gymRowPlaceholder: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gym Name")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appText)
                Text("Location")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
            }
            Spacer()
            Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundStyle(Color.appDestructive)
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
