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
    
    init() {
        startNewGame()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}