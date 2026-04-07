import SwiftUI

struct PaywallView: View {
    let offer: PaywallOffer
    @Bindable var accessManager: AccessManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                    brandHeader
                    heroCard
                    featureCard
                    comparisonSection
                }
                .padding(.horizontal, AppSpacing.screenH)
                .padding(.bottom, 120)
            }
            .background(paywallBackground)
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.inkTextSecondary)
                    }
                    .buttonStyle(IconCircleButtonStyle(size: 34))
                }
            }
        }
    }

    // MARK: - Background

    private var paywallBackground: some View {
        LinearGradient(
            colors: [
                Color.inkBackground,
                Color.inkSurface,
                Color.inkAccentSoft.opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: 8) {
            Text("INKAKADEMİ")
                .font(.system(size: 24, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Color.inkTextPrimary)

            Text(offer.eyebrow)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.inkTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 12)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Lock preview area
            lockPreview
                .padding(.bottom, AppSpacing.lg)

            // Title + subtitle
            VStack(alignment: .leading, spacing: 8) {
                Text(offer.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.inkTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(offer.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, AppSpacing.lg)

            // Price block — flush left, no spacer
            PriceBlock(
                price: offer.price,
                originalPrice: offer.originalPrice,
                badge: offer.badge
            )
            .padding(.bottom, AppSpacing.md)

            // Info pills
            HStack(alignment: .center, spacing: 10) {
                statPill("1 yıl erişim", icon: "clock")
                statPill(offer.tier.title, icon: "medal.fill")
            }
        }
        .padding(AppSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: AppRadii.xxl, style: .continuous)
                .fill(Color.inkSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.xxl, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: AppShadows.cardRadius, x: 0, y: AppShadows.cardY)
    }

    // MARK: - Lock Preview

    private var lockPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadii.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.inkSurfaceSecondary, Color.inkSurface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 190)

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    moduleThumb(number: "07")
                    moduleThumb(number: "06")
                    moduleThumb(number: "05")
                }

                ZStack {
                    Circle()
                        .fill(Color.inkTextPrimary.opacity(0.08))
                        .frame(width: 68, height: 68)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.inkTextPrimary.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func moduleThumb(number: String) -> some View {
        RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
            .fill(Color.inkSurface)
            .frame(width: 80, height: 86)
            .overlay(alignment: .topLeading) {
                Text(number)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.inkAccent)
                    .padding(10)
            }
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.inkTextTertiary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                    .stroke(Color.inkBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private func statPill(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Color.inkTextSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.inkSurfaceSecondary)
        .clipShape(Capsule())
    }

    // MARK: - Feature Card

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            featureBlock(
                title: "Açılacak Özellikler",
                items: offer.primaryFeatures,
                symbol: "checkmark.circle.fill",
                iconColor: .inkAccent
            )

            if !offer.secondaryFeatures.isEmpty {
                sectionDivider
                featureBlock(
                    title: "Pakete Dahil",
                    items: offer.secondaryFeatures,
                    symbol: "sparkles",
                    iconColor: .inkAccent
                )
            }

            if !offer.lockedFeatures.isEmpty {
                sectionDivider
                featureBlock(
                    title: "Sonraki Seviyede",
                    items: offer.lockedFeatures,
                    symbol: "lock.fill",
                    iconColor: .inkTextTertiary
                )
            }
        }
        .padding(AppSpacing.xxl)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.xl, style: .continuous)
                .stroke(Color.inkBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: AppShadows.softRadius, x: 0, y: AppShadows.softY)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.inkDivider)
            .frame(height: 1)
            .padding(.vertical, AppSpacing.lg)
    }

    private func featureBlock(title: String, items: [String], symbol: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)
                .padding(.bottom, 2)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    FeatureRow(
                        text: item,
                        icon: symbol,
                        iconColor: iconColor
                    )
                }
            }
        }
    }

    // MARK: - Comparison Section (Membership Tiers)

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Üyelik Seviyeleri")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.inkTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(accessManager.comparisonOffers) { comparison in
                        comparisonCard(for: comparison)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func comparisonCard(for comparison: PaywallOffer) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Badge row
            HStack(alignment: .center) {
                Circle()
                    .fill(color(for: comparison.tier).opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: medalSymbol(for: comparison.tier))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(color(for: comparison.tier))
                    }

                Spacer()

                if accessManager.currentTier == comparison.tier {
                    StatusChip(
                        text: "Aktif",
                        foreground: .white,
                        background: Color.inkTextPrimary
                    )
                }
            }

            // Title + caption
            VStack(alignment: .leading, spacing: 4) {
                Text(comparison.tier.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.inkTextPrimary)
                Text(comparison.comparisonCaption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Feature rows — match FeatureRow alignment
            VStack(alignment: .leading, spacing: 8) {
                ForEach(comparison.primaryFeatures.prefix(3), id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(color(for: comparison.tier))
                            .frame(width: 18, alignment: .center)
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.inkTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(width: 240, alignment: .topLeading)
        .background(Color.inkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadii.card, style: .continuous)
                .stroke(color(for: comparison.tier).opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: AppShadows.softRadius, x: 0, y: AppShadows.softY)
    }

    // MARK: - Sticky Action Bar

    private var actionBar: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await accessManager.purchase(offer)
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    if accessManager.isProcessingPurchase {
                        ProgressView()
                            .tint(Color.white)
                    }

                    Text(accessManager.currentTier >= offer.tier ? "PAKET ZATEN AÇIK" : offer.ctaTitle)
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: AppRadii.md, style: .continuous)
                        .fill(accessManager.currentTier >= offer.tier ? Color.inkTextTertiary : Color.inkAccent)
                )
            }
            .buttonStyle(.plain)
            .disabled(accessManager.isProcessingPurchase || accessManager.currentTier >= offer.tier)

            Text(offer.footnote)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppSpacing.screenH)
        .padding(.top, 14)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.inkSurface.opacity(0.6))
                )
                .ignoresSafeArea()
        )
    }

    // MARK: - Helpers

    private func medalSymbol(for tier: MembershipTier) -> String {
        switch tier {
        case .demo: return "sparkles"
        case .cirak: return "star.fill"
        case .kalfa: return "medal.fill"
        case .proKalfa: return "crown.fill"
        }
    }

    private func color(for tier: MembershipTier) -> Color {
        switch tier {
        case .demo: return .inkTextTertiary
        case .cirak: return .inkTeal
        case .kalfa: return .inkIndigo
        case .proKalfa: return .inkRose
        }
    }
}

#Preview {
    PaywallView(
        offer: .forTier(.cirak),
        accessManager: AccessManager()
    )
}