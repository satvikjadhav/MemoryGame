//
//  ContentView.swift
//  MemoryGame
//
//  Created by Satvik  Jadhav on 3/1/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}


// Card Data Model
struct Card: Identifiable, Equatable {
    var id = UUID()
    var isFaceUp = false
    var isMatched = false
    var content: String
    var position: CGFloat = 0
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
}

// Card GameView Model
class CardGameViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var score: Int = 0
    @Published var moves: Int = 0
    @Published var gameOver: Bool = false
    
    private var firstSelectedCard: Card?
    
    private let emojis = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐻‍❄️", "🐨", "🐯", "🦁"]
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        // Select a random number of emoji pairs between 6 and 12
        let pairCount = Int.random(in: 6...min(12, emojis.count))
        let emojiPairs = emojis.prefix(pairCount)
        let shuffledPairs = (emojiPairs + emojiPairs).shuffled()
        
        cards = shuffledPairs.enumerated().map { (index, emoji) in
            Card(content: emoji, position: CGFloat(index) * 10)
        }
        
        score = 0
        moves = 0
        gameOver = false
        firstSelectedCard = nil
    }
    
    func shuffleCards() {
        cards.shuffle()
    }
    
    func selectCard(_ selectedCard: Card) {
        // Find the index of the selected card
        guard let index = cards.firstIndex(where: { $0.id == selectedCard.id }),
              !cards[index].isMatched,
              !cards[index].isFaceUp else {
            return
        }
        
        // Set the card to face up
        cards[index].isFaceUp = true
        
        // If we already have a first selected card
        if let firstIndex = cards.firstIndex(where: { $0.id == firstSelectedCard?.id }) {
            // Increment the moves counter
            moves += 1
            
            // Check if the cards match
            if cards[firstIndex].content == cards[index].content {
                // Mark both cards as matched
                cards[firstIndex].isMatched = true
                cards[index].isMatched = true
                
                // Increment score for a match
                score += 2
                
                // Check if the game is over
                if cards.allSatisfy({ $0.isMatched }) {
                    gameOver = true
                }
            } else {
                // Decrement score for a mismatch
                if score > 0 {
                    score -= 1
                }
                
                // Flip the cards back after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.cards[firstIndex].isFaceUp = false
                    self.cards[index].isFaceUp = false
                }
            }
            
            // Reset the first selected card
            firstSelectedCard = nil
        } else {
            // Turn all unmatched cards face down first
            for i in cards.indices {
                if !cards[i].isMatched && cards[i].isFaceUp && cards[i].id != selectedCard.id {
                    cards[i].isFaceUp = false
                }
            }
            
            // Set the first selected card
            firstSelectedCard = selectedCard
        }
    }
}

// Card View
struct CardView: View {
    @ObservedObject var viewModel: CardGameViewModel
    let card: Card
    @State private var dragAmount = CGSize.zero
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            CardBack
                .opacity(card.isFaceUp ? 0 : 1)
                .rotation3DEffect(
                    .degrees(card.isFaceUp ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            CardFront
                .opacity(card.isFaceUp ? 1 : 0)
                .rotation3DEffect(
                    .degrees(card.isFaceUp ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: 80, height: 120)
        .rotationEffect(.degrees(rotation))
        .offset(dragAmount)
        .animation(.spring(), value: dragAmount)
        .animation(.spring(), value: card.isFaceUp)
        .animation(.spring(), value: card.isMatched)
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.dragAmount = value.translation
                }
                .onEnded { _ in
                    self.dragAmount = .zero
                }
        )
        .gesture(
            RotationGesture()
                .onChanged { angle in
                    self.rotation = angle.degrees
                }
        )
        .onTapGesture(count: 2) {
            viewModel.selectCard(card)
        }
    }

    // Front of the card
    private var CardFront: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .overlay(
                Text(card.content)
                    .font(.largeTitle)
            )
            .opacity(card.isMatched ? 0.5 : 1)
            .shadow(radius: 3)
    }
    
    // Back of the card
    private var CardBack: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue)
            .overlay(
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let spacing: CGFloat = 10
                        
                        for i in stride(from: 0, through: width, by: spacing) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i, y: height))
                        }
                        
                        for i in stride(from: 0, through: height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: i))
                            path.addLine(to: CGPoint(x: width, y: i))
                        }
                    }
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .shadow(radius: 3)
    }
}

// Control Panel View
struct ControlPanel: View {
    @ObservedObject var gameViewModel: CardGameViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // Score and Moves Display
            HStack {
                Text("Score: \(gameViewModel.score)")
                    .font(.headline)
                    .padding()
                Spacer()
                Text("Moves: \(gameViewModel.moves)")
                    .font(.headline)
                    .padding()
            }
            
            // Game Control Buttons
            HStack {
                Button("New Game") {
                    withAnimation(.spring()) {
                        gameViewModel.startNewGame()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Shuffle") {
                    withAnimation(.spring()) {
                        gameViewModel.shuffleCards()
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}