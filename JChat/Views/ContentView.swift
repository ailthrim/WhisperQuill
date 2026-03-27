//
//  ContentView.swift
//  JChat
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var conversationStore: ConversationStore
    @State private var modelManager = ModelManager()

    // previewForceSetup: pins needsSetup=true in previews without touching the real keychain
    private let previewForceSetup: Bool

    init(previewStore: ConversationStore? = nil, previewForceSetup: Bool = false) {
        _conversationStore = State(initialValue: previewStore ?? ConversationStore())
        self.previewForceSetup = previewForceSetup
    }

    // nil = follow system text size preference; non-nil = user's Cmd+/- override
    @State private var dynamicTypeSizeOverride: DynamicTypeSize?
    @State private var hasAPIKey = false

    // Setup screen only — sidebar owns its own copies for normal use
    @State private var showingSettingsFromSetup = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.createdAt, order: .reverse) private var chats: [Chat]

    var body: some View {
        NavigationSplitView {
            SidebarView(store: conversationStore, modelManager: modelManager)
                .navigationSplitViewColumnWidth(min: 270, ideal: 300, max: 360)
        } detail: {
            if needsSetup {
                ZStack {
                    setupRequiredView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let selectedChat = conversationStore.selectedChat {
                ConversationPane(
                    store: conversationStore,
                    modelManager: modelManager,
                    chat: selectedChat
                )
            } else {
                EmptyStateView()
            }
        }
        .background(CanvasBackground())
        // Push the zoom scale factor into the environment so .appFont() picks it up.
        .environment(\.textScaleFactor, (dynamicTypeSizeOverride ?? .defaultSize).scaleFactor)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    conversationStore.createNewChat(in: modelContext)
                } label: {
                    Label("New Chat", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingSettingsFromSetup) {
            SettingsView()
        }
        .onChange(of: showingSettingsFromSetup) { _, isShowing in
            if !isShowing {
                loadAPIKeyStatus()
            }
        }
        .task {
            loadDynamicTypeSizeOverride()
            loadAPIKeyStatus()
            await modelManager.refreshIfStale(context: modelContext)
            await conversationStore.generatePendingAutoTitles(in: modelContext)
            selectFirstChatIfNeeded()
        }
        .onChange(of: chats.count) { _, _ in
            selectFirstChatIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.newChat)) { _ in
            conversationStore.createNewChat(in: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.textZoomIn)) { _ in
            handleZoomAction(.increase)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.textZoomOut)) { _ in
            handleZoomAction(.decrease)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppCommandNotification.textZoomReset)) { _ in
            handleZoomAction(.reset)
        }
    }

    // MARK: - Dynamic Type zoom

    /// Load any persisted Cmd+/- override from AppSettings.
    private func loadDynamicTypeSizeOverride() {
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        if let key = settings.dynamicTypeSizeOverride {
            dynamicTypeSizeOverride = DynamicTypeSize.from(persistenceKey: key)
        }
    }

    /// Save the current override (or nil for "follow system") to AppSettings.
    private func saveDynamicTypeSizeOverride() {
        let settings = AppSettings.fetchOrCreate(in: modelContext)
        settings.dynamicTypeSizeOverride = dynamicTypeSizeOverride?.persistenceKey
        try? modelContext.save()
    }

    /// Handle Cmd+/-, Cmd+0 from the menu bar.
    private func handleZoomAction(_ action: TextZoomAction) {
        let current = dynamicTypeSizeOverride ?? .defaultSize
        switch action {
        case .increase:
            if let bigger = current.steppedUp() {
                dynamicTypeSizeOverride = bigger
            }
        case .decrease:
            if let smaller = current.steppedDown() {
                dynamicTypeSizeOverride = smaller
            }
        case .reset:
            dynamicTypeSizeOverride = nil
        }
        saveDynamicTypeSizeOverride()
    }

    // MARK: - Helpers

    private func selectFirstChatIfNeeded() {
        if conversationStore.selectedChat == nil {
            conversationStore.selectedChat = chats.first
        }
    }

    private func loadAPIKeyStatus() {
        do {
            let key = try KeychainManager.shared.loadAPIKey().trimmingCharacters(in: .whitespacesAndNewlines)
            hasAPIKey = !key.isEmpty
        } catch {
            hasAPIKey = false
        }
    }

    private var needsSetup: Bool {
        previewForceSetup || !hasAPIKey
    }

    private var setupRequiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .appFont(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Add your OpenRouter API key to get started.")
                .appFont(.body, design: .rounded, weight: .medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            Button("Open Settings") {
                showingSettingsFromSetup = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .glassEffect(in: .rect(cornerRadius: 22))
    }

}

// MARK: - Empty state

private struct EmptyStateView: View {
    @Environment(\.textScaleFactor) private var scaleFactor

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 40 * scaleFactor, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Select a chat or start a new one")
                .appFont(.title, design: .rounded, weight: .bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

@MainActor
private func makePreviewContainer() throws -> (ModelContainer, Chat) {
    let schema = Schema([Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    let ctx = container.mainContext

    // Seed a few favorite models so the inline model picker has something to show
    let models: [(String, String)] = [
        ("anthropic/claude-sonnet-4-5", "Claude Sonnet 4.5"),
        ("google/gemini-2.0-flash-001", "Gemini 2.0 Flash"),
        ("openai/gpt-4o", "GPT-4o"),
    ]
    for (idx, (modelID, name)) in models.enumerated() {
        let m = CachedModel(id: modelID, name: name, contextLength: 200_000, isFavorite: true, sortOrder: idx)
        ctx.insert(m)
    }

    // Primary seeded chat — "What is Liquid Glass?"
    let chat = Chat(title: "What is Liquid Glass?")
    chat.selectedModelID = "anthropic/claude-sonnet-4-5"
    chat.totalPromptTokens = 1_242
    chat.totalCompletionTokens = 387
    chat.totalCost = 0.00183
    ctx.insert(chat)

    let msgs: [(MessageRole, String, Int, Int)] = [
        (.user,      "What is Liquid Glass in SwiftUI?", 18, 0),
        (.assistant, "Liquid Glass is a new dynamic material introduced in macOS/iOS 26. It provides an adaptive translucent surface that automatically responds to what's behind it — adjusting blur, reflection, and tint based on the underlying content and system appearance.", 18, 68),
        (.user,      "How do I use it in my own views?", 12, 0),
        (.assistant, "Use `.glassEffect(in: shape)` to apply the material to any view:\n\n```swift\nText(\"Hello\")\n    .padding()\n    .glassEffect(in: .rect(cornerRadius: 12))\n```\n\nFor interactive controls, `.buttonStyle(.glass)` gives you a first-class Liquid Glass button that handles hover, press, and dark/tinted appearances automatically.", 12, 92),
    ]
    var t = Date(timeIntervalSinceNow: -300)
    for (role, content, prompt, completion) in msgs {
        let msg = Message(role: role, content: content, promptTokens: prompt, completionTokens: completion, cost: 0.0, modelID: "anthropic/claude-sonnet-4-5")
        msg.timestamp = t
        chat.messages.append(msg)
        t += 30
    }

    // Second chat for sidebar population
    let chat2 = Chat(title: "SwiftData relationships")
    chat2.totalPromptTokens = 540
    ctx.insert(chat2)

    try ctx.save()
    return (container, chat)
}

#Preview("Empty / Setup") {
    ContentView(previewForceSetup: true)
        .frame(minWidth: 900, minHeight: 700)
        .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
#Preview("Active Chat") {
    // Seed data and pre-select the primary chat so ConversationPane renders immediately.
    // Falls back to an empty in-memory container if seeding fails, so the preview
    // still renders rather than crashing the canvas.
    let schema = Schema([Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self])
    let fallback = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    do {
        let (container, chat) = try makePreviewContainer()
        let store = ConversationStore()
        store.selectedChat = chat
        return ContentView(previewStore: store)
            .frame(minWidth: 900, minHeight: 700)
            .modelContainer(container)
    } catch {
        return ContentView()
            .frame(minWidth: 900, minHeight: 700)
            .modelContainer(fallback)
    }
}
