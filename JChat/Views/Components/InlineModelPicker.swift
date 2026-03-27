//
//  InlineModelPicker.swift
//  JChat
//

import Foundation
import SwiftData
import SwiftUI
#if os(macOS)
    import AppKit
#endif

struct InlineModelPicker: View {
    @Binding var selectedModelID: String?
    @Bindable var modelManager: ModelManager
    @Query(sort: \CachedModel.name) private var cachedModels: [CachedModel]

    @State private var showingPopover = false
    @State private var showingFullManager = false
    @State private var pickerSearchText = ""

    var body: some View {
        Button {
            showingPopover = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .appFont(.caption, weight: .semibold)
                    .foregroundStyle(.secondary)

                Text(selectedModelName)
                    .appFont(.body, design: .rounded, weight: .semibold)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .appFont(.caption2, weight: .semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.small)
        .popover(isPresented: $showingPopover) {
            pickerPopover
        }
        .sheet(isPresented: $showingFullManager) {
            ModelManagerView(modelManager: modelManager)
        }
    }

    private var selectedModelName: String {
        guard let id = selectedModelID else { return "Select Model" }
        return ModelNaming.displayName(forModelID: id, namesByID: modelNamesByID)
    }

    private var modelNamesByID: [String: String] {
        ModelNaming.namesByID(from: cachedModels)
    }

    private var pickerPopover: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose a Model")
                        .appFont(.body, design: .rounded, weight: .bold)
                    Text("\(cachedModels.count) cached models")
                        .appFont(.caption, design: .rounded, weight: .medium)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Open Manager") {
                    showingPopover = false
                    showingFullManager = true
                }
                .appFont(.caption, design: .rounded, weight: .semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .appFont(.caption, weight: .semibold)
                    .foregroundStyle(.secondary)

                TextField("Search models, IDs, providers...", text: $pickerSearchText)
                    .textFieldStyle(.plain)
                    .appFont(.subheadline, weight: .medium)

                if !pickerSearchText.isEmpty {
                    Button {
                        pickerSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(.bar)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    let favorites = filteredFavorites
                    if !favorites.isEmpty {
                        sectionHeader("Favorites")
                        ForEach(favorites, id: \.id) { model in
                            modelPickerRow(model)
                        }
                    }

                    let allFiltered = filteredAllModels
                    if !allFiltered.isEmpty {
                        sectionHeader("All Models")
                        ForEach(allFiltered, id: \.id) { model in
                            modelPickerRow(model)
                        }
                    } else if !pickerSearchText.isEmpty {
                        Text("No models match \"\(pickerSearchText)\"")
                            .appFont(.subheadline, weight: .medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 390)

            Divider()

            Button {
                showingPopover = false
                showingFullManager = true
            } label: {
                HStack {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Browse Full Model Manager")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .appFont(.subheadline, design: .rounded, weight: .semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 460)
    }

    private var filteredFavorites: [CachedModel] {
        let favorites = modelManager.sorted(cachedModels.filter { $0.isFavorite }, by: modelManager.sortOrder)
        if pickerSearchText.isEmpty { return favorites }
        let query = pickerSearchText.lowercased()
        return favorites.filter {
            $0.name.lowercased().contains(query) ||
                $0.id.lowercased().contains(query) ||
                $0.providerName.lowercased().contains(query)
        }
    }

    private var filteredAllModels: [CachedModel] {
        let all = modelManager.sorted(cachedModels.filter { !$0.isFavorite }, by: modelManager.sortOrder)
        if pickerSearchText.isEmpty { return Array(all.prefix(70)) }
        let query = pickerSearchText.lowercased()
        return all.filter {
            $0.name.lowercased().contains(query) ||
                $0.id.lowercased().contains(query) ||
                $0.providerName.lowercased().contains(query)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .appFont(.caption2, design: .rounded, weight: .semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 6)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private func modelPickerRow(_ model: CachedModel) -> some View {
        Button {
            selectedModelID = model.id
            showingPopover = false
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(model.uiDisplayName)
                            .appFont(.subheadline, design: .rounded, weight: .semibold)
                            .lineLimit(1)

                        if model.isFree {
                            BadgeCapsule(text: "FREE", color: .green)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(model.modelSlug)
                        Text("•")
                        Text("\(model.contextLengthFormatted) ctx")
                        Text("•")
                        Text(compactPrice(for: model))
                            .foregroundStyle(model.isFree ? .green : .secondary)
                            .lineLimit(1)
                    }
                    .appFont(.caption, design: .rounded, weight: .medium)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if model.id == selectedModelID {
                    Image(systemName: "checkmark")
                        .appFont(.caption, weight: .bold)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(model.id == selectedModelID ? Color.accentColor.opacity(0.14) : Color.clear)
        )
    }

    private func compactPrice(for model: CachedModel) -> String {
        guard !model.isFree else { return "Free" }
        return "$\(model.promptPricePerMillion.formattedPrice) / $\(model.completionPricePerMillion.formattedPrice)"
    }
}

#Preview {
    InlineModelPicker(
        selectedModelID: .constant("anthropic/claude-sonnet-4"),
        modelManager: ModelManager()
    )
    .modelContainer(for: [Chat.self, Message.self, AppSettings.self, Character.self, CachedModel.self], inMemory: true)
}
