import AppKit
import AVFoundation
import CoreText
import CoreVideo
import Foundation
import ImageIO

struct VideoFormat {
    let name: String
    let width: Int
    let height: Int
    let vertical: Bool
}

let formats = [
    VideoFormat(name: "kuber-10s-vertical-1080x1920.mp4", width: 1080, height: 1920, vertical: true),
    VideoFormat(name: "kuber-10s-landscape-1920x1080.mp4", width: 1920, height: 1080, vertical: false)
]

let frameRate: Int32 = 24
let duration = 10.0
let outputDirectory = URL(fileURLWithPath: "google-ads/videos", isDirectory: true)
let logoURL = URL(fileURLWithPath: "google-ads/yantra-emblem.svg")

guard let sourceImage = NSImage(contentsOf: logoURL) else {
    fatalError("Could not load \(logoURL.path)")
}
var logoRect = CGRect(origin: .zero, size: sourceImage.size)
guard let logo = sourceImage.cgImage(forProposedRect: &logoRect, context: nil, hints: nil) else {
    fatalError("Could not rasterize \(logoURL.path)")
}

func addPolygon(_ points: [(CGFloat, CGFloat)], to context: CGContext) {
    guard let first = points.first else { return }
    context.beginPath()
    context.move(to: CGPoint(x: first.0, y: first.1))
    for point in points.dropFirst() {
        context.addLine(to: CGPoint(x: point.0, y: point.1))
    }
    context.closePath()
}

func drawTurtle(_ context: CGContext, centerX: CGFloat, centerY: CGFloat, side: CGFloat, time: Double) {
    let gold = color(0.851, 0.682, 0.361)
    let shellFill = color(0.063, 0.075, 0.094)
    let walkPhase = time * 2 * .pi
    let bob = CGFloat(sin(walkPhase * 2) * 1.4)
    let scale = side / 64

    context.saveGState()
    context.translateBy(x: centerX - side / 2, y: centerY + side / 2)
    context.scaleBy(x: scale, y: -scale)
    context.translateBy(x: 0, y: bob)

    let legs: [(CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
        (17, 22, 6.5, 4.2, 0),
        (47, 22, 6.5, 4.2, .pi),
        (17.5, 45, 6, 4, .pi),
        (46.5, 45, 6, 4, 0)
    ]
    context.setFillColor(gold)
    for (index, leg) in legs.enumerated() {
        let swing = CGFloat(sin(walkPhase + Double(index % 2) * .pi) * 0.95)
        context.saveGState()
        context.translateBy(x: leg.0, y: leg.1)
        context.rotate(by: leg.4 + swing)
        context.fillEllipse(in: CGRect(x: -leg.2, y: -leg.3, width: leg.2 * 2, height: leg.3 * 2))
        context.restoreGState()
    }

    context.beginPath()
    context.move(to: CGPoint(x: 29, y: 48))
    context.addLine(to: CGPoint(x: 32, y: 56))
    context.addLine(to: CGPoint(x: 35, y: 48))
    context.closePath()
    context.fillPath()

    let shell = CGRect(x: 17.5, y: 16.5, width: 29, height: 33)
    context.setFillColor(shellFill)
    context.setStrokeColor(gold)
    context.setLineWidth(2.5)
    context.fillEllipse(in: shell)
    context.strokeEllipse(in: shell)

    context.setLineWidth(1.6)
    context.setLineJoin(.round)
    context.setLineCap(.round)
    context.strokeEllipse(in: CGRect(x: 20, y: 19, width: 24, height: 28))
    addPolygon([(32, 25.5), (38.5, 29.25), (38.5, 36.75), (32, 40.5), (25.5, 36.75), (25.5, 29.25)], to: context)
    context.strokePath()
    context.beginPath()
    context.move(to: CGPoint(x: 32, y: 25.5))
    context.addLine(to: CGPoint(x: 32, y: 19))
    context.move(to: CGPoint(x: 38.5, y: 29.25))
    context.addLine(to: CGPoint(x: 42.4, y: 26))
    context.move(to: CGPoint(x: 38.5, y: 36.75))
    context.addLine(to: CGPoint(x: 42.4, y: 40))
    context.move(to: CGPoint(x: 32, y: 40.5))
    context.addLine(to: CGPoint(x: 32, y: 47))
    context.move(to: CGPoint(x: 25.5, y: 36.75))
    context.addLine(to: CGPoint(x: 21.6, y: 38))
    context.move(to: CGPoint(x: 25.5, y: 29.25))
    context.addLine(to: CGPoint(x: 21.6, y: 24))
    context.strokePath()

    let headBob = CGFloat(sin(walkPhase * 2) * 0.35)
    context.setFillColor(gold)
    context.fillEllipse(in: CGRect(x: 27, y: 5.5 + headBob, width: 10, height: 12))
    context.restoreGState()
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red, green: green, blue: blue, alpha: alpha)
}

func drawText(
    _ text: String,
    in context: CGContext,
    centerX: CGFloat,
    baseline: CGFloat,
    fontSize: CGFloat,
    weight: CTFontSymbolicTraits = [],
    fill: CGColor,
    tracking: CGFloat = 0
) {
    let fontName = weight.contains(.traitBold) ? "AvenirNext-DemiBold" : "AvenirNext-Medium"
    let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): fill,
        NSAttributedString.Key(kCTKernAttributeName as String): tracking
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    context.saveGState()
    context.textPosition = CGPoint(x: centerX - width / 2, y: baseline)
    CTLineDraw(line, context)
    context.restoreGState()
}

func drawRoundedRect(_ context: CGContext, rect: CGRect, radius: CGFloat, fill: CGColor) {
    context.setFillColor(fill)
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.fillPath()
}

func fade(_ time: Double, from start: Double, over span: Double = 0.7) -> CGFloat {
    CGFloat(min(max((time - start) / span, 0), 1))
}

func drawFrame(_ context: CGContext, format: VideoFormat, time: Double, turtle: Bool) {
    let width = CGFloat(format.width)
    let height = CGFloat(format.height)
    let centerX = width / 2
    let centerY = height * 0.5
    let gold = color(0.83, 0.68, 0.25)
    let goldLight = color(0.98, 0.86, 0.55)
    let ink = color(0.035, 0.035, 0.033)
    let chip = color(0.075, 0.078, 0.079, 0.96)

    context.saveGState()
    context.setFillColor(turtle ? color(0.063, 0.075, 0.094) : ink)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    let gradientColors = [color(0.83, 0.68, 0.25, 0.16), color(0.83, 0.68, 0.25, 0)] as CFArray
    if let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: gradientColors,
        locations: [0, 1]
    ) {
        context.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: centerX, y: centerY),
            startRadius: 10,
            endCenter: CGPoint(x: centerX, y: centerY),
            endRadius: min(width, height) * 0.56,
            options: [.drawsAfterEndLocation]
        )
    }

    let gridSpacing = format.vertical ? CGFloat(90) : CGFloat(105)
    context.setStrokeColor(color(0.83, 0.68, 0.25, 0.045))
    context.setLineWidth(1)
    var gridX: CGFloat = 0
    while gridX <= width {
        context.move(to: CGPoint(x: gridX, y: 0))
        context.addLine(to: CGPoint(x: gridX, y: height))
        gridX += gridSpacing
    }
    var gridY: CGFloat = 0
    while gridY <= height {
        context.move(to: CGPoint(x: 0, y: gridY))
        context.addLine(to: CGPoint(x: width, y: gridY))
        gridY += gridSpacing
    }
    context.strokePath()

    let logoSide = turtle
        ? (format.vertical ? width * 0.42 : height * 0.30)
        : (format.vertical ? width * 0.49 : height * 0.34)
    let ringWidth = format.vertical ? width * 0.82 : height * 0.82
    let ringHeight = format.vertical ? height * 0.46 : height * 0.82
    let ringRect = CGRect(x: centerX - ringWidth / 2, y: centerY - ringHeight / 2, width: ringWidth, height: ringHeight)
    context.setStrokeColor(color(0.83, 0.68, 0.25, 0.12))
    context.setLineWidth(1)
    context.strokeEllipse(in: ringRect.insetBy(dx: 20, dy: 20))
    context.setStrokeColor(color(0.83, 0.68, 0.25, 0.32))
    context.setLineWidth(1)
    context.setLineDash(phase: 0, lengths: [4, 9])
    context.strokeEllipse(in: ringRect)
    context.setLineDash(phase: 0, lengths: [])

    let logoAlpha = fade(time, from: 0.15, over: 1.0)
    context.setAlpha(logoAlpha)
    if turtle {
        drawTurtle(context, centerX: centerX, centerY: centerY, side: logoSide, time: time)
    } else {
        context.interpolationQuality = .high
        context.draw(
            logo,
            in: CGRect(x: centerX - logoSide / 2, y: centerY - logoSide / 2, width: logoSide, height: logoSide)
        )
    }
    context.setAlpha(1)

    let labels = ["MOAT", "MANAGEMENT", "MARGIN", "MOMENTUM"]
    let orbitalRadius = min(width, height) * (format.vertical ? 0.39 : 0.38)
    let labelScale = format.vertical ? width * 0.031 : height * 0.035
    let labelBaselineOffset = labelScale * 0.34
    let startingAngles: [Double] = [.pi * 0.75, .pi * 0.25, .pi * 1.25, .pi * 1.75]
    let orbitAngle = time * 2 * .pi / (duration * 1.2)

    for (index, label) in labels.enumerated() {
        let labelWidth = label == "MANAGEMENT" ? labelScale * 10.1 : labelScale * 6.3
        let labelHeight = labelScale * 2.15
        let angle = startingAngles[index] + orbitAngle
        let positionX = centerX + orbitalRadius * CGFloat(cos(angle))
        let positionY = centerY + orbitalRadius * CGFloat(sin(angle))
        let rect = CGRect(
            x: positionX - labelWidth / 2,
            y: positionY - labelHeight / 2,
            width: labelWidth,
            height: labelHeight
        )
        let reveal = fade(time, from: 0.75 + Double(index) * 0.46, over: 0.65)
        let alpha = reveal
        let float = sin(time * 2 * .pi + Double(index) * .pi / 2) * Double(labelScale * 0.035)
        context.setAlpha(alpha)
        drawRoundedRect(context, rect: rect.offsetBy(dx: 0, dy: CGFloat(float)), radius: labelHeight / 2, fill: chip)
        context.setStrokeColor(color(0.83, 0.68, 0.25, 0.52))
        context.setLineWidth(1.2)
        context.addPath(CGPath(roundedRect: rect.offsetBy(dx: 0, dy: CGFloat(float)), cornerWidth: labelHeight / 2, cornerHeight: labelHeight / 2, transform: nil))
        context.strokePath()
        context.setFillColor(gold)
        context.fillEllipse(in: CGRect(
            x: rect.minX + labelScale * 0.75,
            y: rect.midY - labelScale * 0.105 + CGFloat(float),
            width: labelScale * 0.21,
            height: labelScale * 0.21
        ))
        drawText(
            label,
            in: context,
            centerX: rect.midX + labelScale * 0.11,
            baseline: rect.midY - labelBaselineOffset + CGFloat(float),
            fontSize: labelScale * 0.72,
            weight: [.traitBold],
            fill: goldLight,
            tracking: labelScale * 0.10
        )
    }

    let wordmarkSize = format.vertical ? width * 0.052 : height * 0.050
    context.setAlpha(fade(time, from: 0.1, over: 0.7))
    drawText(
        "Kuber",
        in: context,
        centerX: centerX,
        baseline: height * 0.955,
        fontSize: wordmarkSize,
        weight: [.traitBold],
        fill: goldLight,
        tracking: wordmarkSize * 0.015
    )
    drawText(
        "Compounding through first principles.",
        in: context,
        centerX: centerX,
        baseline: height * 0.905,
        fontSize: format.vertical ? width * 0.034 : height * 0.027,
        fill: color(0.86, 0.84, 0.77),
        tracking: format.vertical ? 0.3 : 0.8
    )

    let buttonWidth = format.vertical ? width * 0.56 : width * 0.27
    let buttonHeight = format.vertical ? height * 0.046 : height * 0.055
    let buttonY = height * (format.vertical ? 0.068 : 0.02)
    let buttonRect = CGRect(
        x: centerX - buttonWidth / 2,
        y: buttonY,
        width: buttonWidth,
        height: buttonHeight
    )
    let buttonAlpha = fade(time, from: 5.0, over: 0.85)
    context.setAlpha(buttonAlpha)
    drawRoundedRect(context, rect: buttonRect, radius: buttonHeight / 2, fill: gold)
    drawText(
        "EXPLORE KUBERS.AI",
        in: context,
        centerX: centerX,
        baseline: buttonY + buttonHeight * 0.33,
        fontSize: format.vertical ? width * 0.027 : height * 0.024,
        weight: [.traitBold],
        fill: ink,
        tracking: format.vertical ? 1.1 : 1.4
    )

    context.setAlpha(1)
    context.restoreGState()
}

func render(_ format: VideoFormat, turtle: Bool) throws {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    let outputName = turtle
        ? format.name.replacingOccurrences(of: "kuber-10s-", with: "kuber-turtle-10s-")
        : format.name
    let outputURL = outputDirectory.appendingPathComponent(outputName)
    try? FileManager.default.removeItem(at: outputURL)

    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    let settings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: format.width,
        AVVideoHeightKey: format.height,
        AVVideoCompressionPropertiesKey: [
            AVVideoAverageBitRateKey: format.vertical ? 5_000_000 : 6_000_000,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            AVVideoExpectedSourceFrameRateKey: frameRate,
            AVVideoMaxKeyFrameIntervalKey: frameRate * 2
        ]
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
        assetWriterInput: input,
        sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: format.width,
            kCVPixelBufferHeightKey as String: format.height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
    )
    guard writer.canAdd(input) else {
        throw NSError(domain: "KuberVideo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not add video input."])
    }
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let frameCount = Int(duration * Double(frameRate))
    for frame in 0..<frameCount {
        while !input.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.01)
            if writer.status == .failed {
                throw writer.error ?? NSError(domain: "KuberVideo", code: 2)
            }
        }
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, adaptor.pixelBufferPool!, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw NSError(domain: "KuberVideo", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Could not allocate a video frame."])
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        if let baseAddress = CVPixelBufferGetBaseAddress(buffer),
           let context = CGContext(
            data: baseAddress,
            width: format.width,
            height: format.height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
           ) {
            drawFrame(context, format: format, time: Double(frame) / Double(frameRate), turtle: turtle)
        } else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            throw NSError(domain: "KuberVideo", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not create a frame drawing context."])
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        let presentationTime = CMTime(value: Int64(frame), timescale: frameRate)
        guard adaptor.append(buffer, withPresentationTime: presentationTime) else {
            throw writer.error ?? NSError(domain: "KuberVideo", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not append video frame."])
        }
    }

    input.markAsFinished()
    let completed = DispatchSemaphore(value: 0)
    writer.finishWriting {
        completed.signal()
    }
    completed.wait()
    guard writer.status == .completed else {
        throw writer.error ?? NSError(domain: "KuberVideo", code: 5, userInfo: [NSLocalizedDescriptionKey: "Video export did not complete."])
    }
    print("Created \(outputURL.path)")
}

for format in formats {
    try render(format, turtle: false)
    try render(format, turtle: true)
}
