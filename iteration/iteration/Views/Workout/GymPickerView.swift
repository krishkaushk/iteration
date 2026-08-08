import SwiftUI

struct GymPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var gymVM: GymViewModel
    var onSelect: (Gym?) -> Void
    @State private var showAddGym = false
    @State private var newGymName = ""
    @State private var newGymLocation = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if gymVM.isLoading && gymVM.gyms.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(0..<2, id: \.self) { _ in gymRowPlaceholder }
                        }
                        .redacted(reason: .placeholder)
                    } else if gymVM.gyms.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Text("No gyms yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appMuted)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(gymVM.gyms) { gym in
                                    Button {
                                        onSelect(gym)
                                        dismiss()
                                    } label: {
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
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.appMuted)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 14)
                                    }
                                }
                            }
                        }
                    }

                    Button {
                        onSelect(nil)
                        dismiss()
                    } label: {
                        Text("Skip — no gym")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appMuted)
                            .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Select Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if gymVM.isMutating {
                        ProgressView().tint(Color.appMuted)
                    } else {
                        Button { showAddGym = true } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }
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
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color.appMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
