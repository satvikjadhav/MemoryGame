//
//  ContentView.swift
//  MemoryGame
//
//  Created by Satvik  Jadhav on 3/1/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = CardGameViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            // Use a custom light blue in light mode, but use system background in dark mode.
            let backgroundColor: Color = (colorScheme == .dark ? Color(.systemBackground) : Color(red: 0.8, green: 0.9, blue: 1.0))
            
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                if isLandscape {
                    HStack(spacing: 0) {
                        cardGrid(isLandscape: true)
                            .frame(width: geometry.size.width * 0.7)
                        ControlPanel(viewModel: viewModel)
                            .frame(width: geometry.size.width * 0.3)
                    }
                } else {
                    VStack {
                        cardGrid(isLandscape: false)
                        ControlPanel(viewModel: viewModel)
                    }
                }
            }
        }
    }
    
    //Card Grid Layout Function
    @ViewBuilder
    private func cardGrid(isLandscape: Bool) -> some View {
        let minWidth: CGFloat = isLandscape ? 100 : 80
        let columns = [GridItem(.adaptive(minimum: minWidth))]
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.cards) { card in
                    CardView(viewModel: viewModel, card: card)
                        .aspectRatio(2/3, contentMode: .fit)
                        .padding(4)
                }
            }
            .padding()
        }
    }
}

//Card Model Definition
struct Card: Identifiable {
    let id = UUID()
    let content: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
    var position: CGFloat = 0.0 // Initial position set to zero
}

// Card Game View Model
class CardGameViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var score: Int = 0
    @Published var moves: Int = 0
    @Published var gameOver: Bool = false
    
    private var firstSelectedCardIndex: Int? = nil
    
    // Constant set of emojis used for the game
    private let emojis = ["😀", "😎", "🥳", "🤖", "👻", "🐶", "🐱", "🦊"]
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        score = 0
        moves = 0
        gameOver = false
        firstSelectedCardIndex = nil
        
        // Create pairs of cards (two for each emoji)
        var newCards: [Card] = []
        for emoji in emojis {
            newCards.append(Card(content: emoji))
            newCards.append(Card(content: emoji))
        }
        // Randomize card positions
        cards = newCards.shuffled()
    }
    
    func shuffleCards() {
        withAnimation {
            cards.shuffle()
        }
    }
    
    func selectCard(card: Card) {
        // Find the index of the selected card in the deck
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        // Ignore if the card is already matched or face up
        if cards[index].isMatched || cards[index].isFaceUp { return }
        
        // If no first card is selected, flip all unmatched cards face down and mark this card as the first selection.
        if firstSelectedCardIndex == nil {
            for i in cards.indices {
                if !cards[i].isMatched {
                    cards[i].isFaceUp = false
                }
            }
            firstSelectedCardIndex = index
        } else {
            // Second card selection: increment moves and check for a match.
            moves += 1
            if cards[firstSelectedCardIndex!].content == cards[index].content {
                cards[firstSelectedCardIndex!].isMatched = true
                cards[index].isMatched = true
                score += 2
                // Check if all cards have been matched → game over.
                if cards.allSatisfy({ $0.isMatched }) {
                    gameOver = true
                }
            } else {
                // Penalize incorrect match if score is above zero.
                if score > 0 {
                    score -= 1
                }
            }
            firstSelectedCardIndex = nil
        }
        
        // Flip the selected card face up.
        cards[index].isFaceUp = true
    }
}

//Card View
struct CardView: View {
    @ObservedObject var viewModel: CardGameViewModel
    let card: Card
    @State private var dragAmount: CGSize = .zero
    
    var body: some View {
        ZStack {
            // CardBack is visible when face down; CardFront when face up.
            CardBack(card: card)
            CardFront(card: card)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 3D flip animation based on the card’s face state.
        .rotation3DEffect(.degrees(card.isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        // Allow drag movements.
        .offset(dragAmount)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragAmount = value.translation
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        dragAmount = .zero
                    }
                }
        )
        // Use single-tap to flip the card.
        .gesture(
            TapGesture(count: 1)
                .onEnded {
                    withAnimation {
                        viewModel.selectCard(card: card)
                    }
                }
        )
    }
}

//View for the Card Front
struct CardFront: View {
    let card: Card
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 5)
            Text(card.content)
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
        // Only fully visible when the card is face up.
        .opacity(card.isFaceUp ? 1 : 0)
    }
}

//View for the Card Back
struct CardBack: View {
    let card: Card
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue)
            .overlay(
                Stripes()
            )
            .shadow(radius: 5)
            // Visible when the card is face down.
            .opacity(card.isFaceUp ? 0 : 1)
    }
}

// A decorative stripes pattern used as an overlay on the card back.
struct Stripes: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let stripeWidth: CGFloat = 10
                let count = Int(geometry.size.width / stripeWidth)
                for i in 0...count {
                    let x = CGFloat(i) * stripeWidth
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
            }
            .stroke(Color.white, lineWidth: 1)
        }
    }
}

//Control Panel View
struct ControlPanel: View {
    @ObservedObject var viewModel: CardGameViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // Display the current score and moves side by side.
            HStack {
                Text("Score: \(viewModel.score)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("Moves: \(viewModel.moves)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            // Game control buttons.
            HStack {
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.startNewGame()
                    }
                }) {
                    Text("New Game")
                }
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.shuffleCards()
                    }
                }) {
                    Text("Shuffle")
                }
            }
            // Display game over message when the game is complete.
            if viewModel.gameOver {
                Text("Game Over!")
                    .font(.title)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
