//
//  UndoEraseView.swift
//  PictionAiR
//
//  Created by Sankaet Cheemalamarri on 11/11/23.
//

import SwiftUI
//import Popovers

struct DrawingToolsPanel: View {
    @EnvironmentObject var arPictionaryGame : ARPictionaryGame
    @Binding var penColor : Color
    @Binding var thickness : CGFloat
    @State var sliderValue : CGFloat = 0
    @State private var showAlert = false
    @State private var showPopover = false
    @State private var isColorPickerExpanded = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(alignment: .bottom, spacing: UIScreen.main.bounds.width > 500 ? (arPictionaryGame.gameMode == .freeDraw ? 20 : 30) : 10) {
                DrawingToolsPanelButton("arrow.uturn.backward", arPictionaryGame.gameMode == .freeDraw) {
                    arPictionaryGame.undo()
                }
                .disabled(isColorPickerExpanded)
                .opacity(isColorPickerExpanded ? 0.2 : 1)
                .padding( .leading, UIScreen.main.bounds.width > 500 ? 27.5 : 0)
                
                DrawingToolsPanelButton("arrow.uturn.forward", arPictionaryGame.gameMode == .freeDraw) {
                    arPictionaryGame.redo()
                }
                .disabled(isColorPickerExpanded)
                .opacity(isColorPickerExpanded ? 0.2 : 1)
                
                
                DrawingToolsPanelButton("eraser", arPictionaryGame.gameMode == .freeDraw, isSelected: !arPictionaryGame.isCurrentlyDrawing) {
                    arPictionaryGame.isCurrentlyDrawing.toggle()
                }
                .disabled(isColorPickerExpanded)
                .opacity(isColorPickerExpanded ? 0.2 : 1)
                
                DrawingToolsPanelButton("trash", arPictionaryGame.gameMode == .freeDraw) {
                    showAlert = true
                }
                .disabled(isColorPickerExpanded)
                .opacity(isColorPickerExpanded ? 0.2 : 1)
                
                
                DrawingToolsPanelButton("camera", arPictionaryGame.gameMode == .freeDraw) {
                    arPictionaryGame.snapShot()
                }
                .disabled(isColorPickerExpanded)
                .opacity(isColorPickerExpanded ? 0.2 : 1)
                
                if(UIScreen.main.bounds.width > 500) {
                    Spacer()
                }
                
                DrawingToolsPanelButton("lineweight", arPictionaryGame.gameMode == .freeDraw) {
                    showPopover.toggle()
                }
                .popover(isPresented: $showPopover, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                    SliderView(strokeSize: $thickness, pencolor: $penColor, sliderValue: $sliderValue)
                        .presentationBackground {
                            Rectangle()
                                //.fill(Color.secondary.opacity(0.15))
                                .fill(.ultraThinMaterial)
                        }
                        .presentationCompactAdaptation(.popover)
                }
                .disabled(isColorPickerExpanded)
                .opacity(isColorPickerExpanded ? 0.2 : 1)
                
                if arPictionaryGame.gameMode == .freeDraw {
                    DrawingToolsPanelButton("wand.and.stars", arPictionaryGame.gameMode == .freeDraw) {
                        arPictionaryGame.imageRecognition()
                    }
                    .disabled(!arPictionaryGame.canAnalyzeDrawing)
                    .opacity(!arPictionaryGame.canAnalyzeDrawing ? 0.4 : 1)
                    .disabled(isColorPickerExpanded)
                    .opacity(isColorPickerExpanded ? 0.2 : 1)
                }
                
                DrawingToolsPanelColorPicker(isExpanded: $isColorPickerExpanded, selectedPenColor: $penColor, wandButton: arPictionaryGame.gameMode == .freeDraw)
                    .padding( .trailing, UIScreen.main.bounds.width > 500 ? 27.5 : 0)
            }
            //.padding()
            .frame(alignment: UIScreen.main.bounds.width < 500 ? .bottom : .bottomLeading)
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Clear Drawing"),
                    message: Text("Are you sure you want to clear your drawing?"),
                    primaryButton: .destructive(
                        Text("Clear"),
                        action:arPictionaryGame.clearAllAnchors
                    ),
                    secondaryButton: .default(
                        Text("Cancel"),
                        action: {showAlert = false}
                    )
                )
            }
            
        }
        .animation(.spring(), value: isColorPickerExpanded)
    }
}

private struct LineWeightShape: Shape {
    func path(in rect : CGRect) -> Path {
        Path { path in
            path.addArc(center: CGPoint(x: rect.minX, y: rect.midY),
                        radius: rect.height / 8,
                        startAngle: Angle(degrees: 90),
                        endAngle: Angle(degrees: 270),
                        clockwise: false)
            path.addArc(center: CGPoint(x: rect.maxX, y: rect.midY),
                        radius: rect.height / 2,
                        startAngle: Angle(degrees: -90),
                        endAngle: Angle(degrees: 90),
                        clockwise: false)
        }
    }
}

private struct SliderView: View {
    let sliderWidth: CGFloat = 285
    let knobSize: CGFloat = 30

    @Binding var strokeSize : CGFloat
    @Binding var pencolor : Color
    @Binding var sliderValue: CGFloat

    var body: some View {
        VStack {
            ZStack {
                LineWeightShape()
                    .foregroundColor(pencolor)
                    .frame(width: 300, height: 35)
                    .offset(x: -30)
                    .padding(.leading, 45)
                    .onAppear{
                        print(UIScreen.main.bounds.width)
                    }
                Circle()
                    .coordinateSpace(name: "screen")
                    .frame(width: 40)
                    .offset(x: 0)
                    .offset(x: sliderValue)
                    .foregroundColor(.white)
                    .shadow(color: .gray, radius: 10, x: 5, y: 5)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let boundX = min(max(-142.5, value.location.x), 142.5)
                                sliderValue = boundX
                                strokeSize = (sliderValue + 142.5)/285 * 0.006 + 0.0020
                                print("Circle Location: \(value.location.x)")
                                print("Slider Value: \(sliderValue)")
                            }
                    )
            }
        }
    }
}

private func buttonSizePicker(wandButton: Bool) -> CGFloat {
    if wandButton {
        return (UIScreen.main.bounds.width / 10.5) < 50 ? UIScreen.main.bounds.width / 10.5 : 50
    } else {
        if (UIScreen.main.bounds.width > 500) {
            return (UIScreen.main.bounds.width / 9) < 50 ? UIScreen.main.bounds.width / 9 : 50
        } else {
            return (UIScreen.main.bounds.width / 9) < 45 ? UIScreen.main.bounds.width / 9 : 45
        }
    }
}


private struct DrawingToolsPanelButton: View {
    var systemImage: String
    var isSelected: Bool
    var wandButton: Bool
    var action: (() -> Void)
    var buttonSize: CGFloat {
        buttonSizePicker(wandButton: wandButton)
    }
    
    init(_ systemImage: String, _ wandButton: Bool, isSelected: Bool = false, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
        self.wandButton = wandButton
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundStyle(.ultraThickMaterial)
                    .shadow(radius: 10)
                    .overlay(
                        Circle()
                            .strokeBorder(!isSelected ? Color.primary.opacity(0.2) : Color.primary.opacity(1), lineWidth: 2)
                            .frame(width: buttonSize, height: buttonSize)
                            .foregroundStyle(!isSelected ? Color(UIColor.systemBackground) : Color.primary)
                            .opacity(0.8)
                    )

                Image(systemName: systemImage)
//                    .resizable()
//                    .frame(width: buttonSize * 0.50, height: buttonSize * 0.50)
                    .foregroundStyle(Color.primary)
                    .symbolVariant(isSelected ? .fill : .none)
            }
        }
    }

}

private struct DrawingToolsPanelColorPicker: View {
    @Namespace private var namespace
    @Binding var isExpanded: Bool
    @Binding var selectedPenColor: Color
    var wandButton: Bool
    var buttonSize: CGFloat {
        buttonSizePicker(wandButton: wandButton)
    }
    
    @State private var recentColors: [Color] = [.white, .black, .red, .green, .yellow, .orange, .blue]
    @State private var showingCustomColorPicker = false
    
    var body: some View {
        VStack {
            if isExpanded {
                Circle()
                    .fill(.conicGradient(colors: [.purple, .indigo, .blue, .green, .yellow, .orange, .red], center: .center))
                    .frame(width: buttonSize, height: buttonSize)
                    .frame(width: buttonSize, height: buttonSize)
                    .imageScale(.large)
                    .onTapGesture {
                        showingCustomColorPicker = true
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(.black.opacity(0.3), lineWidth: 2.5)
                    }
            }
            
            ForEach(isExpanded ? recentColors : [selectedPenColor], id: \.self) { color in
                let index = recentColors.endIndex - (recentColors.firstIndex(of: color) ?? 0)
                Circle()
                    .fill(color)
                    .shadow(radius: 10)
                    .onTapGesture {
                        if isExpanded {
                            didSelectColor(color)
                            isExpanded = false
                        } else {
                            isExpanded = true
                        }
                    }
                    .matchedGeometryEffect(id: UIColor(color).hexString(), in: namespace)
                    .transition(.asymmetric(
                        insertion:
                            .scale.animation(.spring().delay(Double(index) * 0.05)),
                        removal:
                            .scale.animation(
                                .spring()
                                .delay(Double(recentColors.endIndex - index) * 0.05))
                            )
                    )
                    .overlay {
                        if color == selectedPenColor {
                            Circle()
                                .strokeBorder(.conicGradient(colors: [.purple, .indigo, .blue, .green, .yellow, .orange, .red], center: .center), lineWidth: 4)
                        } else {
                            Circle()
                                .strokeBorder(.black.opacity(0.3), lineWidth: 2.5)
                        }
                    }
                    .frame(width: buttonSize, height: buttonSize)
            }
        }
        .fixedSize()
        .background {
            if isExpanded {
                GeometryReader { geo in
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .cornerRadius(16.0)
                        .frame(width: geo.size.width + 10, height: geo.size.height + 10)
                        .offset(x: -5, y: -5)
                }
            }
        }
        .colorPickerSheet(isPresented: $showingCustomColorPicker, selection: $selectedPenColor, supportsAlpha: false, title: nil) {
            didSelectColor(selectedPenColor)
            isExpanded = false
            showingCustomColorPicker = false
        }
    }
    
    private func didSelectColor(_ color: Color) {
        if let indexOfColor = recentColors.firstIndex(where: { UIColor($0).hexString() == UIColor(color).hexString() }) {
            recentColors.remove(at: indexOfColor)
        } else if recentColors.count > 8 {
            recentColors.removeFirst()
        }
        recentColors.append(color)
        selectedPenColor = color
    }
}

#Preview {
    DrawingToolsPanel(penColor: .constant(Color.blue), thickness: .constant(0.005))
        .environmentObject(ARPictionaryGame())
}
