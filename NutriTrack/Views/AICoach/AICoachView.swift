import SwiftUI
import SwiftData

struct AICoachView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = AICoachViewModel()

    var profil: UserProfile? { profiles.first }

    var body: some View {
        VStack(spacing: 0) {
            if profil?.aUneCleAPI == false || profil == nil {
                pasCleAPIView
            } else {
                chatInterface
            }
        }
        .navigationTitle("Coach IA")
        .background(Color.fondPrincipal)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.effacerConversation() }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Effacer la conversation")
            }
        }
        .onAppear {
            if let p = profil {
                Task {
                    await viewModel.initialiser(profil: p, context: modelContext)
                }
            }
        }
    }

    // MARK: - Interface chat

    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        if viewModel.messages.isEmpty && !viewModel.isTyping {
                            accueilView
                        }

                        ForEach(viewModel.messages) { message in
                            bulleMessage(message)
                                .id(message.id)
                        }

                        if viewModel.isTyping {
                            indicateurTypage
                        }
                    }
                    .padding(Spacing.md)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let dernierID = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(dernierID, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isTyping) { _, typing in
                    if typing {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }

            Divider()

            // Questions suggérées
            if viewModel.messages.isEmpty {
                questionsSuggerees
            }

            // Barre de saisie
            barreDeMessage
        }
    }

    // MARK: - Bulle de message

    private func bulleMessage(_ message: ClaudeMessage) -> some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.cyan)
                    .frame(width: 28, height: 28)
                    .background(Color.cyan.opacity(0.15), in: Circle())
            }

            Text(message.content)
                .font(.nutriBody)
                .foregroundStyle(.primary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    message.isUser
                        ? Color.nutriGreen.opacity(0.25)
                        : Color(.secondarySystemFill)
                    , in: RoundedRectangle(
                        cornerRadius: message.isUser ? 18 : 18,
                        style: .continuous
                    )
                )
                .frame(maxWidth: 320, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer(minLength: 60) }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }

    // MARK: - Indicateur de frappe

    private var indicateurTypage: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(.cyan)
                .frame(width: 28, height: 28)
                .background(Color.cyan.opacity(0.15), in: Circle())

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(viewModel.isTyping ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                            value: viewModel.isTyping
                        )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 18))

            Spacer()
        }
        .id("typing")
    }

    // MARK: - Accueil (vide)

    private var accueilView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(.cyan)

            Text("Bonjour\(profil.map { ", \($0.prenomAffiche)" } ?? "") !")
                .font(.nutriTitle)

            Text("Je suis NutriCoach, votre assistant nutritionnel IA.\nPosez-moi vos questions ou laissez-moi analyser votre semaine.")
                .font(.nutriBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xl)
    }

    // MARK: - Questions suggérées

    private var questionsSuggerees: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.questionsSuggerees, id: \.self) { question in
                    Button(action: {
                        if let p = profil {
                            Task {
                                await viewModel.poserQuestion(question, profil: p, context: modelContext)
                            }
                        }
                    }) {
                        Text(question)
                            .font(.nutriCaption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Question suggérée : \(question)")
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Barre de message

    private var barreDeMessage: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Votre message…", text: $viewModel.messageEnCours, axis: .vertical)
                .font(.nutriBody)
                .padding(Spacing.sm)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
                .lineLimit(1...5)
                .onSubmit {
                    envoyerMessage()
                }
                .accessibilityLabel("Champ de message")

            Button(action: envoyerMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(
                        viewModel.messageEnCours.isEmpty || viewModel.isTyping
                            ? Color.secondary : Color.nutriGreen
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.messageEnCours.isEmpty || viewModel.isTyping)
            .accessibilityLabel("Envoyer")
        }
        .padding(Spacing.sm)
    }

    // MARK: - Pas de clé API

    private var pasCleAPIView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "key.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Clé API Claude manquante")
                .font(.nutriTitle2)

            Text("Pour utiliser le Coach IA, ajoutez votre clé API Claude dans le profil.")
                .font(.nutriBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Text("Obtenez votre clé sur console.anthropic.com")
                .font(.nutriCaption)
                .foregroundStyle(.cyan)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func envoyerMessage() {
        guard let p = profil else { return }
        Task {
            await viewModel.envoyerMessage(profil: p, context: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        AICoachView()
            .modelContainer(for: [
                FoodEntry.self, BodyMetric.self, UserProfile.self
            ], inMemory: true)
    }
}
