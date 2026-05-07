//
//  RRAdaptiveModalContainer.swift
//  Rentory
//
//  Created by OpenAI on 04/05/2026.
//

import SwiftUI

struct RRAdaptiveModalContainer<Header: View, TopBar: View, Content: View, Footer: View>: View {
    var preferredWidth: CGFloat
    var preferredHeight: CGFloat
    var minWidth: CGFloat
    var minHeight: CGFloat

    private let header: Header
    private let topBar: TopBar
    private let content: Content
    private let footer: Footer

    init(
        preferredWidth: CGFloat,
        preferredHeight: CGFloat,
        minWidth: CGFloat,
        minHeight: CGFloat,
        @ViewBuilder header: () -> Header,
        @ViewBuilder topBar: () -> TopBar = { EmptyView() },
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer = { EmptyView() }
    ) {
        self.preferredWidth = preferredWidth
        self.preferredHeight = preferredHeight
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.header = header()
        self.topBar = topBar()
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        Group {
            if PlatformLayout.isPhone {
                phoneContainer
            } else {
                wideContainer
            }
        }
    }

    private var wideContainer: some View {
        ZStack {
            RRBackgroundView()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                if !isTopBarEmpty {
                    topBar
                        .padding(.horizontal, 28)
                        .padding(.bottom, 20)
                }

                ScrollView {
                    content
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .scrollIndicators(.hidden)

                if !isFooterEmpty {
                    footer
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)
                        .background(.thinMaterial)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(RRColours.border.opacity(0.24))
                                .frame(height: 1)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RRTheme.panelMaterial,
                in: RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous)
                    .stroke(RRColours.border.opacity(0.24), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(RRTheme.strongShadowOpacity), radius: 28, x: 0, y: 16)
            .frame(
                minWidth: minWidth,
                idealWidth: preferredWidth,
                maxWidth: preferredWidth,
                minHeight: minHeight,
                idealHeight: preferredHeight,
                maxHeight: preferredHeight,
                alignment: .top
            )
            .padding(24)
        }
        .frame(
            minWidth: minWidth,
            idealWidth: preferredWidth,
            maxWidth: preferredWidth,
            minHeight: minHeight,
            idealHeight: preferredHeight,
            maxHeight: preferredHeight,
            alignment: .center
        )
    }

    private var phoneContainer: some View {
        ZStack {
            RRBackgroundView()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                if !isTopBarEmpty {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }

                ScrollView {
                    content
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .scrollIndicators(.hidden)

                if !isFooterEmpty {
                    footer
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.thinMaterial)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(RRColours.border.opacity(0.24))
                                .frame(height: 1)
                        }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var isTopBarEmpty: Bool {
        TopBar.self == EmptyView.self
    }

    private var isFooterEmpty: Bool {
        Footer.self == EmptyView.self
    }
}
