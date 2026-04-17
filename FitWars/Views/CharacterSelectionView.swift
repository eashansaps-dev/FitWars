import SwiftUI

struct CharacterSelectionView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedCharacter") private var selectedCharacter = CharacterModel.maleDefault.rawValue
    @State private var selection: CharacterModel = .maleDefault

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text(AppConfig.appName)
                .font(.largeTitle.bold())

            Text("Choose your fighter")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                ForEach(CharacterModel.allCases, id: \.self) { model in
                    characterOption(model)
                }
            }

            Spacer()

            Button {
                selectedCharacter = selection.rawValue
                hasCompletedOnboarding = true
            } label: {
                Text("Let's Fight")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func characterOption(_ model: CharacterModel) -> some View {
        VStack(spacing: 12) {
            Image(systemName: model == .maleDefault ? "figure.martial.arts" : "figure.kickboxing")
                .font(.system(size: 60))
                .foregroundStyle(selection == model ? .orange : .gray)

            Text(model.displayName)
                .font(.subheadline)
                .foregroundStyle(selection == model ? .primary : .secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(selection == model ? Color.orange : Color.gray.opacity(0.3), lineWidth: 2)
        )
        .onTapGesture { selection = model }
    }
}
