//
//  DesignSystemPreview.swift
//  KinakoApp
//
//  Created by Farrell Sudjatmiko on 01/11/26.
//

import SwiftUI

struct DesignSystemPreview: View {
    @State private var isHighTension: Bool = false

    var body: some View {
        ZStack {
            KinakoColor.canvasMidnight
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SANDALPHON DESIGN SYSTEM")
                            .font(.kinakoSectionHeader)
                            .tracking(2)
                            .foregroundStyle(KinakoColor.accentLavender)

                        Text("Rp 1,250,000")
                            .font(.kinakoHeroBalance)
                            .foregroundStyle(KinakoColor.textPrimary)

                        HStack {
                            Text("SAFE-TO-SPEND")
                                .font(.kinakoTelemetry)
                                .foregroundStyle(KinakoColor.textSecondary)

                            Spacer()

                            Text("STABLE")
                                .font(.kinakoTelemetry)
                                .foregroundStyle(KinakoColor.statusNormal)
                        }
                    }
                    .padding(20)
                    .astralSurface(cut: 16, accentColor: isHighTension ? KinakoColor.accentMagenta : KinakoColor.accentLavender)

                    // Secondary Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tokyo Ramen")
                                .font(.kinakoBody)
                                .foregroundStyle(KinakoColor.textPrimary)

                            Text("Dining • Split Outing")
                                .font(.kinakoTelemetry)
                                .foregroundStyle(KinakoColor.textMuted)
                        }

                        Spacer()

                        Text("¥1,200")
                            .font(.kinakoCardAmount)
                            .foregroundStyle(KinakoColor.textPrimary)
                    }
                    .padding(16)
                    .astralSurface(cut: 12)

                    // Color Palette Swatches
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        colorSwatch(title: "Midnight", color: KinakoColor.canvasMidnight)
                        colorSwatch(title: "Card", color: KinakoColor.canvasCard)
                        colorSwatch(title: "Lavender", color: KinakoColor.accentLavender)
                        colorSwatch(title: "Magenta", color: KinakoColor.accentMagenta)
                        colorSwatch(title: "Purple", color: KinakoColor.regalPurple)
                        colorSwatch(title: "Silver", color: KinakoColor.bladeSilver)
                        colorSwatch(title: "Warning", color: KinakoColor.statusWarning)
                        colorSwatch(title: "Deficit", color: KinakoColor.statusInverse)
                    }
                    .padding(.top, 8)

                    // Action Buttons for Springs & Haptics
                    HStack(spacing: 16) {
                        Button {
                            KinakoHaptic.keyPress()
                            withAnimation(.kinakoSnap) {
                                isHighTension.toggle()
                            }
                        } label: {
                            Text("Toggle Energy")
                                .font(.kinakoBody)
                                .foregroundStyle(KinakoColor.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .astralSurface(cut: 8, accentColor: KinakoColor.accentLavender, showGlow: false)
                        }

                        Button {
                            KinakoHaptic.commit()
                        } label: {
                            Text("Commit")
                                .font(.kinakoBody)
                                .foregroundStyle(KinakoColor.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .astralSurface(cut: 8, accentColor: KinakoColor.accentMagenta, showGlow: false)
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private func colorSwatch(title: String, color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(height: 36)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
            Text(title)
                .font(.kinakoTelemetry)
                .foregroundStyle(KinakoColor.textSecondary)
        }
    }
}

#Preview {
    DesignSystemPreview()
}

