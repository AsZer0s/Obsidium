//
//  ObsidianSlab.swift
//  Obsidium
//
//  The signature silhouette: a slab with three rounded corners and one cut
//  (chamfered) top-right corner — like a struck piece of obsidian. The cut edge
//  is where the spectral sheen catches the light.
//

import SwiftUI

/// A rounded rectangle whose top-right corner is sliced off at 45°.
struct ObsidianSlab: Shape {
    var cornerRadius: CGFloat = Theme.Radius.card
    var chamfer: CGFloat = Theme.Radius.chamfer

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let r = min(cornerRadius, min(w, h) / 2)
        let c = min(chamfer, min(w, h) / 2)

        var p = Path()
        p.move(to: CGPoint(x: r, y: 0))
        p.addLine(to: CGPoint(x: w - c, y: 0))          // top edge
        p.addLine(to: CGPoint(x: w, y: c))              // the cut
        p.addLine(to: CGPoint(x: w, y: h - r))          // right edge
        p.addArc(center: CGPoint(x: w - r, y: h - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r, y: h))              // bottom edge
        p.addArc(center: CGPoint(x: r, y: h - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: 0, y: r))              // left edge
        p.addArc(center: CGPoint(x: r, y: r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// Just the cut edge, as an open line — stroked with the spectral sheen.
struct ObsidianFacet: Shape {
    var chamfer: CGFloat = Theme.Radius.chamfer

    func path(in rect: CGRect) -> Path {
        let c = min(chamfer, min(rect.width, rect.height) / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.width - c, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: c))
        return p
    }
}
