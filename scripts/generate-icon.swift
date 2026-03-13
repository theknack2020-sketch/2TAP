#!/usr/bin/env swift

import Cocoa
import CoreGraphics

// Generate a 2TAP app icon: two metallic balls on dark gradient background
let size = 1024
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// Create bitmap context
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: size, height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("❌ Failed to create context")
    exit(1)
}

let s = CGFloat(size)

// -- Background: dark gradient (deep navy to black) with subtle radial glow
let bgColors = [
    CGColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1),
    CGColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1),
    CGColor(red: 0.0, green: 0.0, blue: 0.02, alpha: 1)
]
let bgGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: bgColors as CFArray,
    locations: [0, 0.6, 1]
)!
ctx.drawRadialGradient(
    bgGradient,
    startCenter: CGPoint(x: s * 0.45, y: s * 0.55),
    startRadius: 0,
    endCenter: CGPoint(x: s * 0.5, y: s * 0.5),
    endRadius: s * 0.75,
    options: .drawsAfterEndLocation
)

// -- Helper: Draw a metallic ball
func drawBall(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
              baseH: CGFloat, baseS: CGFloat, baseB: CGFloat) {
    let ns = NSColor(hue: baseH, saturation: baseS, brightness: baseB, alpha: 1)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    ns.usingColorSpace(.deviceRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
    
    // Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: radius * 0.05, height: -radius * 0.08),
                  blur: radius * 0.25,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.6))
    ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius,
                               width: radius * 2, height: radius * 2))
    ctx.restoreGState()

    // Base ball
    ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius,
                               width: radius * 2, height: radius * 2))

    // Darker bottom edge (radial gradient)
    let darkNs = NSColor(hue: baseH, saturation: min(baseS + 0.1, 1), brightness: max(baseB - 0.3, 0), alpha: 1)
    var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0
    darkNs.usingColorSpace(.deviceRGB)?.getRed(&dr, green: &dg, blue: &db, alpha: &a)

    let ballGrad = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: r * 1.15, green: g * 1.15, blue: b * 1.15, alpha: 1),
            CGColor(red: r, green: g, blue: b, alpha: 1),
            CGColor(red: dr, green: dg, blue: db, alpha: 1)
        ] as CFArray,
        locations: [0, 0.5, 1]
    )!

    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: cx - radius, y: cy - radius,
                              width: radius * 2, height: radius * 2))
    ctx.clip()
    ctx.drawRadialGradient(
        ballGrad,
        startCenter: CGPoint(x: cx - radius * 0.2, y: cy + radius * 0.25),
        startRadius: 0,
        endCenter: CGPoint(x: cx, y: cy),
        endRadius: radius * 1.1,
        options: .drawsAfterEndLocation
    )
    ctx.restoreGState()

    // Specular highlight (main)
    ctx.saveGState()
    let hlCx = cx - radius * 0.22
    let hlCy = cy + radius * 0.32
    let hlRx = radius * 0.35
    let hlRy = radius * 0.22
    ctx.saveGState()
    ctx.translateBy(x: hlCx, y: hlCy)
    ctx.scaleBy(x: 1, y: hlRy / hlRx)
    let hlGrad = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.75),
            CGColor(red: 1, green: 1, blue: 1, alpha: 0)
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        hlGrad,
        startCenter: .zero,
        startRadius: 0,
        endCenter: .zero,
        endRadius: hlRx,
        options: []
    )
    ctx.restoreGState()
    ctx.restoreGState()

    // Small secondary highlight
    ctx.saveGState()
    let hl2Cx = cx + radius * 0.25
    let hl2Cy = cy - radius * 0.35
    let hl2Grad = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.2),
            CGColor(red: 1, green: 1, blue: 1, alpha: 0)
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        hl2Grad,
        startCenter: CGPoint(x: hl2Cx, y: hl2Cy),
        startRadius: 0,
        endCenter: CGPoint(x: hl2Cx, y: hl2Cy),
        endRadius: radius * 0.15,
        options: []
    )
    ctx.restoreGState()
}

// Draw two overlapping balls
// Orange-gold ball (left-ish, slightly larger)
drawBall(ctx: ctx, cx: s * 0.38, cy: s * 0.52, radius: s * 0.24,
         baseH: 0.08, baseS: 0.85, baseB: 0.95) // warm orange-gold

// Cool blue ball (right-ish)
drawBall(ctx: ctx, cx: s * 0.62, cy: s * 0.48, radius: s * 0.22,
         baseH: 0.58, baseS: 0.75, baseB: 0.9) // cool blue

// Subtle glow between the balls
ctx.saveGState()
let glowGrad = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        CGColor(red: 1, green: 0.9, blue: 0.7, alpha: 0.08),
        CGColor(red: 1, green: 0.9, blue: 0.7, alpha: 0)
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawRadialGradient(
    glowGrad,
    startCenter: CGPoint(x: s * 0.5, y: s * 0.5),
    startRadius: 0,
    endCenter: CGPoint(x: s * 0.5, y: s * 0.5),
    endRadius: s * 0.15,
    options: []
)
ctx.restoreGState()

// -- Save
guard let image = ctx.makeImage() else {
    print("❌ Failed to create image")
    exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: image)
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("❌ Failed to create PNG")
    exit(1)
}

let outputPath = "\(outputDir)/app-icon-1024.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("✅ Generated icon: 1024x1024 at \(outputPath)")
