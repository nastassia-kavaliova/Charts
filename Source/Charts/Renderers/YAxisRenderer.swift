//
//  YAxisRenderer.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

@objc(ChartYAxisRenderer)
open class YAxisRenderer: AxisRendererBase
{
    /// to prevent wrong "HIGH" value drawing for charts with one y value like [0.0, 0.0, 0.0 ...]
    var axisMaximumValue: Double?
    
    public init(viewPortHandler: ViewPortHandler?, yAxis: YAxis?, transformer: Transformer?)
    {
        super.init(viewPortHandler: viewPortHandler, transformer: transformer, axis: yAxis)
    }
    
    /// draws the y-axis labels to the screen
    open override func renderAxisLabels(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler
            else { return }
        
        if !yAxis.isEnabled || !yAxis.isDrawLabelsEnabled
        {
            return
        }
        
        let xoffset = yAxis.xOffset
        let yoffset = yAxis.labelFont.lineHeight / 2.5 + yAxis.yOffset
        
        let dependency = yAxis.axisDependency
        let labelPosition = yAxis.labelPosition
        
        var xPos = CGFloat(0.0)
        
        var textAlign: NSTextAlignment
        
        if dependency == .left
        {
            if labelPosition == .outsideChart
            {
                textAlign = .right
                xPos = viewPortHandler.offsetLeft - xoffset
            }
            else
            {
                textAlign = .left
                xPos = viewPortHandler.offsetLeft + xoffset
            }
            
        }
        else
        {
            if labelPosition == .outsideChart
            {
                textAlign = .left
                xPos = viewPortHandler.contentRight + xoffset
            }
            else
            {
                textAlign = .right
                xPos = viewPortHandler.contentRight - xoffset
            }
        }
        
        drawYLabels(
            context: context,
            fixedPosition: xPos,
            positions: transformedPositions(),
            offset: yoffset - yAxis.labelFont.lineHeight,
            textAlign: textAlign)
    }
    
    open override func renderAxisLine(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler
            else { return }
        
        if !yAxis.isEnabled || !yAxis.drawAxisLineEnabled
        {
            return
        }
        
        context.saveGState()
        
        context.setStrokeColor(yAxis.axisLineColor.cgColor)
        context.setLineWidth(yAxis.axisLineWidth)
        if yAxis.axisLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.axisLineDashPhase, lengths: yAxis.axisLineDashLengths)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        if yAxis.axisDependency == .left
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: viewPortHandler.contentLeft, y: viewPortHandler.contentBottom))
            context.strokePath()
        }
        else
        {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentTop - yAxis.extraTopOffset))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: viewPortHandler.contentBottom + yAxis.extraBottomOffset))
            context.strokePath()
        }
        
        context.restoreGState()
    }
    
    /// draws the y-labels on the specified x-position
    internal func drawYLabels(
        context: CGContext,
        fixedPosition: CGFloat,
        positions: [CGPoint],
        offset: CGFloat,
        textAlign: NSTextAlignment)
    {
        guard
            let yAxis = self.axis as? YAxis
            else { return }
        
        let labelFont = yAxis.labelFont
        let labelTextColor = yAxis.labelTextColor
        let legendType = yAxis.legendType
        
        switch legendType {
        case .all:
            for i in 0 ..< yAxis.entryCount
            {
                let text = yAxis.getFormattedLabel(i)
                
                if !yAxis.isDrawTopYLabelEntryEnabled && i >= yAxis.entryCount - 1
                {
                    break
                }
                let textXPosition = calculateXPosition(forText: text,
                                                       fixedPosition: fixedPosition)
                
                ChartUtils.drawText(
                    context: context,
                    text: text,
                    point: CGPoint(x: textXPosition, y: positions[i].y + offset),
                    align: textAlign,
                    attributes: [NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelTextColor])
            }
        case .lowHigh:
            if yAxis.entryCount > 0, let firstAuxiliaryTitle = yAxis.legendAuxiliaryTitles.first {
                let firstEntryIndex = 0
                let axisMinValueString = yAxis.valueFormatter?.stringForValue(yAxis.axisMinimum, axis: yAxis) ?? ""
                let lowValueText = axisMinValueString
                
                let textXPosition = calculateXPosition(forText: lowValueText,
                                                       fixedPosition: fixedPosition)
                let yPosition = (viewPortHandler?.contentRect.maxY ?? positions[firstEntryIndex].y) + offset
                
                ChartUtils.drawText(
                    context: context,
                    text: lowValueText,
                    point: CGPoint(x: textXPosition, y: yPosition),
                    align: textAlign,
                    attributes: [NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelTextColor])
                
                drawAuxiliaryYLabel(context: context,
                                    title: firstAuxiliaryTitle,
                                    fixedPosition: fixedPosition,
                                    yPosition: yPosition + 8,
                                    offset: offset,
                                    textAlign: textAlign)
                
            }
            if yAxis.entryCount > 1, let lastAuxiliaryTitle = yAxis.legendAuxiliaryTitles.last, let maxValue = axisMaximumValue, maxValue != yAxis.axisMinimum {
                let lastEntryIndex = yAxis.entryCount - 1
                let axisMax = yAxis.axisMaximum
                let originMax = Double((CGFloat(axisMax) + yAxis.spaceTop*CGFloat(yAxis.axisMinimum))/(1.0 + yAxis.spaceTop))
                let valueText = yAxis.valueFormatter?.stringForValue(originMax, axis: yAxis) ?? ""
                let lowValueText = valueText
                let textXPosition = calculateXPosition(forText: lowValueText,
                                                       fixedPosition: fixedPosition)
                ChartUtils.drawText(
                    context: context,
                    text: lowValueText,
                    point: CGPoint(x: textXPosition, y: positions[lastEntryIndex].y + offset),
                    align: textAlign,
                    attributes: [NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelTextColor])
                
                drawAuxiliaryYLabel(context: context,
                                    title: lastAuxiliaryTitle,
                                    fixedPosition: fixedPosition,
                                    yPosition: positions[lastEntryIndex].y,
                                    offset: offset,
                                    textAlign: textAlign)
                
            }
        }
        
    }
    
    private func calculateXPosition(forText text: String, fixedPosition: CGFloat) -> CGFloat {
        guard let yAxis = self.axis as? YAxis
            else { return fixedPosition }
        let labelFont = yAxis.labelFont
        let textWidth = text.size(attributes: [NSFontAttributeName: labelFont]).width
        var textXPosition: CGFloat
        if textWidth > yAxis.axisLineWidth {
            textXPosition = 0
        }
        else {
            textXPosition = UIScreen.main.bounds.width - yAxis.axisLineWidth + (yAxis.axisLineWidth - textWidth)/2
        }
        return textXPosition
    }
    
    
    private func drawAuxiliaryYLabel(context: CGContext, title: String, fixedPosition: CGFloat, yPosition: CGFloat, offset: CGFloat, textAlign: NSTextAlignment) {
        guard
            let yAxis = self.axis as? YAxis
            else { return }
        let labelTextColor = yAxis.labelTextColor
        let legendAuxiliaryTitlesFont = yAxis.legendAuxiliaryTitlesFont
        let firstEntryTitleSize = title.size(attributes: [NSFontAttributeName: legendAuxiliaryTitlesFont])
        let legendAuxiliaryTitlesOffset = firstEntryTitleSize.width/2 + 5
        let firstEntryTitleYPosition = yPosition + offset - firstEntryTitleSize.height
        
        ChartUtils.drawText(
            context: context,
            text: title,
            point: CGPoint(x: fixedPosition - legendAuxiliaryTitlesOffset, y: firstEntryTitleYPosition),
            align: textAlign,
            attributes: [NSFontAttributeName: legendAuxiliaryTitlesFont, NSForegroundColorAttributeName: labelTextColor])
    }
    
    open override func renderGridLines(context: CGContext)
    {
        guard let
            yAxis = self.axis as? YAxis
            else { return }
        
        if !yAxis.isEnabled
        {
            return
        }
        
        if yAxis.drawGridLinesEnabled
        {
            let positions = transformedPositions()
            
            context.saveGState()
            defer { context.restoreGState() }
            context.clip(to: self.gridClippingRect)
            
            context.setShouldAntialias(yAxis.gridAntialiasEnabled)
            context.setStrokeColor(yAxis.gridColor.cgColor)
            context.setLineWidth(yAxis.gridLineWidth)
            context.setLineCap(yAxis.gridLineCap)
            
            if yAxis.gridLineDashLengths != nil
            {
                context.setLineDash(phase: yAxis.gridLineDashPhase, lengths: yAxis.gridLineDashLengths)
                
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            // draw the grid
            for i in 0 ..< positions.count
            {
                drawGridLine(context: context, position: positions[i])
            }
        }

        if yAxis.drawZeroLineEnabled
        {
            // draw zero line
            drawZeroLine(context: context)
        }
    }
    
    open var gridClippingRect: CGRect
    {
        var contentRect = viewPortHandler?.contentRect ?? CGRect.zero
        let dy = self.axis?.gridLineWidth ?? 0.0
        contentRect.origin.y -= dy / 2.0
        contentRect.size.height += dy
        return contentRect
    }
    
    open func drawGridLine(
        context: CGContext,
        position: CGPoint)
    {
        guard
            let viewPortHandler = self.viewPortHandler
            else { return }
        
        context.beginPath()
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
        context.strokePath()
    }
    
    open func transformedPositions() -> [CGPoint]
    {
        guard
            let yAxis = self.axis as? YAxis,
            let transformer = self.transformer
            else { return [CGPoint]() }
        
        var positions = [CGPoint]()
        positions.reserveCapacity(yAxis.entryCount)
        
        let entries = yAxis.entries
        
        for i in stride(from: 0, to: yAxis.entryCount, by: 1)
        {
            positions.append(CGPoint(x: 0.0, y: entries[i]))
        }

        transformer.pointValuesToPixel(&positions)
        
        return positions
    }

    /// Draws the zero line at the specified position.
    open func drawZeroLine(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler,
            let transformer = self.transformer,
            let zeroLineColor = yAxis.zeroLineColor
            else { return }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        var clippingRect = viewPortHandler.contentRect
        clippingRect.origin.y -= yAxis.zeroLineWidth / 2.0
        clippingRect.size.height += yAxis.zeroLineWidth
        context.clip(to: clippingRect)

        context.setStrokeColor(zeroLineColor.cgColor)
        context.setLineWidth(yAxis.zeroLineWidth)
        
        let pos = transformer.pixelForValues(x: 0.0, y: 0.0)
    
        if yAxis.zeroLineDashLengths != nil
        {
            context.setLineDash(phase: yAxis.zeroLineDashPhase, lengths: yAxis.zeroLineDashLengths!)
        }
        else
        {
            context.setLineDash(phase: 0.0, lengths: [])
        }
        
        context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: pos.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: pos.y))
        context.drawPath(using: CGPathDrawingMode.stroke)
    }
    
    open override func renderLimitLines(context: CGContext)
    {
        guard
            let yAxis = self.axis as? YAxis,
            let viewPortHandler = self.viewPortHandler,
            let transformer = self.transformer
            else { return }
        
        var limitLines = yAxis.limitLines
        
        if limitLines.count == 0
        {
            return
        }
        
        context.saveGState()
        
        let trans = transformer.valueToPixelMatrix
        
        var position = CGPoint(x: 0.0, y: 0.0)
        
        for i in 0 ..< limitLines.count
        {
            let l = limitLines[i]
            
            if !l.isEnabled
            {
                continue
            }
            
            context.saveGState()
            defer { context.restoreGState() }
            
            var clippingRect = viewPortHandler.contentRect
            clippingRect.origin.y -= l.lineWidth / 2.0
            clippingRect.size.height += l.lineWidth
            context.clip(to: clippingRect)
            
            position.x = 0.0
            position.y = CGFloat(l.limit)
            position = position.applying(trans)
            
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
            
            context.setStrokeColor(l.lineColor.cgColor)
            context.setLineWidth(l.lineWidth)
            if l.lineDashLengths != nil
            {
                context.setLineDash(phase: l.lineDashPhase, lengths: l.lineDashLengths!)
            }
            else
            {
                context.setLineDash(phase: 0.0, lengths: [])
            }
            
            context.strokePath()
            
            let label = l.label
            
            // if drawing the limit-value label is enabled
            if l.drawLabelEnabled && label.characters.count > 0
            {
                let labelLineHeight = l.valueFont.lineHeight
                
                let xOffset: CGFloat = 4.0 + l.xOffset
                let yOffset: CGFloat = l.lineWidth + labelLineHeight + l.yOffset
                
                if l.labelPosition == .rightTop
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentRight - xOffset,
                            y: position.y - yOffset),
                        align: .right,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else if l.labelPosition == .rightBottom
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentRight - xOffset,
                            y: position.y + yOffset - labelLineHeight),
                        align: .right,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else if l.labelPosition == .leftTop
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentLeft + xOffset,
                            y: position.y - yOffset),
                        align: .left,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
                else
                {
                    ChartUtils.drawText(context: context,
                        text: label,
                        point: CGPoint(
                            x: viewPortHandler.contentLeft + xOffset,
                            y: position.y + yOffset - labelLineHeight),
                        align: .left,
                        attributes: [NSFontAttributeName: l.valueFont, NSForegroundColorAttributeName: l.valueTextColor])
                }
            }
        }
        
        context.restoreGState()
    }
}
