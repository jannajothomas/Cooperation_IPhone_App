//
//  ViewController.swift
//  Cooperation
//
//  Created by Janna Thomas on 12/7/20.
//  Copyright © 2020 Personal. All rights reserved.
//

//TODO: Make color hint and number hint work

import UIKit
import GameplayKit
import Foundation

class GameViewController: UIViewController {
    //Constants
    let computerHand = 0
    let playerHand = 1
    let numPlayers = 2
    let color =  [1 : UIColor.red,
                   2: UIColor.blue,
                   3: UIColor.magenta,
                   4: UIColor.orange,
                   5: UIColor.purple]
    
    var table: Table!
    var layout = Layout()
    
    //View elements
    var ColorHintView = LabeledCardArea()
    var deck = CardView()
    var DiscardLocation = LabeledCardArea()
    var NumberHintView = LabeledCardArea()
    var playerHands = Array(repeating: Array(repeating: CardView(), count: 5),count: 2)
    lazy var stackPiles = Array(repeating: CardView(), count: 5)
    var discardPiles = Array(repeating: Array(repeating: CardView(), count: 10), count: 5)
    
    var screenDetails = ScreenDetails(windowWidth: 0, windowHeight: 0, topPadding: 0, rightPadding: 0, leftPadding: 0, bottomPadding: 0)

    override func viewDidLoad() {
        
        super.viewDidLoad()
        screenDetails.windowWidth = self.view.frame.size.width
        screenDetails.windowHeight =  self.view.frame.size.height
        //reset table
        table = Table()
        //update UI
        title = "/(board.currentPlayer.name)'s Turn"
        
        for hand in 0...1{
            for card in 0...4{
                playerHands[hand][card] = addCard(hand: hand, card: card, dealingComplete: false)
                view.addSubview(playerHands[hand][card])
            }
        }
        table.delegate = self
        deck = addCard(name: "deck")
    }

    //MARK: View Actions
    @objc func deckTappedAction(){
        dealCards(hand: 0, card: 0)
        for gesture in deck.gestureRecognizers! {
            gesture.isEnabled = false
        }
    }
    
    @objc func selectCardAction(_ recognizer: UITapGestureRecognizer){
        var selectedCardArray = [CardView]()
        
        switch recognizer.state{
            case .ended:
            if let chosenCardView = recognizer.view as? CardView{
                
                chosenCardView.isSelected = !chosenCardView.isSelected
                //put all the selected cards in an array
                for card in 0...4{
                    if playerHands[0][card].isSelected{
                        selectedCardArray.append(playerHands[0][card])
                    }
                }
                //if all of the selected cards are the same number, make number  hint visible
                NumberHintView.isHidden = true
                ColorHintView.isHidden =  true
                if(selectedCardArray.count >= 1){
                    let cardNum = selectedCardArray[0].num
                    NumberHintView.isHidden = false
                    let cardCol = selectedCardArray[0].col
                    ColorHintView.isHidden = false

                    for card in 0...selectedCardArray.count - 1{
                        if selectedCardArray[card].num != cardNum{
                            NumberHintView.isHidden = true
                        }
                        if selectedCardArray[card].col != cardCol{
                            ColorHintView.isHidden = true
                        }
                    }
                }
            }
            default:
                //TODO:?
            print("reached default condition in selectCardAction")
            }
        }
 
    @objc func flipCardAction(_ recognizer: UITapGestureRecognizer) {
    switch recognizer.state {
      case .ended:
          if let chosenCardView = recognizer.view as? CardView{
              UIView.transition(with: chosenCardView, duration: 0.5, options: .transitionFlipFromLeft, animations:{
                  chosenCardView.isFaceUp = !chosenCardView.isFaceUp}
                 )
          }
      default:
          break
      }
    }
    
    @objc func cardTappedAction(){
        //TODO:?
        //print("Card tapped Action")
    }
    
    @objc func colorHint(_ recognizer:UITapGestureRecognizer){
        for count in 0...4{
            if playerHands[computerHand][count].isSelected{
                table.computerHandColorHints[count] = true
                playerHands[computerHand][1].hasColorHint = true
            }
        }
    }
    
    /* Choice to make a number hint has been made, update model */
    @objc func numberHint(_ recognizer: UITapGestureRecognizer){
        for count in 0...4{
            if playerHands[computerHand][count].isSelected{
                table.computerHandNumberHints[count] = true
                playerHands[computerHand][1].hasNumberHint = true
            }
        }
    }
    
    //TODO:
    @objc func hintCardAction(_ recognizer:UITapGestureRecognizer){
         if let chosenCardView = recognizer.view as? LabeledCardArea{
             if(chosenCardView.cardText == "Number Hint"){
                 //gamePlay.getHint(number: numberHint)
             }
             if(chosenCardView.cardText == "Color Hint"){
                 //gamePlay.getHint(color: colorHint)
             }
         }
     }
    
    var lastLocation = CGPoint()
    @objc func detectPanAction(_ recognizer:UIPanGestureRecognizer) {
        if let chosenCardView = recognizer.view as? CardView{
            chosenCardView.superview?.bringSubviewToFront(chosenCardView)
            switch  recognizer.state{
            case .began:
                lastLocation = chosenCardView.center
            case .ended:
                lastLocation = chosenCardView.center
                /****************************Card Discarded****************************/
                if chosenCardView.frame.intersects(DiscardLocation.frame){
                    table.discardCard(hand:chosenCardView.hand, card: chosenCardView.card)
                }else{
                    /****************************Card Played***********************/
                        var largestArea = CGFloat(0)
                        var indexOfLargestArea = 0
                        for card in 0...4{
                            if chosenCardView.frame.intersects(stackPiles[card].frame){
                                let intersection = chosenCardView.frame.intersection(stackPiles[card].frame)
                                let thisArea = (intersection.maxX - intersection.minX)  * (intersection.maxY - intersection.minY)
                                if thisArea > largestArea{
                                    largestArea = thisArea
                                    indexOfLargestArea = card
                                }
                            }
                        }
                        let cardIsPlayable = table.isCardPlayable(hand: chosenCardView.hand, card: chosenCardView.card, stack: indexOfLargestArea)
                        if cardIsPlayable{
                            table.playCard(hand: chosenCardView.hand,card: chosenCardView.card, stack: indexOfLargestArea)
                        }else{
                             table.discardCard(hand:chosenCardView.hand, card: chosenCardView.card)
                        }
                }
                
            case .changed:
                let translation = recognizer.translation(in: self.view)
                chosenCardView.center = CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y)
                if (chosenCardView.frame.intersects(DiscardLocation.frame)){
                    DiscardLocation.backgroundColor = UIColor.gray
                }else{
                    DiscardLocation.backgroundColor = UIColor.clear
                }
                for card in 0...4{
                    if (chosenCardView.frame.intersects(stackPiles[card].frame)){
                        stackPiles[card].backgroundColor = UIColor.gray
                    }else{
                        stackPiles[card].backgroundColor = UIColor.clear
                    }
                }
            default: break
            }
        }
    }
    
    //MARK: LAYOUT
    func layoutTable(){
        DiscardLocation = configureSpecialCards(name: "discard",card: 2)
        DiscardLocation.isHidden = false
        view.addSubview(DiscardLocation)

        ColorHintView = configureSpecialCards(name: "colorHint", card: 1)
        ColorHintView.isHidden = true
        ColorHintView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(colorHint(_:))))
        view.addSubview(ColorHintView)
        
        NumberHintView = configureSpecialCards(name: "numberHint", card: 3)
        view.addSubview(NumberHintView)
        NumberHintView.isHidden = true
        NumberHintView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(numberHint(_:))))
        
        let stackColor = [UIColor.red, UIColor.blue, UIColor.magenta, UIColor.orange,UIColor.purple]
                for card in 0...4{
                    let newStack = CardView()
                   newStack.frame.size = layout.Size(Details: screenDetails)
                    newStack.center = layout.Location(Details: screenDetails, item: CardIdentity(hand: 5, card: card))
                    newStack.backgroundColor = UIColor.clear
                    newStack.num = 0
                    newStack.cardBackgroundColor = stackColor[card]
                    stackPiles[card] = newStack
                    stackPiles[card].tag = card
                    stackPiles[card].isHidden = false
                    view.addSubview(stackPiles[card])
                }
    }
    
    func layoutCardCentersAndSize(){
       deck.center = layout.Location(Details: screenDetails, item: viewLocationIndex["Deck"]!)
       deck.frame.size = layout.Size(Details: screenDetails)
       
       DiscardLocation.center = layout.Location(Details: screenDetails, item: viewLocationIndex["Discard"]!)
       DiscardLocation.frame.size = layout.Size(Details: screenDetails)
       
       ColorHintView.center = layout.Location(Details: screenDetails, item: viewLocationIndex["ColorHint"]!)
       ColorHintView.frame.size = layout.Size(Details: screenDetails)
       
       NumberHintView.center = layout.Location(Details: screenDetails, item: viewLocationIndex["NumberHint"]!)
       NumberHintView.frame.size = layout.Size(Details: screenDetails)
    }

    //MARK: UTILITIES
    func configureSpecialCards(name: String, card: Int)->LabeledCardArea{
        let specialCard = LabeledCardArea()
        specialCard.frame = layout.Frame(Details: screenDetails, name: name)
        specialCard.backgroundColor = UIColor.clear
        if name == "Discard"{
            specialCard.numberOfLines = 1
        }else{
            specialCard.numberOfLines = 2
            specialCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hintCardAction(_:))))
        }
        specialCard.cardText = name
        return specialCard
    }
    
    func findNextDiscardSlot(column: Int)->Int{
        for row in 0...discardPiles[column].count - 1{
            if(discardPiles[column][row].num == 0){
                 return row
            }
        }
        return -1
    }
    
    //MARK: ANIMATIONS
     //Recursive function that animates the dealing of the cards
     private func dealCards(hand: Int, card: Int){
         UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations:{
            self.playerHands[hand][card].center = self.layout.Location(Details: self.screenDetails, item: CardIdentity(hand: hand, card: card))}  , completion: { _ in
                    //see if is the last card in the hand
                    if(card == 4){
                        if hand == self.numPlayers  - 1{
                            //Dealing is done.  Move deck its perm location
                            UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
                                self.deck.frame = self.layout.Frame(Details: self.screenDetails, name: "deck")
                            },
                            completion: { _ in
                                for card in 0...4{
                                    self.turnOverCard(card:card)
                                }
                                //self.turnOverCards()
                                self.layoutTable()
                            })
                            return;
                        }else{
                             self.dealCards(hand: hand + 1, card: 0)
                        }
                    }else{
                        self.dealCards(hand: hand, card: card + 1)
                }
            }
        )
    }

    private func turnOverCard(card:Int){
        UIView.transition(
                       with: playerHands[0][card],
                        duration: 1.5,
                        options: .transitionFlipFromLeft,
                        animations: {self.playerHands[0][card].isFaceUp = true}
        )
    }


      func drawCardAnimation(hand: Int, card: Int) {
            let delay = GameViewController.cardMoveTime
            playerHands[hand][card] = addCard(hand: hand, card: card, dealingComplete: true)

        UIView.animate(withDuration: GameViewController.cardMoveTime, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.playerHands[hand][card].center = self.layout.Location(Details: self.screenDetails, item: CardIdentity(hand: hand, card: card))
        }, completion: {_ in
            if(hand == 0){
                self.turnOverCard(card:card)
            }
            self.table.changePlayers()
        })
    }
    
     func moveCardAnimation(sourceHand: Int, sourceCard: Int, destinationCard: Int, destintionHand: Int, playedToCard: Int, playedToHand: Int) {
        let chosenCardView = playerHands[sourceHand][sourceCard]
        
        var flipDuration = GameViewController.cardFlipTime
        if sourceHand == 0{
            flipDuration = TimeInterval(0)
        }
         view.bringSubviewToFront(chosenCardView)
                 self.view.layoutIfNeeded()
                 UIView.animate(
                  withDuration: GameViewController.cardMoveTime,
                     animations: {
                         chosenCardView.center = self.layout.Location(Details: self.screenDetails, item: CardIdentity(hand: playedToHand, card: playedToCard))},
                     completion: {_ in
                         UIView.transition(
                             with: chosenCardView,
                             duration: GameViewController.cardFlipTime,
                             options:.transitionFlipFromLeft,
                             animations: {
                                 chosenCardView.isFaceUp = true},
                             completion: {_ in
                                     UIView.animate(
                                      withDuration: GameViewController.cardMoveTime,
                                         animations:  {
                                             chosenCardView.center = self.layout.Location(Details: self.screenDetails, item: CardIdentity(hand: destintionHand, card: destinationCard))
                                     },
                                         completion: {_ in
                                          if destintionHand == 5{
                                               self.discardPiles[destinationCard][destintionHand - 5] = chosenCardView
                                          }else{
                                              self.discardPiles[destinationCard].append(chosenCardView)
                                          }
                                     }
                                  )
                             }
                         )
                     }
                 )
     }
}
  
//MARK: EXTENSIONS
 extension GameViewController{
     static var cardMoveTime = 0.8
     static var cardFlipTime = 0.5
 }

extension GameViewController: sendGamePlayActionDelegate{
    func updateHintInView() {
        print("give hint")
        //TODO: Placeholder
    }
    
    func playCardAnimation(hand:Int, card:Int, column:Int) {
        let chosenCardView = playerHands[hand][card]
        view.bringSubviewToFront(chosenCardView)
        self.view.layoutIfNeeded()
        UIView.animate(
            withDuration: GameViewController.cardMoveTime,
            animations: {
                chosenCardView.center = self.layout.Location(Details: self.screenDetails, item: CardIdentity(hand: 5, card: column))},
            completion: {_ in
                self.stackPiles[column] = self.playerHands[hand][card]
                self.drawCardAnimation(hand: hand, card: card)}
        )
    }
    
    func discardCardAnimation(hand:Int, card:Int, column: Int, row:Int) {
        var animationOptions = UIView.AnimationOptions.transitionFlipFromLeft
        if hand == 0{
            animationOptions =  UIView.AnimationOptions.overrideInheritedOptions
        }
        let chosenCardView = playerHands[hand][card]
        view.bringSubviewToFront(chosenCardView)
        self.view.layoutIfNeeded()
        UIView.animate(
            withDuration: GameViewController.cardMoveTime,
            animations: {
                chosenCardView.frame = self.layout.Frame(Details: self.screenDetails, item: CardIdentity(hand: 4, card: 2))},
            completion: {_ in
                UIView.transition(
                    with: chosenCardView,
                    duration: GameViewController.cardFlipTime,
                    options: animationOptions,
                    animations: {chosenCardView.isFaceUp = true},
                    completion: {_ in
                        UIView.animate(
                            withDuration: GameViewController.cardMoveTime,
                            animations:  { chosenCardView.center = self.layout.Location(Details: self.screenDetails, item: CardIdentity(hand: row + 6, card: column))},
                            completion: {_ in
                                self.discardPiles[column][row] = self.playerHands[hand][card]
                                self.drawCardAnimation(hand: hand, card: card)
                            }
                        )
                    }
                )
            }
        )
    }
    
    //TODO: Combine these two functions in any way reasonable
    func addCard(name: String)->CardView {
        let newCard = CardView()
        newCard.backgroundColor = UIColor.clear
        newCard.isFaceUp = false
        switch(name){
            case "deck":
                newCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(deckTappedAction)))
                newCard.frame = layout.Frame(Details: screenDetails, name: "center")
                view.addSubview(newCard)
            default:
                print("error, name is not found in addCard")
        }
        return newCard
    }
    
    func addCard(hand:Int, card: Int, dealingComplete:Bool)->CardView{
        let newCard = CardView()
        newCard.backgroundColor = UIColor.clear
        if hand == 0{
            newCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectCardAction)))
        }
        if hand == 1{
              newCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(flipCardAction)))
            newCard.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(detectPanAction(_:))))
        }
        newCard.hand = hand
        newCard.card = card
        newCard.isFaceUp = false
        if dealingComplete{
            newCard.frame =  layout.Frame(Details: screenDetails, name: "deck")
        }else{
           newCard.frame = layout.Frame(Details: screenDetails, name: "center")
        }
        newCard.num = table.hands[hand][card].num.rawValue
        newCard.col = color[table.hands[hand][card].col.rawValue]!
        view.addSubview(newCard)
        return newCard
    }
}


